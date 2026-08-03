param(
  [Parameter(Mandatory=$true)][string]$FeedPath,
  [string]$RoutingPath = "data/public-authority-routing.json",
  [string]$HealthPath = "data/public-authority-publication-health.json",
  [string]$SourceIndexPath = "data/source-index.json",
  [string]$DocsDir = "docs",
  [string]$JsonTrailsDir = "data/source-trails"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& pwsh -NoProfile -File "scripts/validate-technical-source-candidate-feed.ps1" -FeedPath $FeedPath | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Validation failed before materialize" }

function Get-DeterministicDigest { param([object]$Obj)
  $json = $Obj | ConvertTo-Json -Depth 100 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hash = $sha.ComputeHash($bytes)
  [BitConverter]::ToString($hash).Replace('-','').ToLower()
}

function Get-DatePart { param([string]$Utc) ([datetime]::Parse($Utc, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).ToString('yyyy-MM-dd') }

$routing = Get-Content $RoutingPath -Raw | ConvertFrom-Json -AsHashtable
$index = Get-Content $SourceIndexPath -Raw | ConvertFrom-Json
$health = Get-Content $HealthPath -Raw | ConvertFrom-Json
$feed = Get-Content $FeedPath -Raw | ConvertFrom-Json -Depth 20

if (-not (Test-Path $JsonTrailsDir)) { New-Item -ItemType Directory -Path $JsonTrailsDir -Force | Out-Null }

$now = [datetime]::UtcNow.ToString('o')
$promoted = 0
foreach ($cand in $feed.candidates) {
  $id = $cand.candidateId
  $exists = $false
  foreach ($o in $index.officialSources) { if ($o.id -eq $id) { $exists = $true; break } }
  if ($exists) { Write-Host "SKIP idempotent: $id"; continue }

  $digest = Get-DeterministicDigest $cand
  $datePart = Get-DatePart $cand.reviewedAtUtc
  $mdPath = Join-Path $DocsDir "$id.md"
  $jsonPath = Join-Path $JsonTrailsDir "$id.json"

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
  Write-Host "MATERIALIZED: $id -> $mdPath + $jsonPath digest=$digest"
}

if ($promoted -gt 0) {
  $index.dateModified = ([datetime]::UtcNow.ToString('yyyy-MM-dd'))
  $index | ConvertTo-Json -Depth 20 | Set-Content -Path $SourceIndexPath

  $health.lastSuccessfulPromotionAtUtc = $now
  if (-not $health.PSObject.Properties['recentPromotions']) { $health | Add-Member -NotePropertyName recentPromotions -NotePropertyValue @() -Force }
  $cids = @($feed.candidates | ForEach-Object { $_.candidateId })
  $health.recentPromotions += [ordered]@{ candidateIds = $cids; promotedAtUtc = $now; digestSample = $digest; note = "draft PR prepared; publication only after merge and recheck" }
  $health | ConvertTo-Json -Depth 10 | Set-Content -Path $HealthPath

  Write-Host "UPDATED index and health (promotion only)"
}
Write-Host "Materialize complete. promoted=$promoted"
exit 0
