param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$ModName = "modPerfectDismantling"
)

$ErrorActionPreference = "Stop"

$sourceContent = Join-Path $ProjectRoot "source\$ModName\content"
$reportPath = Join-Path $ProjectRoot "dist\perfect-dismantling-generation-report.txt"

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $baseUri = [Uri]((Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\')
    $pathUri = [Uri](Resolve-Path -LiteralPath $Path).Path
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

function Escape-XmlText {
    param([string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

function New-RecyclingPartsBlock {
    param([object[]]$Ingredients)

    $lines = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $Ingredients.Count; $i += 1) {
        $ingredient = $Ingredients[$i]
        $name = Escape-XmlText $ingredient.Name
        $count = [int]$ingredient.Quantity
        if ($i -eq 0) {
            $lines.Add("`t`t<recycling_parts>`t`t`t`t<parts count=`"$count`">$name</parts>")
        }
        else {
            $lines.Add("`t`t`t`t`t`t`t`t`t`t<parts count=`"$count`">$name</parts>")
        }
    }
    $lines.Add("`t`t</recycling_parts>")
    return ($lines -join [Environment]::NewLine)
}

function Get-RecipeEntries {
    param([System.IO.FileInfo[]]$Files)

    $recipesByOutput = @{}
    $parseErrors = New-Object System.Collections.Generic.List[string]
    $skippedMultiOutput = New-Object System.Collections.Generic.List[string]

    foreach ($file in $Files) {
        try {
            [xml]$xml = Get-Content -LiteralPath $file.FullName -Raw
        }
        catch {
            $parseErrors.Add("$($file.FullName): $($_.Exception.Message)")
            continue
        }

        $nodes = $xml.SelectNodes('//*[@craftedItem_name or @cookedItem_name]')
        foreach ($node in $nodes) {
            $outputName = $node.GetAttribute('craftedItem_name')
            if ([string]::IsNullOrWhiteSpace($outputName)) {
                $outputName = $node.GetAttribute('cookedItem_name')
            }
            if ([string]::IsNullOrWhiteSpace($outputName)) {
                continue
            }

            $outputQtyText = $node.GetAttribute('craftedItemQuantity')
            if ([string]::IsNullOrWhiteSpace($outputQtyText)) {
                $outputQtyText = $node.GetAttribute('cookedItemQuantity')
            }
            if (![string]::IsNullOrWhiteSpace($outputQtyText) -and $outputQtyText -ne "1") {
                $skippedMultiOutput.Add("$outputName from $($file.Name) outputs $outputQtyText")
                continue
            }

            $ingredientNodes = $node.SelectNodes('./ingredients/ingredient')
            if ($ingredientNodes.Count -eq 0) {
                continue
            }

            $ingredientsByName = [ordered]@{}
            foreach ($ingredientNode in $ingredientNodes) {
                $ingredientName = $ingredientNode.GetAttribute('item_name')
                $quantityText = $ingredientNode.GetAttribute('quantity')
                if ([string]::IsNullOrWhiteSpace($ingredientName) -or [string]::IsNullOrWhiteSpace($quantityText)) {
                    continue
                }

                $quantity = 0
                if (![int]::TryParse($quantityText, [ref]$quantity) -or $quantity -le 0) {
                    continue
                }

                if ($ingredientsByName.Contains($ingredientName)) {
                    $ingredientsByName[$ingredientName] += $quantity
                }
                else {
                    $ingredientsByName[$ingredientName] = $quantity
                }
            }

            if ($ingredientsByName.Count -eq 0) {
                continue
            }

            $ingredients = foreach ($entry in $ingredientsByName.GetEnumerator()) {
                [pscustomobject]@{
                    Name = $entry.Key
                    Quantity = $entry.Value
                }
            }

            $recipe = [pscustomobject]@{
                OutputName = $outputName
                Ingredients = @($ingredients)
                SourceFile = $file.FullName
            }

            if (!$recipesByOutput.ContainsKey($outputName)) {
                $recipesByOutput[$outputName] = New-Object System.Collections.Generic.List[object]
            }
            $recipesByOutput[$outputName].Add($recipe)
        }
    }

    return [pscustomobject]@{
        RecipesByOutput = $recipesByOutput
        ParseErrors = $parseErrors
        SkippedMultiOutput = $skippedMultiOutput
    }
}

function Update-ItemFileText {
    param(
        [string]$Text,
        [hashtable]$UniqueRecipes,
        [ref]$ChangedCount
    )

    $pattern = '(?s)<item\b(?<attrs>[^>]*)>.*?</item>'
    return [regex]::Replace($Text, $pattern, {
        param($match)

        $attrs = $match.Groups['attrs'].Value
        $nameMatch = [regex]::Match($attrs, '\bname\s*=\s*"(?<name>[^"]+)"')
        if (!$nameMatch.Success) {
            return $match.Value
        }

        $itemName = $nameMatch.Groups['name'].Value
        if (!$UniqueRecipes.ContainsKey($itemName)) {
            return $match.Value
        }

        $block = New-RecyclingPartsBlock -Ingredients $UniqueRecipes[$itemName].Ingredients
        $itemText = $match.Value
        if ($itemText -match '(?s)\s*<recycling_parts>.*?</recycling_parts>') {
            $updated = [regex]::Replace($itemText, '(?s)\s*<recycling_parts>.*?</recycling_parts>', ([Environment]::NewLine + $block), 1)
        }
        else {
            $updated = [regex]::Replace($itemText, '\s*</item>\s*$', ([Environment]::NewLine + $block + [Environment]::NewLine + "`t</item>"), 1)
        }

        if ($updated -ne $itemText) {
            $ChangedCount.Value += 1
        }
        return $updated
    })
}

$referenceRoots = @(
    (Join-Path $ProjectRoot "uncooked\content0"),
    (Join-Path $ProjectRoot "uncooked\dlc_ep1"),
    (Join-Path $ProjectRoot "uncooked\dlc_bob")
) | Where-Object { Test-Path $_ }

if ($referenceRoots.Count -eq 0) {
    throw "No extracted reference XML found under $ProjectRoot\uncooked."
}

if (Test-Path $sourceContent) {
    $resolvedSource = (Resolve-Path -LiteralPath $sourceContent).Path
    $expectedRoot = (Join-Path $ProjectRoot "source\$ModName\content")
    if ($resolvedSource -ne $expectedRoot) {
        throw "Refusing to clean unexpected source path: $resolvedSource"
    }
    Remove-Item -LiteralPath $sourceContent -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $sourceContent | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $reportPath -Parent) | Out-Null

$report = New-Object System.Collections.Generic.List[string]
$totalRecipes = 0
$totalAmbiguous = 0
$totalAppliedItems = 0
$totalFiles = 0

foreach ($root in $referenceRoots) {
    $allGameplayItemFiles = Get-ChildItem -LiteralPath $root -Recurse -Filter "*.xml" -File |
        Where-Object {
            $_.FullName -match '\\gameplay\\items(_plus)?\\' -and
            $_.Name -notlike 'def_loot*.xml'
        }

    $groups = $allGameplayItemFiles |
        Group-Object {
            $relative = Get-RelativePath -BasePath $root -Path $_.FullName
            if ($relative -match '^(?<prefix>.*?gameplay\\items(?:_plus)?)\\') {
                $matches['prefix']
            }
            else {
                $null
            }
        } |
        Where-Object { $_.Name }

    foreach ($group in $groups) {
        $files = @($group.Group)
        $recipeResult = Get-RecipeEntries -Files $files
        $recipesByOutput = $recipeResult.RecipesByOutput

        $uniqueRecipes = @{}
        $ambiguousOutputs = New-Object System.Collections.Generic.List[string]
        foreach ($outputName in $recipesByOutput.Keys) {
            $recipeList = $recipesByOutput[$outputName]
            if ($recipeList.Count -eq 1) {
                $uniqueRecipes[$outputName] = $recipeList[0]
            }
            else {
                $ambiguousOutputs.Add("$outputName ($($recipeList.Count) recipes)")
            }
        }

        $totalRecipes += $uniqueRecipes.Count
        $totalAmbiguous += $ambiguousOutputs.Count

        foreach ($file in $files) {
            $original = Get-Content -LiteralPath $file.FullName -Raw
            $changedCount = 0
            $updated = Update-ItemFileText -Text $original -UniqueRecipes $uniqueRecipes -ChangedCount ([ref]$changedCount)
            if ($changedCount -le 0 -or $updated -eq $original) {
                continue
            }

            $relative = Get-RelativePath -BasePath $root -Path $file.FullName
            $target = Join-Path $sourceContent $relative
            New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
            Set-Content -LiteralPath $target -Value $updated -Encoding Unicode

            $totalFiles += 1
            $totalAppliedItems += $changedCount
        }

        $report.Add("Group: $($group.Name)")
        $report.Add("  Unique recipes: $($uniqueRecipes.Count)")
        $report.Add("  Ambiguous skipped: $($ambiguousOutputs.Count)")
        $report.Add("  Multi-output skipped: $($recipeResult.SkippedMultiOutput.Count)")
        if ($ambiguousOutputs.Count -gt 0) {
            $report.Add("  Ambiguous outputs:")
            $ambiguousOutputs | Select-Object -First 40 | ForEach-Object { $report.Add("    $_") }
        }
        if ($recipeResult.SkippedMultiOutput.Count -gt 0) {
            $report.Add("  Multi-output recipes:")
            $recipeResult.SkippedMultiOutput | Select-Object -First 40 | ForEach-Object { $report.Add("    $_") }
        }
        if ($recipeResult.ParseErrors.Count -gt 0) {
            $report.Add("  Parse errors:")
            $recipeResult.ParseErrors | Select-Object -First 20 | ForEach-Object { $report.Add("    $_") }
        }
    }
}

$summary = @(
    "Perfect Dismantling generation complete.",
    "Generated files: $totalFiles",
    "Updated item definitions: $totalAppliedItems",
    "Unique recipes available: $totalRecipes",
    "Ambiguous recipes skipped: $totalAmbiguous",
    ""
)

Set-Content -LiteralPath $reportPath -Value ($summary + $report) -Encoding UTF8
$summary | ForEach-Object { Write-Host $_ }
Write-Host "Report: $reportPath"
