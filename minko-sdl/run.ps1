param(
    [string]$Main = 'bin\PBRRendererMain.hl'
)

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$hashlink = if ($env:HASHLINK_HOME) { $env:HASHLINK_HOME } else { 'D:\hashlink-2.0.0-win' }
$main = if ([System.IO.Path]::IsPathRooted($Main)) { $Main } else { Join-Path $root $Main }

if (-not (Test-Path $main)) {
    throw "$Main not found. Run: haxe build_pbr_renderer.hxml / build_pipeline.hxml / build_phong_light_test.hxml / build_pbr_light_test.hxml"
}
if (-not (Test-Path (Join-Path $hashlink 'hl.exe'))) {
    throw "hl.exe not found under $hashlink. Set HASHLINK_HOME to the HashLink directory."
}

$env:HL_PATH = (Join-Path $root 'bin') + ';' + $hashlink
Push-Location $root
try {
    & (Join-Path $hashlink 'hl.exe') $main
}
finally {
    Pop-Location
}
