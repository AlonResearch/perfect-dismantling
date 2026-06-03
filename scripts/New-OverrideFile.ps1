param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath,

    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$ModName = "modPerfectDismantling"
)

$ErrorActionPreference = "Stop"

$cleanRelativePath = $RelativePath.TrimStart("\", "/")
$referenceFile = Join-Path (Join-Path $ProjectRoot "uncooked\content0") $cleanRelativePath
$targetFile = Join-Path (Join-Path $ProjectRoot "source\$ModName\content") $cleanRelativePath
$targetDir = Split-Path $targetFile -Parent

if (!(Test-Path $referenceFile)) {
    throw "Reference file not found: $referenceFile"
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Copy-Item -LiteralPath $referenceFile -Destination $targetFile -Force

Write-Host "Copied override source: $targetFile"
