# Caffeine Army Prime — app Flutter (POC)

Aplicativo iOS/Android de gestão da assinatura **Prime** da Caffeine Army, com os módulos de engajamento preparados (rotina, saúde/wearables e assistente Prime IA). Fala **só com o BFF** (`caffeine-prime-bff`, contrato em `api.ts` / `ROUTES.md`); nunca com a Prime API direto.

> UI em português; identificadores em inglês; comentários em português. Design: tema **claro**, tokens em `lib/core/theme/tokens.dart`, fonte Archivo via `google_fonts`.

---

## 1. Pré-requisitos no Windows

### Flutter
Opção A (winget):
```powershell
winget install --id=Google.Flutter -e
```
Opção B (zip): baixe o SDK estável em https://docs.flutter.dev/get-started/install/windows, extraia em `C:\dev\flutter` (sem espaços no caminho) e adicione `C:\dev\flutter\bin` ao **PATH** do usuário (Configurações › Sistema › Sobre › Configurações avançadas › Variáveis de ambiente).

Depois, em um PowerShell novo:
```powershell
flutter --version      # precisa ser 3.24+ (Dart 3.5+)
flutter doctor         # mostra o que falta
```

### Android
1. Instale o **Android Studio** (https://developer.android.com/studio). No assistente, inclua Android SDK, SDK Platform-Tools e um emulador.
2. Em Android Studio › More Actions › **SDK Manager** › SDK Tools: marque *Android SDK Command-line Tools* e *Android SDK Build-Tools*.
3. Rode `flutter doctor --android-licenses` e aceite tudo.
4. Crie um emulador em **Device Manager** (ex.: Pixel 7, API 34). Inicie-o antes de `flutter run`.

### iOS
Build iOS **exige um Mac** com Xcode. No Windows você consegue compilar e testar Android e Web; o `ios/` só é usado no Mac.

---

## 2. Gerar as pastas de plataforma (uma vez)

Este repositório **não** contém `android/` nem `ios/`. Na raiz do projeto, rode exatamente:

```powershell
flutter create --org com.caffeinearmy --project-name caffeine_prime --platforms=android,ios,web .
```

Isso cria `android/`, `ios/` e `web/` com `applicationId` / bundle id **`com.caffeinearmy.caffeine_prime`**. Se quiser exatamente `com.caffeinearmy.prime`, edite depois `android/app/build.gradle` (`applicationId`) e, no Xcode, o Bundle Identifier. Os arquivos já existentes (`lib/`, `pubspec.yaml`, `assets/`) não são sobrescritos.

Depois de gerar, ajustes necessários:

**Android** (`android/app/build.gradle`): `minSdkVersion 26` e `compileSdkVersion 34` (exigidos por `health` e `flutter_local_notifications`). Em `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED"/>
<uses-permission android:name="android.permission.health.READ_EXERCISE"/>
<uses-permission android:name="android.permission.health.READ_SLEEP"/>
```
Dentro de `<activity android:name=".MainActivity" …>`, deep links:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="caffeineprime"/>
  <data android:scheme="app"/>
</intent-filter>
<!-- Health Connect: permissão -->
<intent-filter>
  <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"/>
</intent-filter>
```
Para Health Connect no Android 14+, a `MainActivity` precisa estender `FlutterFragmentActivity` (veja a doc do pacote `health`).

**iOS** (`ios/Runner/Info.plist`): `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `CFBundleURLTypes` com os esquemas `caffeineprime` e `app`; no Xcode, capabilities *HealthKit*, *Push Notifications*, *Background Modes › Remote notifications* e *Sign in with Apple*. Ícone de launcher: use `assets/icon.png` com o pacote `flutter_launcher_icons` (não incluído) ou substitua manualmente os mipmaps/AppIcon.

---

## 3. Rodar contra o BFF fake

1. Suba o BFF (`caffeine-prime-bff`) em modo fake na porta 3333 (`/v1`). Ele aceita CORS de `localhost` em qualquer porta.
2. **Web (rápido, para conferir telas):**
   ```powershell
   .\rodar.ps1
   # = flutter run -d chrome --dart-define=API_URL=http://localhost:3333/v1 --dart-define=FAKE_AUTH=true --web-port 8081
   ```
3. **Emulador Android:** o padrão de `API_URL` já é `http://10.0.2.2:3333/v1` (o host visto de dentro do emulador):
   ```powershell
   flutter run -d emulator-5554 --dart-define=FAKE_AUTH=true
   ```
4. **Aparelho físico:** use o IP da sua máquina na rede: `--dart-define=API_URL=http://192.168.0.10:3333/v1`.

`FAKE_AUTH=true` faz o app: mostrar um seletor de contas de teste; enviar `idToken = "fake:<email>"` no login Google/Apple; exibir o `debugToken` do link mágico; e gerar `fake-token-<últimos 4>` em vez de tokenizar o cartão na Vindi.

### Contas de teste (senha `prime123`)
| E-mail | Cenário |
|---|---|
| ativa@teste.com | Anual ativa, 2 créditos de pausa, pedido em trânsito |
| janela@teste.com | Semestral, cobrança amanhã (janela D-3 fechada) |
| pausada@teste.com | Anual pausada por 2 ciclos (fatura R$ 0,00) |
| pendente@teste.com | Trimestral com fatura pendente e PIX |
| agendada@teste.com | Anual com mudança agendada |
| cancelada@teste.com | Cancelada há 20 dias (pode reativar) |
| analise@teste.com | Em análise antifraude |
| mensal@teste.com | Mensal, sem créditos de pausa |
| semassinatura@teste.com | Cliente sem assinatura |
| novata@teste.com | 1 cobrança paga: não pode pausar nem cancelar |
| fim-fidelidade@teste.com | Fidelidade cumprida: pode cancelar |

---

## 4. Verificar o código

```powershell
.\verificar.ps1
```
Roda `flutter --version`, `flutter pub get`, `flutter analyze` e `flutter test`, gravando tudo em **`verificacao.txt`** (continua mesmo com erro). Cole esse arquivo no chat para o Claude corrigir.

Pontos marcados com **`VERIFICAR na compilação`** no código isolam APIs de plugins cuja assinatura pode variar entre versões: `lib/core/notifications/local_notifications.dart`, `lib/core/push/firebase_push_service.dart`, `lib/features/health/device_health_service.dart`, `lib/features/auth/social_sign_in.dart`, `lib/app.dart` (app_links). Qualquer erro de compilação nesses plugins fica contido nesses arquivos.

---

## 5. Configurar depois (placeholders)

| Recurso | O que fazer | Onde no código |
|---|---|---|
| **Push (Firebase)** | Criar projeto no Firebase; adicionar `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist` (não versionar); aplicar o plugin Google Services no Gradle. Sem isso, `Firebase.initializeApp()` falha e o app usa `NoopPushService` sem quebrar. O token vai para `POST /me/devices` com `pushProvider: fcm/apns`. | `lib/core/push/` |
| **Google Sign-In** | Criar OAuth Client IDs (Android com SHA-1, iOS, Web). Passar o Client ID web em `--dart-define=GOOGLE_WEB_CLIENT_ID=…` (vira `serverClientId`, necessário para o `idToken`). iOS: `GIDClientID` + URL scheme reverso no Info.plist. | `lib/data/auth_controller.dart`, `lib/features/auth/social_sign_in.dart` |
| **Sign in with Apple** | Capability no Xcode + Service ID no Apple Developer; o BFF valida o `identityToken` em `/auth/apple`. Botão aparece só no iOS (e em FAKE_AUTH). | `lib/features/auth/social_sign_in.dart` |
| **Vindi** | Nada no app: `GET /payments/vindi-config` entrega `publicKey`/`apiUrl`; o app tokeniza em `{apiUrl}/public/payment_profiles` e envia só o `gatewayToken`. | `lib/api/endpoints/vindi_api.dart` |
| **Analytics** | Trocar `NoopAnalytics` por Firebase Analytics/Amplitude. Todo evento carrega `customerId` (= shopifyCustomerId) para cruzar com o BigQuery. | `lib/core/analytics.dart` |
| **Deep links universais** | Publicar `assetlinks.json` / `apple-app-site-association` para `https://…/account/prime/*`. | `lib/core/deep_links.dart` |

---

## 6. Onde está cada coisa

```
lib/
  main.dart, app.dart            bootstrap, ProviderScope, MaterialApp.router, listener de deep links
  router.dart                    go_router 14 (redirect por sessão, abas com StatefulShellRoute)
  core/                          env (--dart-define), tema/tokens/tipografia, formatação pt-BR,
                                 imagens de produto, bandeiras, analytics, deep links, push/, notifications/
  api/                           ApiClient (dio, bearer, refresh single-flight, Idempotency-Key), ApiError,
                                 models/ (1:1 com api.ts, por domínio), endpoints/ (uma classe por domínio)
  data/                          providers Riverpod, SessionStore (secure storage), AuthController,
                                 SubscriptionActions (mutações), ConsentsController
  features/
    auth/                        welcome, login, registro, link mágico, login social (isolado)
    home/                        dashboard + widgets (WelcomeCard, alertas, próximas caixas, duo, exclusivos, seções)
    box_editor/                  editor de caixa (controller + tela)
    orders/, pay/, cards/, address/
    subscription/                meu plano, pausar, cancelar, status (pausada/cancelada/análise/sem assinatura)
    profile/                     perfil, dados, notificações, consentimentos (LGPD)
    routine/                     rotina (check-ins, streak, heatmap, lembretes, estoque) — frente 2
    health/                      HealthService (abstração) + DeviceHealthService (pacote health) — frente 2
    assistant/                   Prime IA (threads + chat markdown) — frente 5
test/                            modelos (round-trip), formatação, imagens, streak/deep links
```

**Consentimentos (LGPD)**: `GET/PUT /me/consents`, versões em `GET /config.consentVersions`. Gates: Rotina pede `routine_data` no primeiro acesso; Saúde pede `health_data` em tela própria **antes** de qualquer permissão do sistema; Prime IA pede `ai_assistant`; push pede `push`. Tudo revogável em Perfil › Consentimentos.

---

## 7. Invariantes (contexto-prime.md §12)

- UI em português BR. O app **nunca** fala com `/admin`, `/tasks` ou `/webhooks`; só com o BFF, autenticado por usuário (identidade = `shopifyCustomerId`).
- **Nenhum preço, produto, plano, brinde ou desconto fixo** no código: tudo vem da API (`/me/catalog`, `/me/subscription`, `/preview`). O app **não recalcula** desconto; mostra o que a API devolve. As imagens embutidas são só fallback visual.
- **Prazos vêm do servidor**: `capabilities.*.closesAt/until` (fuso America/Sao_Paulo). O app formata preservando a hora de parede do offset (`Fmt.parseWall`) e não calcula D-3/D-5 localmente.
- O ciclo é de **30 dias**: só `nextBillingAt` é data confirmada; as seguintes aparecem como "Previsão".
- **Nunca guardar o id da assinatura**: todas as rotas são `/me/subscription`; após troca de plano o id muda.
- Toda ação que escreve é protegida contra **toque duplo** (botão trava enquanto roda) e envia **`Idempotency-Key`** (UUID v4) por requisição.
- **Status desconhecido** vira estado genérico "Status: {rawStatus}", nunca crash; JSON tolerante a campo ausente.
- Fatura **R$ 0,00 em ciclo pausado** é esperada (`pausedCycle`), não erro.
- Taxa de cancelamento antecipado **não** é calculada nem cobrada pelo app.
- Testes só contra homologação/fake: a API cobra cartão de verdade na Vindi.
- Analytics carrega `shopifyCustomerId`; dados de saúde/hábito só com consentimento e só **agregados diários**.
