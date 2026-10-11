# Verificação do projeto Flutter (Windows / PowerShell).
# Roda flutter --version, pub get, analyze e test e grava TUDO em verificacao.txt,
# continuando mesmo quando um passo falha. Depois, cole o conteúdo de
# verificacao.txt no chat para o Claude corrigir os erros.
#
# Uso:  powershell -ExecutionPolicy Bypass -File .\verificar.ps1

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root
$out = Join-Path $root "verificacao.txt"

"=== Verificação Caffeine Prime — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $out -Encoding utf8

function Run-Step($title, $cmd) {
  "" | Out-File $out -Append -Encoding utf8
  "----- $title -----" | Out-File $out -Append -Encoding utf8
  "> $cmd" | Out-File $out -Append -Encoding utf8
  Write-Host ">>> $title" -ForegroundColor Cyan
  try {
    # 2>&1 junta stderr; Out-String preserva a saída inteira.
    $result = Invoke-Expression "$cmd 2>&1" | Out-String
    $result | Out-File $out -Append -Encoding utf8
    Write-Host $result
    "exit code: $LASTEXITCODE" | Out-File $out -Append -Encoding utf8
  } catch {
    "ERRO ao executar: $($_.Exception.Message)" | Out-File $out -Append -Encoding utf8
    Write-Host $_.Exception.Message -ForegroundColor Red
  }
}

Run-Step "flutter --version" "flutter --version"

if (-not (Test-Path (Join-Path $root "android")) -and -not (Test-Path (Join-Path $root "ios"))) {
  "" | Out-File $out -Append -Encoding utf8
  "AVISO: pastas android/ e ios/ não existem. Gere com:" | Out-File $out -Append -Encoding utf8
  "  flutter create --org com.caffeinearmy --project-name caffeine_prime --platforms=android,ios,web ." | Out-File $out -Append -Encoding utf8
}

Run-Step "flutter pub get" "flutter pub get"
Run-Step "flutter analyze" "flutter analyze --no-pub"
Run-Step "flutter test" "flutter test --no-pub -r expanded"

"" | Out-File $out -Append -Encoding utf8
"=== Fim ===" | Out-File $out -Append -Encoding utf8
Write-Host ""
Write-Host "Resultado gravado em $out" -ForegroundColor Green
