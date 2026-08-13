$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$configurationRoots = @("templates", "examples") |
    ForEach-Object { Join-Path $repoRoot $_ } |
    Where-Object { Test-Path $_ }
$configurations = Get-ChildItem -Path $configurationRoots -Directory -Recurse |
    Where-Object { Test-Path (Join-Path $_.FullName "versions.tf") }

foreach ($configuration in $configurations) {
    $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $configuration.FullName)
    Write-Host "Validating $relativePath"
    Push-Location $configuration.FullName
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

Write-Host "Validated $($configurations.Count) templates and examples."
