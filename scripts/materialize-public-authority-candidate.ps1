param(
  [Parameter(Mandatory=$true)][string]$FeedPath,
  [string]$RoutingPath = "data/public-authority-routing.json",
  [string]$HealthPath = "data/public-authority-publication-health.json",
  [string]$SourceIndexPath = "data/source-index.json",
  [string]$DocsDir = "docs",
  [string]$JsonTrailsDir = "data/source-trails",
  [string]$NowUtc = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$effectiveNowUtc = if ([string]::IsNullOrWhiteSpace($NowUtc)) {
  [datetime]::UtcNow
} else {
  [datetime]::Parse($NowUtc, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
}

& pwsh -NoProfile -File "scripts/validate-technical-source-candidate-feed.ps1" -FeedPath $FeedPath -RoutingPath $RoutingPath -HealthPath $HealthPath -SourceIndexPath $SourceIndexPath -NowUtc $NowUtc | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Validation failed before materialize" }

function Get-DeterministicDigest { param([object]$Candidate)
  $canonical = [ordered]@{
    schema = [string]$Candidate.schema; candidateId = [string]$Candidate.candidateId
    destination = [string]$Candidate.destination; topicId = [string]$Candidate.topicId
    title = [string]$Candidate.title; summary = [string]$Candidate.summary
    reviewedAtUtc = ([datetime]$Candidate.reviewedAtUtc).ToUniversalTime().ToString('o')
    recheckBeforeUse = [bool]$Candidate.recheckBeforeUse
    sources = @($Candidate.sources | ForEach-Object { [ordered]@{
      url = [string]$_.url; title = [string]$_.title; publisher = [string]$_.publisher
      kind = [string]$_.kind; reviewedAtUtc = ([datetime]$_.reviewedAtUtc).ToUniversalTime().ToString('o')
      supports = [string]$_.supports
    } })
    supports = @($Candidate.supports | ForEach-Object { [string]$_ })
    doesNotProve = @($Candidate.doesNotProve | ForEach-Object { [string]$_ })
    generatorEvidence = [ordered]@{
      provider = [string]$Candidate.generatorEvidence.provider; authMode = [string]$Candidate.generatorEvidence.authMode
      model = [string]$Candidate.generatorEvidence.model; runId = [string]$Candidate.generatorEvidence.runId
      generatedAtUtc = ([datetime]$Candidate.generatorEvidence.generatedAtUtc).ToUniversalTime().ToString('o')
      usage = [ordered]@{ inputTokens = [int]$Candidate.generatorEvidence.usage.inputTokens; outputTokens = [int]$Candidate.generatorEvidence.usage.outputTokens; reasoningTokens = [int]$Candidate.generatorEvidence.usage.reasoningTokens }
    }
  }
  $json = $canonical | ConvertTo-Json -Depth 20 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hash = $sha.ComputeHash($bytes)
  [BitConverter]::ToString($hash).Replace('-','').ToLower()
}

function Get-DatePart { param([string]$Utc) ([datetime]::Parse($Utc, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).ToString('yyyy-MM-dd') }

$index = Get-Content $SourceIndexPath -Raw | ConvertFrom-Json
$health = Get-Content $HealthPath -Raw | ConvertFrom-Json
$feed = Get-Content $FeedPath -Raw | ConvertFrom-Json -Depth 20

if (-not (Test-Path $JsonTrailsDir)) { New-Item -ItemType Directory -Path $JsonTrailsDir -Force | Out-Null }

$now = $effectiveNowUtc.ToString('o')
$promoted = 0
$promotedIds = @()
foreach ($cand in $feed.candidates) {
  $id = $cand.candidateId
  $digest = Get-DeterministicDigest $cand
  $datePart = Get-DatePart $cand.reviewedAtUtc
  $mdPath = Join-Path $DocsDir "$id.md"
  $jsonPath = Join-Path $JsonTrailsDir "$id.json"
  $exists = $false
  foreach ($o in $index.officialSources) { if ($o.id -eq $id) { $exists = $true; break } }
  if ($exists) {
    if (-not (Test-Path $jsonPath)) { throw "candidateId collision without a materialized trail: $id" }
    $existingTrail = Get-Content $jsonPath -Raw | ConvertFrom-Json
    if ($existingTrail.digest -ne $digest) { throw "candidateId collision with different content: $id" }
    Write-Host "SKIP idempotent: $id"
    continue
  }

  $supportsList = ($cand.supports | ForEach-Object { "- $_" }) -join "`n"
  $doesNotList = ($cand.doesNotProve | ForEach-Object { "- $_" }) -join "`n"
  $srcList = ($cand.sources | ForEach-Object { "- [$($_.title)]($($_.url)) ($($_.publisher), $($_.kind))" }) -join "`n"
  $ev = $cand.generatorEvidence
  $md = @"
# $($cand.title)

Reviewed: $datePart

$($cand.summary)

## Supports

$supportsList

## Does Not Prove

$doesNotList

## Sources

$srcList

## Recheck Before Use

$($cand.recheckBeforeUse)

This source trail must be re-checked against the controlling official sources before use in decisions.

## Generator Evidence (public-safe metadata only)

- provider: $($ev.provider)
- authMode: $($ev.authMode)
- model: $($ev.model)
- runId: $($ev.runId)
- generatedAtUtc: $($ev.generatedAtUtc.ToString('o'))
- usage: input=$($ev.usage.inputTokens) output=$($ev.usage.outputTokens) reasoning=$($ev.usage.reasoningTokens)

Digest: $digest
"@.Trim()
  Set-Content -Path $mdPath -Value $md -NoNewline

  $trailJson = [ordered]@{
    schema = "public-authority-source-trail/v1"
    candidateId = $id
    topicId = $cand.topicId
    title = $cand.title
    reviewedAtUtc = $cand.reviewedAtUtc
    recheckBeforeUse = $cand.recheckBeforeUse
    sources = $cand.sources
    supports = $cand.supports
    doesNotProve = $cand.doesNotProve
    generatorEvidence = $cand.generatorEvidence
    digest = $digest
    materializedAtUtc = $now
  }
  $trailJson | ConvertTo-Json -Depth 20 | Set-Content -Path $jsonPath

  $sourceType = if ($cand.sources[0].kind) { $cand.sources[0].kind } else { "official_vendor_docs" }
  $captured = $datePart
  $urls = $cand.sources | ForEach-Object { $_.url }
  $newSrc = [ordered]@{
    id = $id
    title = $cand.title
    sourceType = $sourceType
    capturedAt = $captured
    urls = $urls
    supports = $cand.supports
    doesNotProve = $cand.doesNotProve
  }
  $index.officialSources += $newSrc

  $rel = [ordered]@{
    title = $cand.title
    path = "docs/$id.md"
    useFor = ($cand.summary.Substring(0, [Math]::Min(120, $cand.summary.Length)))
  }
  $index.relatedFiles += $rel

  $promoted++
  $promotedIds += $id
  Write-Host "MATERIALIZED: $id -> $mdPath + $jsonPath digest=$digest"
}

if ($promoted -gt 0) {
  $index.dateModified = $effectiveNowUtc.ToString('yyyy-MM-dd')
  $index | ConvertTo-Json -Depth 20 | Set-Content -Path $SourceIndexPath

  $health.lastSuccessfulPromotionAtUtc = $now
  if (-not $health.PSObject.Properties['recentPromotions']) { $health | Add-Member -NotePropertyName recentPromotions -NotePropertyValue @() -Force }
  $health.recentPromotions += [ordered]@{ candidateIds = @($promotedIds); promotedAtUtc = $now; digestSample = $digest; note = "draft PR prepared; publication only after merge and recheck" }
  $health.recentPromotions = @($health.recentPromotions | Select-Object -Last 20)
  $health | ConvertTo-Json -Depth 10 | Set-Content -Path $HealthPath

  Write-Host "UPDATED index and health (promotion only)"
}
Write-Host "Materialize complete. promoted=$promoted"
exit 0
