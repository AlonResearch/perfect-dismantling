param(
    [Parameter(Mandatory = $true)]
    [string]$Pattern,

    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

$itemsRoot = Join-Path $ProjectRoot "uncooked\content0\gameplay"
if (!(Test-Path $itemsRoot)) {
    throw "Missing extracted reference XML at $itemsRoot. Run .\scripts\Extract-ReferenceXml.ps1 first."
}

Get-ChildItem -LiteralPath $itemsRoot -Recurse -Filter "def_item*.xml" -File |
    Select-String -Pattern $Pattern -SimpleMatch |
    Select-Object Path, LineNumber, Line
