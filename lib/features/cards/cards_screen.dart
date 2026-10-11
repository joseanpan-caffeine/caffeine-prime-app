import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/payment.dart';
import '../../api/models/subscription.dart';
import '../../core/card_brands.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../data/subscription_actions.dart';
import '../../router.dart';
import 'new_card_form.dart';

/// Cartões cadastrados (GET/DELETE /me/payment-profiles) + adicionar novo.
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PaymentProfile>> cards = ref.watch(paymentProfilesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Formas de pagamento')),
      body: cards.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(paymentProfilesProvider)),
        data: (List<PaymentProfile> list) => ListView(
          padding: const EdgeInsets.all(AppDims.pageMargin),
          children: <Widget>[
            if (list.isEmpty)
              const EmptyView(title: 'Nenhum cartão cadastrado', icon: Icons.credit_card_off_outlined)
            else
              for (final PaymentProfile p in list) ...<Widget>[
                PaymentProfileTile(
                  profile: p,
                  onRemove: list.length > 1 && !p.isDefault
                      ? () async {
                          try {
                            await ref.read(subscriptionActionsProvider).removeCard(p.id);
                            if (context.mounted) showSuccessToast(context, 'Cartão removido');
                          } catch (e) {
                            if (context.mounted) showErrorToast(context, e);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 8),
            PrimeButton(
              label: 'Adicionar novo cartão',
              icon: Icons.add_card_rounded,
              onPressed: () async => context.push(Routes.newCard),
            ),
            const SizedBox(height: 12),
            Text(
              'O cartão principal é usado nas próximas cobranças. A troca pode levar alguns instantes para refletir na assinatura.',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentProfileTile extends StatelessWidget {
  const PaymentProfileTile({super.key, required this.profile, this.onRemove, this.trailing});

  final PaymentProfile profile;
  final Future<void> Function()? onRemove;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final String? logo = CardBrands.forBrand(profile.brand);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            height: 28,
            child: logo != null
                ? SvgPicture.asset(logo, fit: BoxFit.contain)
                : const Icon(Icons.credit_card_rounded, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${profile.brand} •••• ${profile.lastFour}', style: AppTypography.bodyBold),
                Text('${profile.holderName} · válido até ${profile.expiration}', style: AppTypography.small),
              ],
            ),
          ),
          if (profile.isDefault) const StatusBadge(label: 'PRINCIPAL', tone: BadgeTone.success),
          if (trailing != null) trailing!,
          if (onRemove != null)
            IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
              onPressed: () async {
                final bool? ok = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text('Remover cartão?'),
                    content: Text('${profile.brand} terminado em ${profile.lastFour}.'),
                    actions: <Widget>[
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remover')),
                    ],
                  ),
                );
                if (ok == true) await onRemove!();
              },
            ),
        ],
      ),
    );
  }
}

/// Tela de novo cartão (POST /me/payment-profiles com gatewayToken da Vindi).
class NewCardScreen extends ConsumerWidget {
  const NewCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo cartão')),
      body: ListView(
        padding: const EdgeInsets.all(AppDims.pageMargin),
        children: <Widget>[
          NewCardForm(
            showDefaultSwitch: true,
            onTokenized: (TokenizedCard card, bool setAsDefault) async {
              await ref.read(subscriptionActionsProvider).addCard(
                    AddCardRequest(
                      gatewayToken: card.gatewayToken,
                      paymentCompanyCode: card.paymentCompanyCode,
                      setAsDefault: setAsDefault,
                    ),
                  );
              if (context.mounted) {
                showSuccessToast(context, 'Cartão salvo', body: 'Final ${card.lastFour}.');
                context.pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
