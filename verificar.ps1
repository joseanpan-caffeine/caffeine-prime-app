# Verifica o app Flutter e grava tudo em verificacao.txt (Claude le esse arquivo).
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
$out = Join-Path $PSScriptRoot "verificacao.txt"
if (Test-Path $out) { Remove-Item $out -Force }
function Run($title, $cmd) {
  Add-Content $out "`n===== $title ====="
  Write-Host "== $title" -ForegroundColor Cyan
  $output = & cmd /c "$cmd 2>&1"
  $output | Out-String -Width 400 | Add-Content $out
  Add-Content $out "(exit code: $LASTEXITCODE)"
}
Add-Content $out ("=== Verificacao Caffeine Prime " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " ===")
Run "flutter --version" "flutter --version"
Run "flutter pub get" "flutter pub get"
Run "flutter analyze" "flutter analyze --no-pub"
Run "flutter test" "flutter test --no-pub"
Write-Host "Resultado gravado em $out" -ForegroundColor Green
