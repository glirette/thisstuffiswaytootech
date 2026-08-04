param(
  [string]$Validator = "scripts/validate-technical-source-candidate-feed.ps1",
  [string]$Materializer = "scripts/materialize-public-authority-candidate.ps1",
  [string]$ReferenceTimeUtc = "2026-08-03T10:15:00Z"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$fixturesDir = "test/fixtures"
$validPath = Join-Path $fixturesDir 'valid-technical-source-candidate-feed.json'
$validRaw = Get-Content -LiteralPath $validPath -Raw
$pass = 0
$fail = 0

function Add-Pass {
  param([string]$Message)
  Write-Host "PASS: $Message"
  $script:pass++
}

function Add-Fail {
  param([string]$Message)
  Write-Host "FAIL: $Message"
  $script:fail++
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
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    return [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical))).Replace('-','').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Run-Validate {
  param([string]$Path, [bool]$ExpectPass, [string]$ExpectedError = "")
  $out = $null
  $code = 0
  try {
    $out = & pwsh -NoProfile -File $Validator -FeedPath $Path -NowUtc $ReferenceTimeUtc 2>&1
    $code = $LASTEXITCODE
  } catch {
    $code = 1
    $out = $_
  }
  $outText = @($out | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
  $ok = ($ExpectPass -and $code -eq 0) -or (-not $ExpectPass -and $code -ne 0)
  if ($ok -and -not [string]::IsNullOrWhiteSpace($ExpectedError) -and $outText -notmatch [Regex]::Escape($ExpectedError)) {
    $ok = $false
  }
  if ($ok) {
    Add-Pass "$Path (exit=$code expectPass=$ExpectPass)"
  } else {
    Add-Fail "$Path (exit=$code expectPass=$ExpectPass expected='$ExpectedError' out: $outText)"
  }
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("technical-authority-" + [guid]::NewGuid().ToString('n'))
try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  function Write-MutatedFeed {
    param(
      [string]$Name,
      [scriptblock]$Mutate,
      [bool]$RecomputeIdentity = $false
    )
    $feed = $validRaw | ConvertFrom-Json -Depth 20
    & $Mutate $feed
    if ($RecomputeIdentity) {
      $feed.candidates[0].candidateId = Get-CandidateIdentity $feed.candidates[0]
    }
    $path = Join-Path $tempRoot "$Name.json"
    $feed | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $path
    return $path
  }

  Run-Validate $validPath $true

  $unsafeRunId = Write-MutatedFeed 'unsafe-run-id' {
    param($feed)
    $feed.candidates[0].generatorEvidence.runId = 'AccountKey=unsafe'
  }
  Run-Validate $unsafeRunId $false 'Schema validation failed'

  $multilineRunId = Write-MutatedFeed 'multiline-run-id' {
    param($feed)
    $feed.candidates[0].generatorEvidence.runId = "safe-run$([char]10)## injected"
  }
  Run-Validate $multilineRunId $false 'Schema validation failed'

  $topicPublisherMismatch = Write-MutatedFeed 'topic-publisher-mismatch' {
    param($feed)
    $feed.candidates[0].topicId = 'crm-and-work-management-apis'
    $feed.candidates[0].sources = @(
      [pscustomobject]@{
        url = 'https://developers.openai.com/api/docs'
        title = 'OpenAI API Documentation'
        publisher = 'openai'
        kind = 'official_vendor_docs'
        reviewedAtUtc = '2026-08-03T09:00:00Z'
        supports = 'Official public API documentation for a test routing boundary.'
      }
    )
  } $true
  Run-Validate $topicPublisherMismatch $false 'Publisher openai is not allowed for topic crm-and-work-management-apis'

  $topicPublisherMatch = Write-MutatedFeed 'topic-publisher-match' {
    param($feed)
    $feed.candidates[0].topicId = 'crm-and-work-management-apis'
    $feed.candidates[0].sources = @(
      [pscustomobject]@{
        url = 'https://docs.heffl.com/'
        title = 'Heffl API Documentation'
        publisher = 'heffl'
        kind = 'official_vendor_docs'
        reviewedAtUtc = '2026-08-03T09:00:00Z'
        supports = 'Official public API documentation for a matching topic publisher route.'
      }
    )
  } $true
  Run-Validate $topicPublisherMatch $true

  $futureSource = Write-MutatedFeed 'future-source-review' {
    param($feed)
    $feed.candidates[0].sources[0].reviewedAtUtc = '2026-08-03T10:15:01Z'
  }
  Run-Validate $futureSource $false 'Source review too old or future'

  $futureCandidate = Write-MutatedFeed 'future-candidate-review' {
    param($feed)
    $feed.candidates[0].reviewedAtUtc = '2026-08-03T10:15:01Z'
  }
  Run-Validate $futureCandidate $false 'Candidate too stale or future'

  $scalarSupports = Write-MutatedFeed 'scalar-supports' {
    param($feed)
    $feed.candidates[0].supports = 'A scalar claim that must not be accepted as an array.'
  }
  Run-Validate $scalarSupports $false 'Schema validation failed'

  $scalarDoesNotProve = Write-MutatedFeed 'scalar-does-not-prove' {
    param($feed)
    $feed.candidates[0].doesNotProve = 'A scalar limit that must not be accepted as an array.'
  }
  Run-Validate $scalarDoesNotProve $false 'Schema validation failed'

  $scalarSources = Write-MutatedFeed 'scalar-sources' {
    param($feed)
    $feed.candidates[0].sources = 'not-an-array'
  }
  Run-Validate $scalarSources $false 'Schema validation failed'

  $badIdentity = Write-MutatedFeed 'bad-stable-identity' {
    param($feed)
    $feed.candidates[0].candidateId = ('a' * 64)
  }
  Run-Validate $badIdentity $false 'candidateId is not the stable content identity'

  $tokenAsString = Write-MutatedFeed 'token-as-string' {
    param($feed)
    $feed.candidates[0].generatorEvidence.usage.inputTokens = '120'
  }
  Run-Validate $tokenAsString $false 'Schema validation failed'

  $missingClaim = Write-MutatedFeed 'missing-claim' {
    param($feed)
    $feed.candidates[0].PSObject.Properties.Remove('doesNotProve')
  }
  Run-Validate $missingClaim $false 'Schema validation failed'

  Get-ChildItem -LiteralPath $fixturesDir -Filter 'adversarial-*.json' | ForEach-Object {
    Run-Validate $_.FullName $false
  }

  $tempDocs = Join-Path $tempRoot 'docs'
  $tempTrails = Join-Path $tempRoot 'source-trails'
  $tempIndex = Join-Path $tempRoot 'source-index.json'
  $tempHealth = Join-Path $tempRoot 'publication-health.json'
  New-Item -ItemType Directory -Path $tempDocs,$tempTrails -Force | Out-Null
  Copy-Item data/source-index.json $tempIndex
  Copy-Item data/public-authority-publication-health.json $tempHealth
  $candidateId = ($validRaw | ConvertFrom-Json).candidates[0].candidateId
  $materializeArgs = @(
    '-NoProfile', '-File', $Materializer,
    '-FeedPath', $validPath,
    '-HealthPath', $tempHealth,
    '-SourceIndexPath', $tempIndex,
    '-DocsDir', $tempDocs,
    '-JsonTrailsDir', $tempTrails,
    '-NowUtc', $ReferenceTimeUtc
  )

  & pwsh @materializeArgs | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'First materialization failed' }
  $artifactPaths = @(
    $tempIndex,
    $tempHealth,
    (Join-Path $tempDocs "$candidateId.md"),
    (Join-Path $tempTrails "$candidateId.json")
  )
  if (@($artifactPaths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -gt 0) {
    throw 'Materialization did not create every expected artifact'
  }
  $firstHashes = @{}
  foreach ($path in $artifactPaths) { $firstHashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }

  & pwsh @materializeArgs | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Second materialization failed' }
  foreach ($path in $artifactPaths) {
    if ($firstHashes[$path] -ne (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash) {
      throw "Second materialization changed $path"
    }
  }
  Add-Pass 'materialization is idempotent across index, health, Markdown, and JSON trail artifacts'

  $collisionRoot = Join-Path $tempRoot 'collision'
  $collisionDocs = Join-Path $collisionRoot 'docs'
  $collisionTrails = Join-Path $collisionRoot 'source-trails'
  $collisionIndex = Join-Path $collisionRoot 'source-index.json'
  $collisionHealth = Join-Path $collisionRoot 'publication-health.json'
  New-Item -ItemType Directory -Path $collisionDocs,$collisionTrails -Force | Out-Null
  Copy-Item data/source-index.json $collisionIndex
  Copy-Item data/public-authority-publication-health.json $collisionHealth
  $collisionMarkdown = Join-Path $collisionDocs "$candidateId.md"
  Set-Content -LiteralPath $collisionMarkdown -Value 'unrelated file must survive'
  $collisionHash = (Get-FileHash -LiteralPath $collisionMarkdown -Algorithm SHA256).Hash
  $collisionIndexHash = (Get-FileHash -LiteralPath $collisionIndex -Algorithm SHA256).Hash
  $collisionHealthHash = (Get-FileHash -LiteralPath $collisionHealth -Algorithm SHA256).Hash
  $collisionOut = & pwsh -NoProfile -File $Materializer -FeedPath $validPath -HealthPath $collisionHealth -SourceIndexPath $collisionIndex -DocsDir $collisionDocs -JsonTrailsDir $collisionTrails -NowUtc $ReferenceTimeUtc 2>&1
  if ($LASTEXITCODE -eq 0 -or (@($collisionOut | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine) -notmatch 'Output-path collision') {
    throw 'New candidate did not fail closed on a pre-existing Markdown path'
  }
  if ($collisionHash -ne (Get-FileHash -LiteralPath $collisionMarkdown -Algorithm SHA256).Hash -or
      $collisionIndexHash -ne (Get-FileHash -LiteralPath $collisionIndex -Algorithm SHA256).Hash -or
      $collisionHealthHash -ne (Get-FileHash -LiteralPath $collisionHealth -Algorithm SHA256).Hash -or
      (Test-Path -LiteralPath (Join-Path $collisionTrails "$candidateId.json"))) {
    throw 'Path-collision failure mutated an artifact'
  }
  Add-Pass 'pre-existing Markdown path collision is refused before any materialization mutation'

  $jsonCollisionRoot = Join-Path $tempRoot 'json-collision'
  $jsonCollisionDocs = Join-Path $jsonCollisionRoot 'docs'
  $jsonCollisionTrails = Join-Path $jsonCollisionRoot 'source-trails'
  $jsonCollisionIndex = Join-Path $jsonCollisionRoot 'source-index.json'
  $jsonCollisionHealth = Join-Path $jsonCollisionRoot 'publication-health.json'
  New-Item -ItemType Directory -Path $jsonCollisionDocs,$jsonCollisionTrails -Force | Out-Null
  Copy-Item data/source-index.json $jsonCollisionIndex
  Copy-Item data/public-authority-publication-health.json $jsonCollisionHealth
  $collisionTrail = Join-Path $jsonCollisionTrails "$candidateId.json"
  Set-Content -LiteralPath $collisionTrail -Value '{"unrelated":true}'
  $collisionTrailHash = (Get-FileHash -LiteralPath $collisionTrail -Algorithm SHA256).Hash
  $jsonCollisionIndexHash = (Get-FileHash -LiteralPath $jsonCollisionIndex -Algorithm SHA256).Hash
  $jsonCollisionHealthHash = (Get-FileHash -LiteralPath $jsonCollisionHealth -Algorithm SHA256).Hash
  $jsonCollisionOut = & pwsh -NoProfile -File $Materializer -FeedPath $validPath -HealthPath $jsonCollisionHealth -SourceIndexPath $jsonCollisionIndex -DocsDir $jsonCollisionDocs -JsonTrailsDir $jsonCollisionTrails -NowUtc $ReferenceTimeUtc 2>&1
  if ($LASTEXITCODE -eq 0 -or (@($jsonCollisionOut | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine) -notmatch 'Output-path collision') {
    throw 'New candidate did not fail closed on a pre-existing JSON path'
  }
  if ($collisionTrailHash -ne (Get-FileHash -LiteralPath $collisionTrail -Algorithm SHA256).Hash -or
      $jsonCollisionIndexHash -ne (Get-FileHash -LiteralPath $jsonCollisionIndex -Algorithm SHA256).Hash -or
      $jsonCollisionHealthHash -ne (Get-FileHash -LiteralPath $jsonCollisionHealth -Algorithm SHA256).Hash -or
      (Test-Path -LiteralPath (Join-Path $jsonCollisionDocs "$candidateId.md"))) {
    throw 'JSON path-collision failure mutated an artifact'
  }
  Add-Pass 'pre-existing JSON path collision is refused before any materialization mutation'
} catch {
  Add-Fail "materialization contract: $_"
} finally {
  if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

Write-Host "SUMMARY: $pass passed, $fail failed"
if ($fail -gt 0) { exit 1 }
exit 0
