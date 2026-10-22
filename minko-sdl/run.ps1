$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$hashlink = if ($env:HASHLINK_HOME) { $env:HASHLINK_HOME } else { 'D:\hashlink-2.0.0-win' }
$main = Join-Path $root 'bin\Main.hl'

if (-not (Test-Path $main)) {
    throw "bin\Main.hl not found. Run: haxe build.hxml"
}
if (-not (Test-Path (Join-Path $hashlink 'hl.exe'))) {
    throw "hl.exe not found under $hashlink. Set HASHLINK_HOME to the HashLink directory."
}

$env:HL_PATH = (Join-Path $root 'bin') + ';' + $hashlink
Push-Location $root
try {
    & (Join-Path $hashlink 'hl.exe') 'bin\Main.hl'
}
finally {
    Pop-Location
}
