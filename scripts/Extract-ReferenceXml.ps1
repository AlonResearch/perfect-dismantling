param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$GamePath = "C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3",
    [string]$WccPath = "C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3\WitcherScriptMerger\Tools\wcc_lite\bin\x64\wcc_lite.exe"
)

$ErrorActionPreference = "Stop"

$outDir = Join-Path $ProjectRoot "uncooked\content0"
$bundleDir = Join-Path $GamePath "content\content0\bundles"
$xmlBundle = Join-Path $bundleDir "xml.bundle"
$ep1OutDir = Join-Path $ProjectRoot "uncooked\dlc_ep1"
$ep1BundleDir = Join-Path $GamePath "dlc\ep1\content\bundles"
$ep1BlobBundle = Join-Path $ep1BundleDir "blob.bundle"
$bobOutDir = Join-Path $ProjectRoot "uncooked\dlc_bob"
$bobBundleDir = Join-Path $GamePath "dlc\bob\content\bundles"
$bobBlobBundle = Join-Path $bobBundleDir "blob.bundle"
$wccDir = Split-Path $WccPath -Parent
$wccExe = Split-Path $WccPath -Leaf

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $ep1OutDir | Out-Null
New-Item -ItemType Directory -Force -Path $bobOutDir | Out-Null

Push-Location $wccDir
try {
    & ".\$wccExe" uncook -indir="$bundleDir" -outdir="$outDir" -infile="$xmlBundle" -skiperrors
    if ($LASTEXITCODE -ne 0) {
        throw "wcc_lite uncook failed with exit code $LASTEXITCODE"
    }

    if (Test-Path $ep1BlobBundle) {
        & ".\$wccExe" uncook -indir="$ep1BundleDir" -outdir="$ep1OutDir" -infile="$ep1BlobBundle" -skiperrors
        if ($LASTEXITCODE -ne 0) {
            throw "wcc_lite Hearts of Stone uncook failed with exit code $LASTEXITCODE"
        }
    }

    if (Test-Path $bobBlobBundle) {
        & ".\$wccExe" uncook -indir="$bobBundleDir" -outdir="$bobOutDir" -infile="$bobBlobBundle" -skiperrors
        if ($LASTEXITCODE -ne 0) {
            throw "wcc_lite Blood and Wine uncook failed with exit code $LASTEXITCODE"
        }
    }
}
finally {
    Pop-Location
}

Write-Host "Extracted reference XML to $outDir"
Write-Host "Extracted DLC references to $ep1OutDir and $bobOutDir when available"
