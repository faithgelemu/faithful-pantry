$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $projectRoot 'build\web'
$workerPath = Join-Path $buildRoot 'sw.js'
$outputPath = Join-Path $buildRoot 'sw-assets.js'

if (!(Test-Path $workerPath)) {
    throw 'Build the web app first. build\web\sw.js is missing.'
}

$files = @(
    Get-ChildItem $buildRoot -Recurse -File |
        ForEach-Object {
            $relativePath = $_.FullName.Substring(
                $buildRoot.Length + 1
            ).Replace('\', '/')

            if (
                $relativePath -notmatch '\.(map|symbols)$' -and
                $relativePath -notin @(
                    'sw.js',
                    'sw-assets.js',
                    'flutter_service_worker.js',
                    'ocr_test.html'
                )
            ) {
                [PSCustomObject]@{
                    Path = $relativePath
                    FullName = $_.FullName
                }
            }
        } |
        Sort-Object Path
)

foreach ($required in @(
    'index.html',
    'flutter_bootstrap.js',
    'main.dart.js',
    'canvaskit/canvaskit.js',
    'canvaskit/canvaskit.wasm'
)) {
    if ($required -notin $files.Path) {
        throw "Required release file missing: $required"
    }
}

$hashEntries = foreach ($file in $files) {
    $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
    "$($file.Path):$hash"
}

$hashEntries += 'worker:' + (
    Get-FileHash $workerPath -Algorithm SHA256
).Hash

$hashInput = [Text.Encoding]::UTF8.GetBytes(
    $hashEntries -join "`n"
)

$sha = [Security.Cryptography.SHA256]::Create()

try {
    $version = [BitConverter]::ToString(
        $sha.ComputeHash($hashInput)
    ).Replace('-', '').ToLowerInvariant()
} finally {
    $sha.Dispose()
}

$manifest = [ordered]@{
    version = $version
    files = @($files | ForEach-Object { $_.Path })
}

$json = $manifest | ConvertTo-Json -Depth 4 -Compress
$script = "self.PANTRY_PRECACHE = $json;"

[IO.File]::WriteAllText(
    $outputPath,
    $script,
    [Text.UTF8Encoding]::new($false)
)

Write-Host "Prepared offline asset list: $($files.Count) files."
Write-Host "Cache version: $($version.Substring(0, 12))"