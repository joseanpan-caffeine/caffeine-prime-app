# Roda o app Flutter no Chrome contra o BFF local (API precisa estar de pe: ..\rodar-api.ps1)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
flutter run -d chrome --web-port 8081 --dart-define=API_URL=http://localhost:3333/v1 --dart-define=FAKE_AUTH=true
