param(
  [string]$Validator = "scripts/validate-technical-source-candidate-feed.ps1",
  [string]$ReferenceTimeUtc = "2026-08-03T10:15:00Z"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fixturesDir = "test/fixtures"
$pass = 0
$fail = 0

function Run-Validate {
  param([string]$Path, [bool]$ExpectPass)
  $out = $null
  $code = 0
  try {
    $out = & pwsh -NoProfile -File $Validator -FeedPath $Path -NowUtc $ReferenceTimeUtc 2>&1
    $code = $LASTEXITCODE
  } catch {
    $code = 1
    $out = $_
  }
  $ok = ($ExpectPass -and $code -eq 0) -or (-not $ExpectPass -and $code -ne 0)
  if ($ok) {
    Write-Host "PASS: $Path (exit=$code expectPass=$ExpectPass)"
    $script:pass++
  } else {
    Write-Host "FAIL: $Path (exit=$code expectPass=$ExpectPass) out: $out"
    $script:fail++
  }
}

Run-Validate "$fixturesDir/valid-technical-source-candidate-feed.json" $true
Run-Validate "$fixturesDir/adversarial-extra-field-feed.json" $false
Run-Validate "$fixturesDir/adversarial-bad-schema-version.json" $false
Run-Validate "$fixturesDir/adversarial-bad-destination.json" $false
Run-Validate "$fixturesDir/adversarial-unknown-topic.json" $false
Run-Validate "$fixturesDir/adversarial-http-url.json" $false
Run-Validate "$fixturesDir/adversarial-bad-evidence-provider.json" $false
Run-Validate "$fixturesDir/adversarial-extra-field-candidate.json" $false
Run-Validate "$fixturesDir/adversarial-stale-badpub.json" $false
Run-Validate "$fixturesDir/adversarial-blob-url.json" $false
Run-Validate "$fixturesDir/adversarial-private-summary.json" $false

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("technical-authority-" + [guid]::NewGuid().ToString('n'))
try {
  $tempDocs = Join-Path $tempRoot 'docs'
  $tempTrails = Join-Path $tempRoot 'source-trails'
  New-Item -ItemType Directory -Path $tempDocs,$tempTrails -Force | Out-Null
  $tempIndex = Join-Path $tempRoot 'source-index.json'
  $tempHealth = Join-Path $tempRoot 'publication-health.json'
  Copy-Item data/source-index.json $tempIndex
  Copy-Item data/public-authority-publication-health.json $tempHealth

  & pwsh -NoProfile -File scripts/materialize-public-authority-candidate.ps1 -FeedPath "$fixturesDir/valid-technical-source-candidate-feed.json" -HealthPath $tempHealth -SourceIndexPath $tempIndex -DocsDir $tempDocs -JsonTrailsDir $tempTrails -NowUtc $ReferenceTimeUtc | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'First materialization failed' }
  $firstIndex = Get-FileHash $tempIndex -Algorithm SHA256
  $firstHealth = Get-FileHash $tempHealth -Algorithm SHA256
  & pwsh -NoProfile -File scripts/materialize-public-authority-candidate.ps1 -FeedPath "$fixturesDir/valid-technical-source-candidate-feed.json" -HealthPath $tempHealth -SourceIndexPath $tempIndex -DocsDir $tempDocs -JsonTrailsDir $tempTrails -NowUtc $ReferenceTimeUtc | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Second materialization failed' }
  if ($firstIndex.Hash -ne (Get-FileHash $tempIndex -Algorithm SHA256).Hash -or $firstHealth.Hash -ne (Get-FileHash $tempHealth -Algorithm SHA256).Hash) {
    throw 'Second materialization was not idempotent'
  }
  Write-Host 'PASS: materialization is idempotent and collision-aware'
  $pass++
} catch {
  Write-Host "FAIL: materialization contract: $_"
  $fail++
} finally {
  if (Test-Path $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

Write-Host "SUMMARY: $pass passed, $fail failed"
if ($fail -gt 0) { exit 1 }
exit 0
