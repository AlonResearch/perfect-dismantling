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

$sourceFiles = Get-ChildItem -LiteralPath $sourceContent -Recurse -File | Where-Object { $_.Name -ne ".gitkeep" }
if ($sourceFiles.Count -eq 0) {
    throw "No mod source files found in $sourceContent."
}

if (Test-Path $distMod) {
    Remove-Item -LiteralPath $distMod -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $distContent | Out-Null

$scriptSource = Join-Path $sourceContent "scripts"
if (Test-Path $scriptSource) {
    Copy-Item -LiteralPath $scriptSource -Destination $distContent -Recurse -Force
}

$packableFiles = Get-ChildItem -LiteralPath $sourceContent -Recurse -File | Where-Object {
    $_.Name -ne ".gitkeep" -and $_.FullName -notlike (Join-Path $scriptSource "*")
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
