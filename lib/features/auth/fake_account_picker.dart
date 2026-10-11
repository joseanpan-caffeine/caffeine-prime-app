import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// Contas fake do adaptador em memória do BFF (ROUTES.md). Senha: prime123.
/// Só aparece com FAKE_AUTH=true.
const List<({String email, String scenario})> fakeAccounts = <({String email, String scenario})>[
  (email: 'ativa@teste.com', scenario: 'Anual ativa, 2 créditos de pausa, pedido em trânsito'),
  (email: 'janela@teste.com', scenario: 'Semestral, cobrança amanhã (janela D-3 fechada)'),
  (email: 'pausada@teste.com', scenario: 'Anual pausada por 2 ciclos'),
  (email: 'pendente@teste.com', scenario: 'Trimestral com fatura pendente e PIX'),
  (email: 'agendada@teste.com', scenario: 'Anual com mudança agendada'),
  (email: 'cancelada@teste.com', scenario: 'Cancelada há 20 dias (pode reativar)'),
  (email: 'analise@teste.com', scenario: 'Em análise antifraude'),
  (email: 'mensal@teste.com', scenario: 'Mensal, sem créditos de pausa'),
  (email: 'semassinatura@teste.com', scenario: 'Cliente sem assinatura'),
  (email: 'novata@teste.com', scenario: 'Anual com 1 cobrança (não pode pausar/cancelar)'),
  (email: 'fim-fidelidade@teste.com', scenario: 'Fidelidade cumprida: pode cancelar'),
];

const String fakePassword = 'prime123';

/// Abre um bottom sheet para escolher a conta de teste. Devolve o e-mail.
Future<String?> pickFakeAccount(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: <Widget>[
            Text('Conta de teste', style: AppTypography.h3),
            Text('Adaptador em memória do BFF · senha $fakePassword', style: AppTypography.caption),
            const SizedBox(height: 8),
            for (final ({String email, String scenario}) a in fakeAccounts)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_circle_outlined, color: AppColors.brandGold),
                title: Text(a.email, style: AppTypography.bodyBold),
                subtitle: Text(a.scenario, style: AppTypography.caption),
                onTap: () => Navigator.of(ctx).pop(a.email),
              ),
          ],
        ),
      );
    },
  );
}
