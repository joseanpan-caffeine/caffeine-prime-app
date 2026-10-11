# Design system — Caffeine Army Prime (derivado do Figma "Painel do assinante")

Referências visuais (PNG exportados do Figma) em `/tmp/claude-0/-home-claude/579005b8-6483-56a5-a1ae-5e65b01227f4/scratchpad/figma/` — originais na raiz, versões redimensionadas em `view/`. Ver especialmente `view/col1a.png` + `view/col1b.png` (dashboard mobile completo, coluna 1), `view/atoms_a.png` (átomos: header, botões, badges), `view/nextbox.png` (card "próxima caixa"), `view/alerts.png` (toasts, stepper, timeline, item de caixa, tabs), `view/editmenu.png` (menu de ação do item), `view/sectionmobile.png` (listas de seção), `Pedido.png`, `Produt Carrousel.png`, `Benefit Section.png`.

## Tema: CLARO (não escuro)

| Token | Hex | Uso |
|---|---|---|
| `bg.page` | `#F3F3F3` | fundo das telas |
| `bg.surface` | `#FFFFFF` | cards, header |
| `bg.subtle` | `#F8F9FA` | círculos de ícone, áreas secundárias |
| `bg.muted` | `#E9ECEF` | botão desabilitado, placeholders |
| `border` | `#E9ECEF` / `#DEE2E6` | divisores |
| `brand.dark` | `#260F0F` | card "próxima caixa", header do perfil (variante), badges "20% OFF", texto de badge de plano |
| `brand.dark2` | `#331E1E` | superfícies dentro do card escuro |
| `brand.primary` | `#F1D98A` | botão primário (texto `#260F0F`), borda do botão secundário |
| `brand.primaryStrong` | `#EBC969` | badge "EXCLUSIVO PRIME", botão "Editar caixa" dentro do card escuro (gradiente `#C28B14`→`#E4BD6F`) |
| `brand.gold` | `#DBA73F` | nome do cliente ("Olá, Brenda"), valor de economia, ícones de seção, tab ativa |
| `brand.goldDeep` | `#DDA41F` | badge "PRIME ANUAL" (bg) |
| `brand.purple` | `#7B44DA` | Caffeine Army X (ícone, botão "Resgatar", pontos) |
| `brand.purpleSoft` | `#EAE1F9` | fundo card Caffeine X |
| `success` | `#82C91E` | botão "Confirmar edição", toast ok, check da timeline |
| `successDeep` | `#74B816` | badge "ECONOMIZE R$ …", "15% OFF" |
| `successSoft` | `#EEF6E2` / `#C1DB96` | badge "Assinatura ativa" (bg `#C1DB96`-ish claro, texto `#2B8A3E`) |
| `warning` | `#F59F00` | ponto "1 item adicionado", barra de vigência |
| `warningSoft` | `#FFF3BF` | badge "Edição indisponível" / "Assinatura pausada" (texto `#F08C00`) |
| `danger` | `#C92A2A` | "Remover item", "Cancelar e perder benefícios" |
| `dangerSoft` | `#FFE3E3` | badge "Pagamento pendente" (texto `#C92A2A`), card de pagamento recusado |
| `info` | `#006EBB` | badges "Assinatura em análise", "Edição disponível até…" |
| `infoSoft` | `#D9F2FC` | fundo desses badges |
| `text.primary` | `#212529` | títulos |
| `text.secondary` | `#495057` | corpo |
| `text.muted` | `#909296` | legendas, "Assinatura cancelada" |

## Tipografia
- Marca usa **Acumin Pro** (Adobe Fonts) — não embutível sem licença. Usar **Archivo** (Google Fonts via `@expo-google-fonts/archivo`) como substituto: Archivo 400/500/600/700 para texto; `Archivo_700Bold` com `letterSpacing: -0.3` para títulos. Centralizar em `theme/typography.ts` com `fonts.body`, `fonts.heading`, `fonts.display`; trocar para Acumin é mudar esse arquivo.
- Logo "CAFFEINE ARMY PRIME": renderizar como texto em dois níveis (CAFFEINE ARMY pequeno em caixa alta + PRIME grande, itálico-pesado) até receber o SVG oficial.
- Escala: display 28, h1 22, h2 18, h3 16, body 14, small 12, caption 11. Line-height 1.3.

## Forma
- Radius: cards 12, botões 8, badges 4 (pill para status), círculos de ícone 56.
- Sombra de card: `shadowColor #000, opacity 0.06, radius 8, offsetY 2` (elevation 2).
- Espaçamento base 4; padding de card 16; gap entre seções 12; margem lateral 16.
- Botões: altura 44; primário `#F1D98A` texto `#260F0F` peso 600; secundário fundo branco borda `#F1D98A` texto `#260F0F`; ghost texto `#260F0F`; danger texto `#C92A2A`; success `#82C91E` texto branco; purple `#7B44DA` texto branco; loading mostra spinner no lugar do texto.

## Padrões de componente (do Figma)
- **Header da tela**: branco, ícone menu à esquerda, logo centralizada, ícone perfil à direita.
- **Card de boas-vindas**: badge "PRIME ANUAL" (bg `#DDA41F`, texto `#260F0F`, caixa alta 10px), "Olá, {nome}" em dourado 20px, badge "Assinatura ativa" à direita + ícone sair. Abaixo: **linha de ações rápidas** com 5 círculos (`#F8F9FA`, ícone `#495057`) e rótulo em 2 linhas (Editar Caixa, Perfil e Pedidos, Minha Assinatura, Caffeine Army X, Clube de Vantagens). Abaixo: **faixa de economia** (`#F8F9FA`): "Economia total" + valor grande; "Últimos 2 meses" + mês/valor ×2.
- **Minhas próximas caixas**: título com ícone cubo dourado + subtítulo "Acompanhe seus pedidos mês a mês" + setas ‹ › (círculo cinza / círculo preto). Carrossel horizontal de **cards escuros** `#260F0F`: topo "Data de pagamento / 17 de Julho" e "Valor total / R$ 178,80"; grade de produtos (thumb 72px com badge de quantidade preto no canto e lápis dourado) + bloco "+ Adicionar itens à caixa" (bg `#331E1E` com borda tracejada dourada); "Seus brindes da próxima caixa" com chevron e thumbs 56px; botão "Editar caixa" dourado-gradiente centralizado; rodapé "ⓘ Você pode alterar sua caixa até 14/07". Variante clara (`#F8F9FA`, desaturada) quando "Pagamento pendente".
- **Dupla de cards** Caffeine Army X (ícone X roxo, "Você possui 1.580 pontos" em roxo) e Clube de Vantagens (ícone dourado, "Até 20% OFF em parceiros").
- **Itens exclusivos**: título com raio dourado "Complete sua rotina com itens exclusivos" + subtítulo; carrossel de cards brancos 140px: badge "EXCLUSIVO PRIME" (`#EBC969`), imagem, nome bold, sabor, peso/doses, "R$ 184,90 compra única" riscado cinza, "R$ 157,16" + badge "15% OFF" verde; botão "Adicionar à caixa" primário + "Comprar" secundário.
- **Listas de seção** (Entrega e pagamento / Minha assinatura / Ajuda e suporte): título 14px bold cinza-escuro fora do card; card branco com linhas: ícone dourado 20px à esquerda, título bold 14, subtítulo 12 cinza, chevron à direita; divisor `#E9ECEF`. Linha "Meu plano" expandida mostra "Plano atual / Anual", "Assinante desde / 12/08/2023", barra "Vigência" dourada com "Restam X meses…". Linha "Cancelar e perder benefícios" em vermelho com ícone ⊗.
- **Benefícios exclusivos**: "Programa de pontos: Caffeine Army X" + carrossel de brindes (imagem, nome, "898 pts para resgate" roxo, botão "Resgatar" roxo). "Clube de Vantagens" com logos de parceiros e "8% OFF".
- **Alertas** (`view/alerts.png`, `atoms_a` direita): cards com ícone à esquerda e título bold: "Caixa em trânsito!" (verde), "Caixa entregue!", "Caixa em preparo", "Alteração de caixa agendada!" (com botão "Editar caixa" escuro), "Por que não consigo editar minha caixa agora?" (cinza, explica janela de cobrança). Pagamento recusado: borda/título vermelho, cartão com bandeira, opções em rádio (cartão atual / PIX / outro cartão), botões "Regularizar assinatura" + "Fale conosco". PIX: QR grande, "Você deve pagar até 01/01/24", campo copia-e-cola com botão "Copiar link". Pausada: card bege `#FFF3BF`-ish "Assinatura pausada… Retomar assinatura".
- **Item da caixa (edição)**: linha com thumb, nome bold, "250g - 25 Doses", "⟳ Recorrência de 60 dias", botão "Editar" pequeno amarelo; expandido mostra "Trocar recorrência" e "Remover item" (vermelho). **Menu de ação** (action sheet): Trocar sabor / Trocar tamanho / Trocar recorrência / Remover item (vermelho) + Cancelar separado.
- **Stepper** quantidade: caixa cinza com − e + nas pontas. **Tabs de categoria**: texto, ativa dourada com sublinhado dourado.
- **Resumo de edição** (sticky inferior): "Total R$ 390,49/mês ~~R$ 590,49~~", "3 itens · Ver todos ↗", badge "ECONOMIZE R$ 126,98" verde, "● 1 item adicionado" laranja, botão "Confirmar edição da assinatura" verde `#82C91E`.
- **Timeline de fidelidade**: 4 pontos verdes com check "Próxima caixa 17 de Julho / Mês 2 / Mês 3 / Mês 4".
- **Toasts**: branco com sombra, ícone verde (ok) ou vermelho (erro) + título bold + texto.
