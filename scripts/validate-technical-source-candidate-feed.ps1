param(
  [Parameter(Mandatory=$true)][string]$FeedPath,
  [string]$RoutingPath = "data/public-authority-routing.json",
  [string]$HealthPath = "data/public-authority-publication-health.json",
  [string]$SourceIndexPath = "data/source-index.json",
  [string]$FeedSchemaPath = "schemas/technical-source-candidate-feed.schema.json",
  [string]$CandidateSchemaPath = "schemas/technical-source-candidate.schema.json",
  [int]$MaxFeedAgeHours = 0,
  [int]$MaxCandidateAgeHours = 0,
  [int]$MaxSourceReviewAgeDays = 0,
  [string]$NowUtc = "",
  [string]$ValidationResultPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$expectedDestination = 'glirette/thisstuffiswaytootech'
$effectiveNowUtc = if ([string]::IsNullOrWhiteSpace($NowUtc)) {
  [datetime]::UtcNow
} else {
  [datetime]::Parse($NowUtc, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
}

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

function Get-CandidateIdentity {
  param([object]$Candidate)
  $urls = [string[]]@($Candidate.sources | ForEach-Object { ([string]$_.url).Trim() })
  [Array]::Sort($urls, [StringComparer]::OrdinalIgnoreCase)
  $canonical = @(
    ([string]$Candidate.destination).ToLowerInvariant(),
    ([string]$Candidate.topicId).Trim().ToLowerInvariant(),
    ([string]$Candidate.summary).Trim(),
    $urls
  ) -join [char]10
  return Get-Sha256 $canonical
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

function Test-ValidDateTime {
  param([string]$Text)
  try {
    [datetime]::Parse($Text, $null, [System.Globalization.DateTimeStyles]::RoundtripKind) | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Get-AgeHours {
  param([object]$UtcValue)
  $dt = if ($UtcValue -is [datetime]) {
    $UtcValue.ToUniversalTime()
  } else {
    [datetime]::Parse([string]$UtcValue, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
  }
  return ($effectiveNowUtc - $dt).TotalHours
}

function Get-AgeDays {
  param([object]$UtcValue)
  $dt = if ($UtcValue -is [datetime]) {
    $UtcValue.ToUniversalTime()
  } else {
    [datetime]::Parse([string]$UtcValue, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
  }
  return ($effectiveNowUtc - $dt).TotalDays
}

function Assert-PublicSafeText {
  param([string]$Text, [string]$Field)
  if ($Text -match '[\x00-\x1F\x7F]') { throw "Control character in $Field" }
  $secretOrPrivatePattern = '(?i)(blob\.core\.windows\.net|DefaultEndpointsProtocol=|AccountKey=|SharedAccessSignature=|Bearer\s+[A-Za-z0-9._~+/-]{12,}|[?&](?:sig|se|sp|sv|token|key)=|https?://(?:localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(?:1[6-9]|2\d|3[01])\.\d+\.\d+))'
  if ($Text -match $secretOrPrivatePattern) { throw "Private or credential-like content in $Field" }
}

function Assert-MarkdownSafeUrl {
  param([string]$Url)
  if ($Url -match '[\s\[\]\(\)<>"'']') { throw "Unsafe characters in source url" }
  try {
    $uri = [Uri]$Url
  } catch {
    throw "Invalid source url"
  }
  if (-not $uri.IsAbsoluteUri -or $uri.Scheme -ne 'https' -or -not [string]::IsNullOrWhiteSpace($uri.UserInfo)) {
    throw "Non-HTTPS or credentialed source url"
  }
}

function Assert-NoExtraProperties {
  param([object]$Object, [string[]]$Allowed)
  $properties = $Object.PSObject.Properties.Name
  foreach ($property in $properties) {
    if ($Allowed -notcontains $property) { throw "Unknown field: $property" }
  }
}

function Test-LocalFeedSchema {
  param([string]$RawFeed)
  $feedSchema = Get-Content -LiteralPath $FeedSchemaPath -Raw | ConvertFrom-Json -AsHashtable
  $candidateSchema = Get-Content -LiteralPath $CandidateSchemaPath -Raw | ConvertFrom-Json -AsHashtable
  [void]$feedSchema.Remove('$id')
  [void]$candidateSchema.Remove('$id')
  if (-not $feedSchema.ContainsKey('$defs')) { $feedSchema['$defs'] = [ordered]@{} }
  $feedSchema['$defs']['candidate'] = $candidateSchema
  $feedSchema['properties']['candidates']['items'] = [ordered]@{ '$ref' = '#/$defs/candidate' }
  $combinedSchema = $feedSchema | ConvertTo-Json -Depth 100
  try {
    if (-not ($RawFeed | Test-Json -Schema $combinedSchema -ErrorAction Stop)) {
      throw 'schema returned false'
    }
  } catch {
    throw "Schema validation failed: $($_.Exception.Message)"
  }
}

$feedRaw = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $FeedPath))
Test-LocalFeedSchema $feedRaw
$feed = $feedRaw | ConvertFrom-Json -Depth 20
$routing = Get-Content -LiteralPath $RoutingPath -Raw | ConvertFrom-Json -AsHashtable
$index = Get-Content -LiteralPath $SourceIndexPath -Raw | ConvertFrom-Json

if ($routing.destination -ne $expectedDestination) { throw "Routing destination does not match this repository" }
if ($MaxFeedAgeHours -le 0) { $MaxFeedAgeHours = [int]$routing.maxFeedAgeHours }
if ($MaxCandidateAgeHours -le 0) { $MaxCandidateAgeHours = [int]$routing.maxCandidateAgeHours }
if ($MaxSourceReviewAgeDays -le 0) { $MaxSourceReviewAgeDays = [int]$routing.maxSourceReviewAgeDays }

Assert-NoExtraProperties $feed @('schema','generatedAtUtc','candidates')
if ($feed.schema -ne 'technical-source-candidate-feed/v1') { throw "Bad feed schema: $($feed.schema)" }
if (-not (Test-ValidDateTime $feed.generatedAtUtc)) { throw "Invalid feed generatedAtUtc" }
$feedAge = Get-AgeHours $feed.generatedAtUtc
if ($feedAge -gt $MaxFeedAgeHours -or $feedAge -lt -1) { throw "Feed too stale or future: $feedAge h" }

$publisherAllowlists = $routing.publishers
$routes = $routing.routes
$validCount = 0
$digests = @{}
$validationCandidates = [System.Collections.Generic.List[object]]::new()
foreach ($cand in @($feed.candidates)) {
  $allowed = @('schema','candidateId','destination','topicId','title','summary','reviewedAtUtc','recheckBeforeUse','sources','supports','doesNotProve','generatorEvidence')
  Assert-NoExtraProperties $cand $allowed
  if ($cand.schema -ne 'technical-source-candidate/v1') { throw "Bad candidate schema for $($cand.candidateId)" }
  if ($cand.destination -ne $routing.destination) { throw "Bad destination for $($cand.candidateId)" }
  if (-not $routes.ContainsKey($cand.topicId)) { throw "Unrouted topicId: $($cand.topicId)" }
  if ((Get-CandidateIdentity $cand) -cne $cand.candidateId) { throw "candidateId is not the stable content identity: $($cand.candidateId)" }
  Assert-PublicSafeText $cand.title "candidate.title"
  Assert-PublicSafeText $cand.summary "candidate.summary"
  if (-not (Test-ValidDateTime $cand.reviewedAtUtc)) { throw "Bad reviewedAtUtc" }
  $candidateAge = Get-AgeHours $cand.reviewedAtUtc
  if ($candidateAge -gt $MaxCandidateAgeHours -or $candidateAge -lt 0) { throw "Candidate too stale or future: $($cand.candidateId)" }

  foreach ($source in @($cand.sources)) {
    $sourceAllowed = @('url','title','publisher','kind','reviewedAtUtc','supports')
    Assert-NoExtraProperties $source $sourceAllowed
    Assert-PublicSafeText $source.url "source.url"
    Assert-MarkdownSafeUrl $source.url
    $publisher = [string]$source.publisher
    if (-not $publisherAllowlists.ContainsKey($publisher)) { throw "Unknown publisher: $publisher" }
    if (@($routes[$cand.topicId]) -notcontains $publisher) { throw "Publisher $publisher is not allowed for topic $($cand.topicId)" }
    $hostOk = $false
    foreach ($allowedPrefix in @($publisherAllowlists[$publisher])) {
      if ($source.url.StartsWith([string]$allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $hostOk = $true
        break
      }
    }
    if (-not $hostOk) { throw "Source url not in allowlist for $($publisher): $($source.url)" }
    if (-not (Test-ValidDateTime $source.reviewedAtUtc)) { throw "Bad source reviewedAtUtc" }
    $sourceAge = Get-AgeDays $source.reviewedAtUtc
    if ($sourceAge -gt $MaxSourceReviewAgeDays -or $sourceAge -lt 0) { throw "Source review too old or future: $($source.url)" }
    Assert-PublicSafeText $source.title "source.title"
    Assert-PublicSafeText $source.supports "source.supports"
  }

  foreach ($statement in @($cand.supports) + @($cand.doesNotProve)) {
    Assert-PublicSafeText $statement "candidate claim"
  }

  $evidence = $cand.generatorEvidence
  $evidenceAllowed = @('provider','authMode','model','runId','generatedAtUtc','usage')
  Assert-NoExtraProperties $evidence $evidenceAllowed
  if ($evidence.provider -ne 'openai') { throw "generatorEvidence.provider must be openai" }
  if ($evidence.authMode -ne 'dedicated_public_source_key') { throw "generatorEvidence.authMode must be dedicated_public_source_key" }
  if ($evidence.runId -notmatch '^[A-Za-z0-9._:-]{1,120}$') { throw "Bad generatorEvidence.runId" }
  Assert-PublicSafeText $evidence.runId "generatorEvidence.runId"
  if (-not (Test-ValidDateTime $evidence.generatedAtUtc)) { throw "Bad evidence generatedAtUtc" }
  $evidenceAge = Get-AgeHours $evidence.generatedAtUtc
  if ($evidenceAge -gt $MaxCandidateAgeHours -or $evidenceAge -lt 0) { throw "Generator evidence too stale or future" }
  $usage = $evidence.usage
  $usageAllowed = @('inputTokens','outputTokens','reasoningTokens')
  Assert-NoExtraProperties $usage $usageAllowed

  $digest = Get-DeterministicDigest $cand
  if ($digests.ContainsKey($cand.candidateId)) { throw "Duplicate candidateId" }
  $digests[$cand.candidateId] = $digest
  $exists = @($index.officialSources | Where-Object { $_.id -eq $cand.candidateId }).Count -gt 0
  if ($exists) {
    Write-Host "EXISTING-ID: $($cand.candidateId) digest=$digest"
  } else {
    Write-Host "VALID: $($cand.candidateId) digest=$digest"
  }
  $validationCandidates.Add([ordered]@{ candidateId = [string]$cand.candidateId; digest = $digest })
  $validCount++
}

if (-not [string]::IsNullOrWhiteSpace($ValidationResultPath)) {
  $candidateIds = [string[]]@($validationCandidates | ForEach-Object { $_.candidateId })
  [Array]::Sort($candidateIds, [StringComparer]::Ordinal)
  $result = [ordered]@{
    schema = 'technical-source-candidate-validation-result/v1'
    destination = $routing.destination
    candidates = @($validationCandidates)
    batchDigest = Get-Sha256 ($candidateIds -join [char]10)
  }
  $result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ValidationResultPath
}

Write-Host "Feed validation passed: $validCount candidate(s)"
exit 0
