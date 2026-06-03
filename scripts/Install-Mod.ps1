param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$ModName = "modPerfectDismantling",
    [string]$GamePath = "C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3"
)

$ErrorActionPreference = "Stop"

$distMod = Join-Path $ProjectRoot "dist\$ModName"
$targetMod = Join-Path $GamePath "Mods\$ModName"

if (!(Test-Path (Join-Path $distMod "content\blob0.bundle"))) {
    throw "Built bundle not found. Run .\scripts\Build-Mod.ps1 first."
}

if (Test-Path $targetMod) {
    Remove-Item -LiteralPath $targetMod -Recurse -Force
}

Copy-Item -LiteralPath $distMod -Destination $targetMod -Recurse -Force
Write-Host "Installed $ModName to $targetMod"
Write-Host "Now run Witcher Script Merger and check for XML/bundle conflicts."
