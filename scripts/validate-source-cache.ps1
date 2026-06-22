Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceIndexPath = Join-Path $repoRoot 'data/source-index.json'
$topicManifestPath = Join-Path $repoRoot 'data/topic-manifest.json'
$checklistPath = Join-Path $repoRoot 'data/source-capture-checklist.json'

function Read-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Add-Failure {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]] $Failures,
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    $Failures.Add($Message) | Out-Null
}

$failures = [System.Collections.Generic.List[string]]::new()

$sourceIndex = Read-JsonFile -Path $sourceIndexPath
$topicManifest = Read-JsonFile -Path $topicManifestPath
$checklist = Read-JsonFile -Path $checklistPath

$sourceTypeIds = @{}
foreach ($sourceType in $sourceIndex.sourceTypes) {
    $sourceTypeIds[$sourceType.id] = $true
}

$sourceIds = @{}
foreach ($source in $sourceIndex.officialSources) {
    if ($sourceIds.ContainsKey($source.id)) {
        Add-Failure $failures "Duplicate source id: $($source.id)"
    }
    $sourceIds[$source.id] = $true

    if (-not $sourceTypeIds.ContainsKey($source.sourceType)) {
        Add-Failure $failures "Source '$($source.id)' uses unknown sourceType '$($source.sourceType)'."
    }

    if (-not ($source.capturedAt -match '^\d{4}-\d{2}-\d{2}$')) {
        Add-Failure $failures "Source '$($source.id)' capturedAt must be YYYY-MM-DD."
    }

    if (-not $source.urls -or $source.urls.Count -eq 0) {
        Add-Failure $failures "Source '$($source.id)' must include at least one URL."
    }

    foreach ($url in $source.urls) {
        if (-not [System.Uri]::IsWellFormedUriString($url, [System.UriKind]::Absolute)) {
            Add-Failure $failures "Source '$($source.id)' has invalid URL: $url"
        }
    }

    if (-not $source.supports -or $source.supports.Count -eq 0) {
        Add-Failure $failures "Source '$($source.id)' must include supports."
    }

    if (-not $source.doesNotProve -or $source.doesNotProve.Count -eq 0) {
        Add-Failure $failures "Source '$($source.id)' must include doesNotProve."
    }
}

$topicIds = @{}
foreach ($topic in $topicManifest.topics) {
    if ($topicIds.ContainsKey($topic.id)) {
        Add-Failure $failures "Duplicate topic id: $($topic.id)"
    }
    $topicIds[$topic.id] = $true

    foreach ($starterSource in $topic.starterSources) {
        if (-not $sourceIds.ContainsKey($starterSource)) {
            Add-Failure $failures "Topic '$($topic.id)' references missing starterSource '$starterSource'."
        }
    }

    if (-not $topic.mustNotInclude -or $topic.mustNotInclude.Count -eq 0) {
        Add-Failure $failures "Topic '$($topic.id)' must include public-boundary exclusions."
    }
}

foreach ($relatedFile in $sourceIndex.relatedFiles) {
    $path = Join-Path $repoRoot $relatedFile.path
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure $failures "relatedFiles path does not exist: $($relatedFile.path)"
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $checklist.canonicalHumanGuide))) {
    Add-Failure $failures "Checklist canonicalHumanGuide does not exist: $($checklist.canonicalHumanGuide)"
}

foreach ($step in $checklist.jsonUpdateSteps) {
    if ([string]::IsNullOrWhiteSpace($step)) {
        Add-Failure $failures "Checklist jsonUpdateSteps contains a blank step."
    }
}

if ($failures.Count -gt 0) {
    Write-Error ("Source cache validation failed:`n- " + ($failures -join "`n- "))
}

Write-Host "Source cache validation passed."
