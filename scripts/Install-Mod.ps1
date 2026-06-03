param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$ModName = "modPerfectDismantling",
    [string]$GamePath = "C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3"
)

$ErrorActionPreference = "Stop"

$distMod = Join-Path $ProjectRoot "dist\$ModName"
$targetMod = Join-Path $GamePath "Mods\$ModName"
$distConfigDir = Join-Path $distMod "bin\config\r4game\user_config_matrix\pc"
$gameConfigDir = Join-Path $GamePath "bin\config\r4game\user_config_matrix\pc"

function Add-FileListEntry {
    param(
        [string]$FileList,
        [string]$EntryName
    )

    $entries = @()
    if (Test-Path $FileList) {
        $entries = (Get-Content -LiteralPath $FileList -Raw -Encoding ASCII) -split ";" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    }

    if ($entries -notcontains $EntryName) {
        $entries += $EntryName
    }

    $lines = $entries | ForEach-Object { "$_;" }
    Set-Content -LiteralPath $FileList -Value $lines -Encoding ASCII
}

if (!(Test-Path (Join-Path $distMod "content"))) {
    throw "Built mod content not found. Run .\scripts\Build-Mod.ps1 first."
}

$distFiles = Get-ChildItem -LiteralPath (Join-Path $distMod "content") -Recurse -File
if ($distFiles.Count -eq 0) {
    throw "Built mod content is empty. Run .\scripts\Build-Mod.ps1 first."
}

if (Test-Path $targetMod) {
    Remove-Item -LiteralPath $targetMod -Recurse -Force
}

Copy-Item -LiteralPath $distMod -Destination $targetMod -Recurse -Force
if (Test-Path $distConfigDir) {
    New-Item -ItemType Directory -Force -Path $gameConfigDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $distConfigDir "modPerfectDismantling.xml") -Destination $gameConfigDir -Force

    foreach ($fileListName in @("dx11filelist.txt", "dx12filelist.txt")) {
        $fileList = Join-Path $gameConfigDir $fileListName
        Add-FileListEntry -FileList $fileList -EntryName "modPerfectDismantling.xml"
    }

    Write-Host "Installed mod menu config to $gameConfigDir"
}
Write-Host "Installed $ModName to $targetMod"
Write-Host "Now run Witcher Script Merger and merge any script conflicts from this mod."
