$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$templates = Get-ChildItem -Path (Join-Path $repoRoot "templates") -Directory -Recurse |
    Where-Object { Test-Path (Join-Path $_.FullName "versions.tf") }

foreach ($template in $templates) {
    $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $template.FullName)
    Write-Host "Validating $relativePath"
    Push-Location $template.FullName
    try {
        tofu init -backend=false -input=false | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "tofu init failed for $relativePath" }
        tofu validate | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "tofu validate failed for $relativePath" }
    }
    finally {
        Pop-Location
    }
}

Write-Host "Validated $($templates.Count) templates."
