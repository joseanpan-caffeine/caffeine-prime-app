# Caffeine Prime — app (iOS / Android)

App de gestão da assinatura **Caffeine Army Prime**, em React Native + Expo (SDK 57), TypeScript e Expo Router.
O app conversa **somente com o BFF** (`/v1`); nenhuma chave de terceiro fica no app, exceto a chave pública da Vindi (tokenização de cartão).

- Contrato: `src/api/contracts.ts` (tipos públicos do BFF) e `ROUTES.md` (rotas, corpos e contas de teste).
- Arquitetura: `docs-arquitetura.md`.

## Como rodar

Pré-requisitos: Node 22+, app **Expo Go** no celular (ou simulador) e o BFF fake rodando em `http://localhost:3333`.

```bash
npm install
cp .env.example .env        # EXPO_PUBLIC_API_URL=http://localhost:3333/v1, EXPO_PUBLIC_FAKE_AUTH=1
npx expo start              # ou: npm run ios | npm run android | npm run web
```

> Celular físico: o `localhost` do celular não é o do computador. Troque `EXPO_PUBLIC_API_URL` para o IP da sua máquina na rede (ex.: `http://192.168.0.10:3333/v1`) ou use `npx expo start --tunnel` com o BFF exposto.

Outros scripts: `npm run typecheck` (tsc), `npm run lint` (eslint via `expo lint`), `npm run icons` (regenera os PNGs placeholder em `assets/`).

### Contas de teste (BFF fake, senha `prime123`)

| E-mail | Cenário |
|---|---|
| ativa@teste.com | Anual, ativa, 2 créditos de pausa, cobrança em 12 dias, pedido em trânsito |
| janela@teste.com | Semestral, cobrança amanhã (janela D-2 fechada → edição bloqueada) |
| pausada@teste.com | Anual, pausada, retoma em 2 ciclos |
| pendente@teste.com | Trimestral, fatura pendente com PIX |
| agendada@teste.com | Anual, com mudança agendada (botão "Desfazer") |
| cancelada@teste.com | cancelada há 20 dias (pode reativar) |
| analise@teste.com | fraud_review → tela "Em análise" |
| mensal@teste.com | Mensal, sem créditos de pausa |
| semassinatura@teste.com | cliente sem assinatura → tela "Sem assinatura" |

### Modo fake (`EXPO_PUBLIC_FAKE_AUTH=1`)

- Botões **Google/Apple** abrem um sheet pedindo o e-mail e enviam `idToken: "fake:<email>"` para `POST /auth/google|apple`.
- **Link mágico**: a tela mostra o `debugToken` devolvido pelo BFF e um botão "Usar este token" (`POST /auth/magic-link/exchange`). O deep link equivalente é `caffeineprime://auth/magic/<token>` — para testar: `npx uri-scheme open "caffeineprime://auth/magic/<token>" --ios` (ou `--android`).
- **Cartões**: o formulário não chama a Vindi; envia `gatewayToken: "fake-token-<últimos 4 dígitos>"`.
- A tela de login já vem preenchida com `ativa@teste.com / prime123`.

## Apontar para staging / produção

Variáveis `EXPO_PUBLIC_*` são lidas em build time (Metro). Para trocar de ambiente:

```bash
EXPO_PUBLIC_API_URL=https://bff-staging.caffeinearmy.com.br/v1 EXPO_PUBLIC_FAKE_AUTH=0 npx expo start --clear
```

Os perfis de `eas.json` (`development`, `preview`, `production`) já definem `EXPO_PUBLIC_API_URL` e `EXPO_PUBLIC_FAKE_AUTH` por ambiente — ajuste as URLs reais do BFF antes do primeiro `eas build`.
Push notifications só funcionam em **development build** (`eas build --profile development`), não no Expo Go; o app detecta e ignora o registro quando não dá (web, Expo Go, simulador, sem permissão).

## Ligar Google / Apple reais

1. Defina `EXPO_PUBLIC_FAKE_AUTH=0`.
2. **Google** (`expo-auth-session/providers/google`): crie os client IDs no Google Cloud (iOS, Android e Web) e preencha `EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID`, `EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID`, `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID`. O iOS/Android exigem development build (o Expo Go não aceita client IDs nativos). O app envia o `id_token` para `POST /auth/google`.
3. **Apple** (`expo-apple-authentication`): o `app.config.ts` já tem `ios.usesAppleSignIn: true` e o plugin; habilite "Sign in with Apple" no App ID (Apple Developer). O app envia `identityToken` e `fullName` (só no primeiro login) para `POST /auth/apple`. Botão aparece apenas no iOS (ou em modo fake).
4. **Link mágico** em produção: configure o Universal Link / App Link para `caffeineprime://auth/magic/:token` (o `intentFilter` Android já está no `app.config.ts`; para iOS adicione `associatedDomains` quando houver domínio).
5. **Vindi**: `GET /payments/vindi-config` devolve `publicKey` e `apiUrl`; o app faz `POST {apiUrl}/public/payment_profiles` com Basic auth (`publicKey:`) e só envia o `gateway_token` ao BFF.

## Estrutura

```
app/                      Expo Router (arquivo = tela)
  _layout.tsx             QueryClientProvider, bootstrap da sessão, redirecionamentos, Toast, StatusBar
  index.tsx               decide (auth) ou (tabs)
  (auth)/                 welcome, login, magic-link, register
  auth/magic/[token].tsx  deep link do link mágico
  (tabs)/                 index (Home), box (Minha caixa), orders (Pedidos), profile (Perfil)
  subscription/           pause, paused, cancel, canceled, under-review, none
  payments/               cards, pay/[billId] (PIX / cartão atual / cartão novo)
  shipping/address.tsx    CEP → cotação → formulário → salvar
  orders/[billId].tsx     detalhe da fatura com itens, pagamento e rastreio
src/
  api/                    contracts.ts (tipos), client.ts (fetch + refresh + Idempotency-Key), endpoints.ts, hooks.ts (react-query)
  components/             Screen, Card, Button, Badge, ListItem, Money, Skeleton, EmptyState, Sheet, Stepper, Toast, Input, Text, Section
  features/               auth (SocialButtons), box (useBoxEditor), orders (BillCard), payments (CardForm), subscription (ReasonPicker)
  lib/                    env, secureStorage, session, push, vindi, socialAuth, format, labels
  store/auth.ts           zustand: tokens + usuário + status da sessão
  theme/                  tokens (cores, espaçamento base 4, radius 16, tipografia com fontFamily para GT Pressura/Rund)
scripts/generate-icons.mjs  gera os PNGs placeholder
```

### Regras que o app NÃO reimplementa

Tudo que é regra de negócio (janela D-2, créditos de pausa, elegibilidade de cancelamento, melhor desconto) vem do BFF em `dashboard.capabilities`. O app só exibe `allowed: false` com o motivo (`src/lib/labels.ts → capabilityReasonLabel`) e desabilita o CTA.

### Suposições sobre o contrato (confirmar com o BFF)

- `POST /auth/magic-link` em modo fake devolve `{ sent: true, debugToken?: string }` (o campo `debugToken` não está em `contracts.ts`; é opcional no app).
- `BoxItemInput.handle` é o handle do **sabor** quando o produto tem `flavors`, senão o handle do produto. `Subscription.items[].handle` segue a mesma convenção (o app procura o produto do catálogo pelo handle do produto ou de um dos sabores).
- A troca de recorrência 60 dias de um item **já existente** na assinatura usa `PATCH /me/subscription/items/:itemId/recurrence` imediatamente (quando não há outras edições pendentes); itens novos/edições em lote mandam `recurrence` dentro do `SchedulingRequest`.
- `GET /me/subscription`, `/me/tracking` e `/me/shipping-address` podem responder 404 → tratados como "não há".
- O QR do PIX vem como imagem (`pix.qrCodeImageUrl`), renderizada com `expo-image`.
