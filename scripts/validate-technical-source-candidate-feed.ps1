param(
  [Parameter(Mandatory=$true)][string]$FeedPath,
  [string]$RoutingPath = "data/public-authority-routing.json",
  [string]$HealthPath = "data/public-authority-publication-health.json",
  [string]$SourceIndexPath = "data/source-index.json",
  [int]$MaxFeedAgeHours = 30,
  [int]$MaxCandidateAgeHours = 72,
  [int]$MaxSourceReviewAgeDays = 31
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DeterministicDigest {
  param([object]$Obj)
  $json = $Obj | ConvertTo-Json -Depth 100 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hash = $sha.ComputeHash($bytes)
  return [BitConverter]::ToString($hash).Replace('-','').ToLower()
}

function Test-ValidDateTime {
  param([string]$S)
  try { [datetime]::Parse($S, $null, [System.Globalization.DateTimeStyles]::RoundtripKind) | Out-Null; return $true } catch { return $false }
}

function Get-AgeHours {
  param([string]$UtcStr)
  $dt = [datetime]::Parse($UtcStr, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
  return ([datetime]::UtcNow - $dt).TotalHours
}

function Get-AgeDays {
  param([string]$UtcStr)
  $dt = [datetime]::Parse($UtcStr, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
  return ([datetime]::UtcNow - $dt).TotalDays
}

function Assert-NoExtraProperties {
  param([object]$Obj, [string[]]$Allowed)
  $props = $Obj.PSObject.Properties.Name
  foreach ($p in $props) { if ($Allowed -notcontains $p) { throw "Unknown field: $p" } }
}

$routing = Get-Content $RoutingPath -Raw | ConvertFrom-Json -AsHashtable
$health = Get-Content $HealthPath -Raw | ConvertFrom-Json
$index = Get-Content $SourceIndexPath -Raw | ConvertFrom-Json

$feed = Get-Content $FeedPath -Raw | ConvertFrom-Json -Depth 20
Assert-NoExtraProperties $feed @('schema','generatedAtUtc','candidates')
if ($feed.schema -ne 'technical-source-candidate-feed/v1') { throw "Bad feed schema: $($feed.schema)" }
if (-not (Test-ValidDateTime $feed.generatedAtUtc)) { throw "Invalid feed generatedAtUtc" }
$feedAge = Get-AgeHours $feed.generatedAtUtc
if ($feedAge -gt $MaxFeedAgeHours -or $feedAge -lt -1) { throw "Feed too stale or future: $feedAge h" }
if ($feed.candidates.Count -gt 20) { throw "Too many candidates" }

$publisherAllowlists = $routing.publishers
$routes = $routing.routes
$allowedPublishersForTopic = @{}
foreach ($t in $routes.Keys) { $allowedPublishersForTopic[$t] = $routes[$t] }

$validCount = 0
$digests = @{}
foreach ($cand in $feed.candidates) {
  $allowed = @('schema','candidateId','destination','topicId','title','summary','reviewedAtUtc','recheckBeforeUse','sources','supports','doesNotProve','generatorEvidence')
  Assert-NoExtraProperties $cand $allowed
  if ($cand.schema -ne 'technical-source-candidate/v1') { throw "Bad candidate schema for $($cand.candidateId)" }
  if ($cand.destination -ne 'glirette/thisstuffiswaytootech') { throw "Bad destination for $($cand.candidateId)" }
  if ($cand.candidateId -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') { throw "Bad candidateId: $($cand.candidateId)" }
  if ($cand.topicId -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') { throw "Bad topicId: $($cand.topicId)" }
  if (-not $routes.ContainsKey($cand.topicId)) { throw "Unrouted topicId: $($cand.topicId)" }
  if ($cand.title.Length -lt 8 -or $cand.title.Length -gt 140) { throw "Bad title length" }
  if ($cand.summary.Length -lt 20 -or $cand.summary.Length -gt 1200) { throw "Bad summary length" }
  if (-not (Test-ValidDateTime $cand.reviewedAtUtc)) { throw "Bad reviewedAtUtc" }
  $candAge = Get-AgeHours $cand.reviewedAtUtc
  if ($candAge -gt $MaxCandidateAgeHours -or $candAge -lt -1) { throw "Candidate too stale: $($cand.candidateId)" }
  if ($cand.recheckBeforeUse -isnot [bool]) { throw "recheckBeforeUse must be boolean" }

  foreach ($src in $cand.sources) {
    $sallowed = @('url','title','publisher','kind','reviewedAtUtc','supports')
    Assert-NoExtraProperties $src $sallowed
    if ($src.url -notmatch '^https://') { throw "Non-HTTPS source url: $($src.url)" }
    if ($src.url -match 'blob\.core\.windows|private|token=|key=') { throw "Rejected private/blob url: $($src.url)" }
    $pub = $src.publisher
    if (-not $publisherAllowlists.ContainsKey($pub)) { throw "Unknown publisher: $pub" }
    $allowHosts = $publisherAllowlists[$pub]
    $hostOk = $false
    foreach ($h in $allowHosts) { if ($src.url.StartsWith($h)) { $hostOk=$true; break } }
    if (-not $hostOk) { throw "Source url not in allowlist for ${pub}: $($src.url)" }
    if ($src.kind -notin @('official_vendor_docs','official_project_docs','official_changelog','standards_body')) { throw "Bad kind" }
    if (-not (Test-ValidDateTime $src.reviewedAtUtc)) { throw "Bad source reviewedAtUtc" }
    $srcAge = Get-AgeDays $src.reviewedAtUtc
    if ($srcAge -gt $MaxSourceReviewAgeDays) { throw "Source review too old: $($src.url)" }
    if ($src.title.Length -lt 3 -or $src.supports.Length -lt 10) { throw "Bad source fields" }
  }
  if ($cand.sources.Count -lt 1 -or $cand.sources.Count -gt 12) { throw "Bad sources count" }

  if ($cand.supports.Count -lt 1 -or $cand.supports.Count -gt 10) { throw "Bad supports count" }
  if ($cand.doesNotProve.Count -lt 1 -or $cand.doesNotProve.Count -gt 10) { throw "Bad doesNotProve count" }

  $ev = $cand.generatorEvidence
  $eallowed = @('provider','authMode','model','runId','generatedAtUtc','usage')
  Assert-NoExtraProperties $ev $eallowed
  if ($ev.provider -ne 'openai') { throw "generatorEvidence.provider must be openai" }
  if ($ev.authMode -ne 'dedicated_public_source_key') { throw "generatorEvidence.authMode must be dedicated_public_source_key" }
  if ($ev.model -notmatch '^[A-Za-z0-9._-]+$') { throw "Bad model" }
  if (-not (Test-ValidDateTime $ev.generatedAtUtc)) { throw "Bad evidence generatedAtUtc" }
  $u = $ev.usage
  $uallowed = @('inputTokens','outputTokens','reasoningTokens')
  Assert-NoExtraProperties $u $uallowed
  if ($u.inputTokens -lt 0 -or $u.outputTokens -lt 0 -or $u.reasoningTokens -lt 0) { throw "Negative token counts" }

  $digest = Get-DeterministicDigest $cand
  if ($digests.ContainsKey($cand.candidateId)) { throw "Duplicate candidateId" }
  $digests[$cand.candidateId] = $digest

  $existing = $false
  foreach ($o in $index.officialSources) { if ($o.id -eq $cand.candidateId) { $existing = $true; break } }
  if ($existing) {
    Write-Host "IDEMPOTENT: $($cand.candidateId) digest=$digest"
  } else {
    Write-Host "VALID: $($cand.candidateId) digest=$digest"
  }
  $validCount++
}

Write-Host "Feed validation passed: $validCount candidate(s)"
exit 0
