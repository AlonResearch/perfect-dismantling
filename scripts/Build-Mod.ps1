param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$ModName = "modPerfectDismantling",
    [string]$WccPath = "C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3\WitcherScriptMerger\Tools\wcc_lite\bin\x64\wcc_lite.exe"
)

$ErrorActionPreference = "Stop"

$sourceContent = Join-Path $ProjectRoot "source\$ModName\content"
$sourceBin = Join-Path $ProjectRoot "source\$ModName\bin"
$distMod = Join-Path $ProjectRoot "dist\$ModName"
$distContent = Join-Path $distMod "content"
$distBin = Join-Path $distMod "bin"
$wccDir = Split-Path $WccPath -Parent
$wccExe = Split-Path $WccPath -Leaf

if (!(Test-Path $sourceContent)) {
    throw "Missing source content folder: $sourceContent"
}

$sourceFiles = Get-ChildItem -LiteralPath $sourceContent -Recurse -File | Where-Object { $_.Name -ne ".gitkeep" }
if ($sourceFiles.Count -eq 0) {
    throw "No mod source files found in $sourceContent."
}

if (Test-Path $distMod) {
    Remove-Item -LiteralPath $distMod -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $distContent | Out-Null
if (Test-Path $sourceBin) {
    New-Item -ItemType Directory -Force -Path $distBin | Out-Null
    Copy-Item -Path (Join-Path $sourceBin "*") -Destination $distBin -Recurse -Force
}

$scriptSource = Join-Path $sourceContent "scripts"
if (Test-Path $scriptSource) {
    Copy-Item -LiteralPath $scriptSource -Destination $distContent -Recurse -Force
}

$localizationCsvFiles = Get-ChildItem -LiteralPath $sourceContent -File -Filter "*.csv"
foreach ($csvFile in $localizationCsvFiles) {
    Copy-Item -LiteralPath $csvFile.FullName -Destination $distContent -Force

    $stringsOutput = Join-Path $distContent ($csvFile.BaseName + ".w3strings")
    $encoderManifest = Join-Path $ProjectRoot "scripts\tools\w3strings-encode\Cargo.toml"
    & cargo run --quiet --manifest-path $encoderManifest -- $csvFile.FullName $stringsOutput
    if ($LASTEXITCODE -ne 0) {
        throw "w3strings encode failed with exit code $LASTEXITCODE"
    }
}

$packableFiles = Get-ChildItem -LiteralPath $sourceContent -Recurse -File | Where-Object {
    $_.Name -ne ".gitkeep" `
        -and $_.FullName -notlike (Join-Path $scriptSource "*") `
        -and $_.Extension -ne ".csv" `
        -and $_.Extension -ne ".w3strings"
}

if ($packableFiles.Count -eq 0) {
    Write-Host "No bundle files found. Built loose-script mod at $distMod"
    return
}

Push-Location $wccDir
try {
    & ".\$wccExe" pack -dir="$sourceContent" -outdir="$distContent"
    if ($LASTEXITCODE -ne 0) {
        throw "wcc_lite pack failed with exit code $LASTEXITCODE"
    }

    & ".\$wccExe" metadatastore -path="$distContent"
    if ($LASTEXITCODE -ne 0) {
        throw "wcc_lite metadatastore failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host "Built $ModName at $distMod"
