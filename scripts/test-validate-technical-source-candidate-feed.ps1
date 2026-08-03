param(
  [string]$Validator = "scripts/validate-technical-source-candidate-feed.ps1"
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
    $out = & pwsh -NoProfile -File $Validator -FeedPath $Path 2>&1
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

Write-Host "SUMMARY: $pass passed, $fail failed"
if ($fail -gt 0) { exit 1 }
exit 0
