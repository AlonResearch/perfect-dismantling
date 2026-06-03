param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$ModName = "modPerfectDismantling",
    [string]$WccPath = "C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3\WitcherScriptMerger\Tools\wcc_lite\bin\x64\wcc_lite.exe"
)

$ErrorActionPreference = "Stop"

$sourceContent = Join-Path $ProjectRoot "source\$ModName\content"
$distMod = Join-Path $ProjectRoot "dist\$ModName"
$distContent = Join-Path $distMod "content"
$wccDir = Split-Path $WccPath -Parent
$wccExe = Split-Path $WccPath -Leaf

if (!(Test-Path $sourceContent)) {
    throw "Missing source content folder: $sourceContent"
}

$xmlFiles = Get-ChildItem -LiteralPath $sourceContent -Recurse -Filter *.xml -File
if ($xmlFiles.Count -eq 0) {
    throw "No XML files found in $sourceContent. Use New-OverrideFile.ps1 first, then edit the copied XML."
}

if (Test-Path $distMod) {
    Remove-Item -LiteralPath $distMod -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $distContent | Out-Null

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
