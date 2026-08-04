param(
  [Parameter(Mandatory=$true)][string]$FeedPath,
  [string]$RoutingPath = "data/public-authority-routing.json",
  [string]$HealthPath = "data/public-authority-publication-health.json",
  [string]$SourceIndexPath = "data/source-index.json",
  [string]$DocsDir = "docs",
  [string]$JsonTrailsDir = "data/source-trails",
  [string]$FeedSchemaPath = "schemas/technical-source-candidate-feed.schema.json",
  [string]$CandidateSchemaPath = "schemas/technical-source-candidate.schema.json",
  [string]$NowUtc = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$effectiveNowUtc = if ([string]::IsNullOrWhiteSpace($NowUtc)) {
  [datetime]::UtcNow
} else {
  [datetime]::Parse($NowUtc, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
}

$validatorPath = Join-Path $PSScriptRoot 'validate-technical-source-candidate-feed.ps1'
& pwsh -NoProfile -File $validatorPath -FeedPath $FeedPath -RoutingPath $RoutingPath -HealthPath $HealthPath -SourceIndexPath $SourceIndexPath -FeedSchemaPath $FeedSchemaPath -CandidateSchemaPath $CandidateSchemaPath -NowUtc $NowUtc | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Validation failed before materialize" }

function Get-Sha256 {
  param([string]$Text)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    return [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-DeterministicDigest {
  param([object]$Candidate)
  $canonical = [ordered]@{
    schema = [string]$Candidate.schema
    candidateId = [string]$Candidate.candidateId
    destination = [string]$Candidate.destination
    topicId = [string]$Candidate.topicId
    title = [string]$Candidate.title
    summary = [string]$Candidate.summary
    reviewedAtUtc = ([datetime]$Candidate.reviewedAtUtc).ToUniversalTime().ToString('o')
    recheckBeforeUse = [bool]$Candidate.recheckBeforeUse
    sources = @($Candidate.sources | ForEach-Object {
      [ordered]@{
        url = [string]$_.url
        title = [string]$_.title
        publisher = [string]$_.publisher
        kind = [string]$_.kind
        reviewedAtUtc = ([datetime]$_.reviewedAtUtc).ToUniversalTime().ToString('o')
        supports = [string]$_.supports
      }
    })
    supports = @($Candidate.supports | ForEach-Object { [string]$_ })
    doesNotProve = @($Candidate.doesNotProve | ForEach-Object { [string]$_ })
    generatorEvidence = [ordered]@{
      provider = [string]$Candidate.generatorEvidence.provider
      authMode = [string]$Candidate.generatorEvidence.authMode
      model = [string]$Candidate.generatorEvidence.model
      runId = [string]$Candidate.generatorEvidence.runId
      generatedAtUtc = ([datetime]$Candidate.generatorEvidence.generatedAtUtc).ToUniversalTime().ToString('o')
      usage = [ordered]@{
        inputTokens = [int]$Candidate.generatorEvidence.usage.inputTokens
        outputTokens = [int]$Candidate.generatorEvidence.usage.outputTokens
        reasoningTokens = [int]$Candidate.generatorEvidence.usage.reasoningTokens
      }
    }
  }
  return Get-Sha256 ($canonical | ConvertTo-Json -Depth 20 -Compress)
}

function Convert-ToCanonicalUtc {
  param([object]$Value)
  if ($Value -is [datetime]) {
    return $Value.ToUniversalTime()
  }
  return [datetime]::Parse([string]$Value, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
}

function New-SourceTrailMarkdown {
  param([object]$Candidate, [string]$Digest)
  $datePart = (Convert-ToCanonicalUtc $Candidate.reviewedAtUtc).ToString('yyyy-MM-dd')
  $supportsList = ($Candidate.supports | ForEach-Object { "- $_" }) -join [Environment]::NewLine
  $doesNotList = ($Candidate.doesNotProve | ForEach-Object { "- $_" }) -join [Environment]::NewLine
  $sourceList = ($Candidate.sources | ForEach-Object { "- [$($_.title)]($($_.url)) ($($_.publisher), $($_.kind))" }) -join [Environment]::NewLine
  $evidence = $Candidate.generatorEvidence
  $generatedAtUtc = (Convert-ToCanonicalUtc $evidence.generatedAtUtc).ToString('o')
  return @"
# $($Candidate.title)

Reviewed: $datePart

$($Candidate.summary)

## Supports

$supportsList

## Does Not Prove

$doesNotList

## Sources

$sourceList

## Recheck Before Use

$($Candidate.recheckBeforeUse)

This source trail must be re-checked against the controlling official sources before use in decisions.

## Generator Evidence (public-safe metadata only)

- provider: $($evidence.provider)
- authMode: $($evidence.authMode)
- model: $($evidence.model)
- runId: $($evidence.runId)
- generatedAtUtc: $generatedAtUtc
- usage: input=$($evidence.usage.inputTokens) output=$($evidence.usage.outputTokens) reasoning=$($evidence.usage.reasoningTokens)

Digest: $Digest
"@.Trim()
}

if (-not (Test-Path -LiteralPath $DocsDir)) { throw "Docs directory does not exist: $DocsDir" }
$index = Get-Content -LiteralPath $SourceIndexPath -Raw | ConvertFrom-Json
$health = Get-Content -LiteralPath $HealthPath -Raw | ConvertFrom-Json
$feed = Get-Content -LiteralPath $FeedPath -Raw | ConvertFrom-Json -Depth 20
$now = $effectiveNowUtc.ToString('o')
$plans = [System.Collections.Generic.List[object]]::new()

foreach ($candidate in @($feed.candidates)) {
  $id = [string]$candidate.candidateId
  $digest = Get-DeterministicDigest $candidate
  $markdownPath = Join-Path $DocsDir "$id.md"
  $trailPath = Join-Path $JsonTrailsDir "$id.json"
  $markdown = New-SourceTrailMarkdown $candidate $digest
  $indexEntry = @($index.officialSources | Where-Object { $_.id -eq $id })

  if ($indexEntry.Count -gt 1) { throw "Duplicate source-index id: $id" }
  if ($indexEntry.Count -eq 1) {
    if (-not (Test-Path -LiteralPath $markdownPath) -or -not (Test-Path -LiteralPath $trailPath)) {
      throw "candidateId collision without both materialized artifacts: $id"
    }
    $existingTrail = Get-Content -LiteralPath $trailPath -Raw | ConvertFrom-Json
    if ($existingTrail.candidateId -ne $id -or $existingTrail.digest -ne $digest) {
      throw "candidateId collision with different content: $id"
    }
    if ((Get-Content -LiteralPath $markdownPath -Raw) -cne $markdown) {
      throw "candidateId collision with different Markdown content: $id"
    }
    $plans.Add([ordered]@{ candidate = $candidate; digest = $digest; markdownPath = $markdownPath; trailPath = $trailPath; markdown = $markdown; isExisting = $true })
    continue
  }

  if ((Test-Path -LiteralPath $markdownPath) -or (Test-Path -LiteralPath $trailPath)) {
    throw "Output-path collision for new candidateId: $id"
  }
  $plans.Add([ordered]@{ candidate = $candidate; digest = $digest; markdownPath = $markdownPath; trailPath = $trailPath; markdown = $markdown; isExisting = $false })
}

$newPlans = @($plans | Where-Object { -not $_.isExisting })
if ($newPlans.Count -gt 0 -and -not (Test-Path -LiteralPath $JsonTrailsDir)) {
  New-Item -ItemType Directory -Path $JsonTrailsDir -Force | Out-Null
}

$promotedIds = [System.Collections.Generic.List[string]]::new()
foreach ($plan in $plans) {
  $candidate = $plan.candidate
  if ($plan.isExisting) {
    Write-Host "SKIP idempotent: $($candidate.candidateId)"
    continue
  }

  Set-Content -LiteralPath $plan.markdownPath -Value $plan.markdown -NoNewline
  $trail = [ordered]@{
    schema = "public-authority-source-trail/v1"
    candidateId = $candidate.candidateId
    topicId = $candidate.topicId
    title = $candidate.title
    reviewedAtUtc = (Convert-ToCanonicalUtc $candidate.reviewedAtUtc).ToString('o')
    recheckBeforeUse = $candidate.recheckBeforeUse
    sources = $candidate.sources
    supports = $candidate.supports
    doesNotProve = $candidate.doesNotProve
    generatorEvidence = $candidate.generatorEvidence
    digest = $plan.digest
    materializedAtUtc = $now
  }
  $trail | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $plan.trailPath

  $sourceType = [string]$candidate.sources[0].kind
  $sourceUrls = @($candidate.sources | ForEach-Object { [string]$_.url })
  $index.officialSources += [ordered]@{
    id = $candidate.candidateId
    title = $candidate.title
    sourceType = $sourceType
    capturedAt = (Convert-ToCanonicalUtc $candidate.reviewedAtUtc).ToString('yyyy-MM-dd')
    urls = $sourceUrls
    supports = @($candidate.supports)
    doesNotProve = @($candidate.doesNotProve)
  }
  $index.relatedFiles += [ordered]@{
    title = $candidate.title
    path = "docs/$($candidate.candidateId).md"
    useFor = $candidate.summary.Substring(0, [Math]::Min(120, $candidate.summary.Length))
  }
  $promotedIds.Add([string]$candidate.candidateId)
  Write-Host "MATERIALIZED: $($candidate.candidateId) -> $($plan.markdownPath) + $($plan.trailPath) digest=$($plan.digest)"
}

if ($promotedIds.Count -gt 0) {
  $index.dateModified = $effectiveNowUtc.ToString('yyyy-MM-dd')
  $index | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $SourceIndexPath

  $health.lastSuccessfulPromotionAtUtc = $now
  if (-not $health.PSObject.Properties['recentPromotions']) {
    $health | Add-Member -NotePropertyName recentPromotions -NotePropertyValue @() -Force
  }
  $health.recentPromotions += [ordered]@{
    candidateIds = @($promotedIds)
    materializedAtUtc = $now
    digestSample = $newPlans[0].digest
    note = "candidate materialized for proposed review; canonical authority only after reviewed merge"
  }
  $health.recentPromotions = @($health.recentPromotions | Select-Object -Last 20)
  $health | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $HealthPath
  Write-Host "UPDATED index and promotion evidence"
}

Write-Host "Materialize complete. promoted=$($promotedIds.Count)"
exit 0
