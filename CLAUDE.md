# CLAUDE.md — App Prime (Caffeine Army)

Aplicativo do Prime, o clube de assinatura da Caffeine Army (Expo / React Native, iOS e Android).
Contexto de negócio, API e regras: `docs/contexto-prime.md` (leia antes de mexer em fluxo de
assinatura). Este app fala **somente com o BFF** (`caffeine-prime-bff`, contrato em
`src/api/contracts.ts`, rotas em `ROUTES.md`); nunca com a caffeine-prime-api, a Vindi ou a Shopify
Admin diretamente.

## Invariantes

- UI em português BR.
- O app NUNCA fala com `/admin`, `/tasks` ou `/webhooks` da caffeine-prime-api. Na prática o app
  só conhece a URL do BFF (`EXPO_PUBLIC_API_URL`).
- Nenhuma chave de API compartilhada embutida no binário. Toda chamada é autenticada pelo usuário
  logado (JWT do BFF; identidade = shopifyCustomerId, que o app nunca envia nem exibe). Só a chave
  pública da Vindi (tokenização de cartão) chega ao app, via `GET /payments/vindi-config`.
- Nenhum preço, produto, plano, brinde ou desconto fixo no código: tudo vem do BFF
  (`/me/catalog`, `/me/subscription`, `/me/dashboard`). Textos de rótulo ficam em `src/lib/labels.ts`.
- O valor exibido ao cliente é o que o BFF devolve; o app não recalcula desconto. O preview de
  edição (`/me/subscription/preview`) é informativo e o total final vem da resposta do scheduling.
- Prazos (edição até D-3, pausa até D-3, desfazer pausa até D-5, pausa só a partir da 4ª cobrança
  paga, trava de cancelamento por fidelidade) são **calculados no BFF em America/Sao_Paulo** e
  chegam em `capabilities` (`allowed`, `reason`, `until`, `closesAt`). O app só exibe
  (`capabilityReasonLabel`, `capabilityDeadline`); nunca calcula D-3/D-5 no fuso do aparelho.
- A cobrança é a cada ciclo de 30 dias, não em um dia fixo do mês: mostrar sempre o
  `nextBillingAt` da API; datas seguintes são "Previsão". Nunca derivar "todo dia X".
- Nunca guardar o id da assinatura como permanente: após troca de plano ele muda (a Prime API cria
  uma assinatura `future` e cancela a atual). O app nunca envia id de assinatura: tudo é `/me/*`.
- Toda ação que escreve (editar caixa, pausar, cancelar, trocar cartão, endereço) é protegida
  contra toque duplo e retry (`Idempotency-Key` em `src/api/client.ts`, botão em `loading`).
- Status desconhecido vindo da API (`rawStatus` presente) vira estado genérico neutro
  ("Status: {raw}") e a navegação continua; nunca crash.
- Fatura de R$ 0,00 durante a pausa é esperada (`Bill.pausedCycle`): badge "Ciclo pausado", não erro.
- Testes só contra ambiente de homologação: a API cobra cartão de verdade na Vindi.
- Evento de analytics carrega shopifyCustomerId (pelo BFF) para cruzar com o BigQuery; dado de
  saúde/hábito só com consentimento (LGPD).
- `npm run typecheck`, `npm run lint` e `npx expo export --platform web` precisam ficar verdes.

## Fontes

- `docs/contexto-prime.md` — contexto de negócio (foto de 11/10/2026).
- BFF: `caffeine-prime-bff` (`openapi.yaml`, `ROUTES.md`, `CLAUDE.md`).
- Repos de referência: caffeine-prime-api (backend), ecommerce-hydrogen (Área do Assinante web).
- Regras vivas: KB "Tecnologia & Dados — Prime" no Notion.
