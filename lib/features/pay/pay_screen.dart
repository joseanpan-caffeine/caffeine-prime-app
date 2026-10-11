import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api/models/bills.dart';
import '../../api/models/common.dart';
import '../../api/models/payment.dart';
import '../../api/models/subscription.dart';
import '../../core/card_brands.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/alert_card.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../data/subscription_actions.dart';
import '../cards/cards_screen.dart';
import '../cards/new_card_form.dart';

enum _PayOption { currentCard, pix, newCard }

/// Regularização de fatura pendente: cartão atual, PIX (QR + copia e cola +
/// validade + regenerar) ou cartão novo (tokenizado na Vindi).
class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({super.key, required this.billId});

  final String billId;

  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> {
  _PayOption _option = _PayOption.currentCard;
  Bill? _pixBill; // fatura com `pix` após POST pay/pix

  Future<void> _payCurrent() async {
    try {
      final Bill b = await ref.read(subscriptionActionsProvider).payWithCurrentCard(widget.billId);
      if (!mounted) return;
      if (b.status == BillStatus.paid) {
        showSuccessToast(context, 'Pagamento aprovado!', body: 'Sua assinatura está regularizada.');
        context.pop();
      } else {
        showErrorToast(context, 'A cobrança não foi aprovada. Tente PIX ou outro cartão.', title: 'Pagamento recusado');
      }
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Pagamento recusado');
    }
  }

  Future<void> _generatePix() async {
    try {
      final Bill b = await ref.read(subscriptionActionsProvider).payWithPix(widget.billId);
      if (mounted) setState(() => _pixBill = b);
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível gerar o PIX');
    }
  }

  Future<void> _payNewCard(TokenizedCard card, bool _) async {
    final Bill b = await ref.read(subscriptionActionsProvider).payWithNewCard(
          widget.billId,
          PayWithNewCardRequest(gatewayToken: card.gatewayToken, paymentCompanyCode: card.paymentCompanyCode),
        );
    if (!mounted) return;
    if (b.status == BillStatus.paid) {
      showSuccessToast(context, 'Pagamento aprovado!', body: 'Cartão final ${card.lastFour} salvo na assinatura.');
      context.pop();
    } else {
      showErrorToast(context, 'A cobrança não foi aprovada.', title: 'Pagamento recusado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Bill> bill = ref.watch(billProvider(widget.billId));
    return Scaffold(
      appBar: AppBar(title: const Text('Regularizar pagamento')),
      body: bill.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(billProvider(widget.billId))),
        data: (Bill b) {
          if (b.status == BillStatus.paid) {
            return EmptyView(
              title: 'Fatura paga',
              body: 'Ciclo ${b.cycle} · ${Fmt.money(b.amount)} · pago em ${Fmt.date(b.paidAt)}.',
              icon: Icons.check_circle_outline_rounded,
              action: PrimeButton(label: 'Voltar', expanded: false, onPressed: () async => context.pop()),
            );
          }
          final PaymentProfile? card = b.paymentProfile ?? ref.watch(dashboardProvider).valueOrNull?.subscription?.paymentProfile;
          final Bill pixSource = _pixBill ?? b;
          return ListView(
            padding: const EdgeInsets.all(AppDims.pageMargin),
            children: <Widget>[
              AlertCard(
                tone: AlertTone.danger,
                icon: Icons.credit_card_off_rounded,
                title: 'Pagamento recusado',
                body: 'Fatura do ciclo ${b.cycle} · ${Fmt.money(b.amount)} · vencimento ${Fmt.date(b.dueAt)}. '
                    'Inadimplente não recebe a caixa: regularize para liberar o envio.',
              ),
              const SizedBox(height: 16),
              Text('Como você quer pagar?', style: AppTypography.h3),
              const SizedBox(height: 8),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    if (card != null)
                      RadioListTile<_PayOption>(
                        value: _PayOption.currentCard,
                        groupValue: _option,
                        onChanged: (_PayOption? v) => setState(() => _option = v!),
                        title: Text('Cartão atual (${card.brand} •••• ${card.lastFour})', style: AppTypography.bodyBold),
                        subtitle: Text('Tentar a cobrança novamente', style: AppTypography.small),
                        secondary: CardBrands.forBrand(card.brand) != null
                            ? SizedBox(width: 36, child: SvgPicture.asset(CardBrands.forBrand(card.brand)!))
                            : const Icon(Icons.credit_card_rounded),
                      ),
                    RadioListTile<_PayOption>(
                      value: _PayOption.pix,
                      groupValue: _option,
                      onChanged: (_PayOption? v) => setState(() => _option = v!),
                      title: Text('PIX', style: AppTypography.bodyBold),
                      subtitle: Text('QR Code ou copia e cola', style: AppTypography.small),
                      secondary: SizedBox(width: 28, child: SvgPicture.asset(CardBrands.pix)),
                    ),
                    RadioListTile<_PayOption>(
                      value: _PayOption.newCard,
                      groupValue: _option,
                      onChanged: (_PayOption? v) => setState(() => _option = v!),
                      title: Text('Outro cartão', style: AppTypography.bodyBold),
                      subtitle: Text('Passa a ser o cartão da assinatura', style: AppTypography.small),
                      secondary: const Icon(Icons.add_card_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_option == _PayOption.currentCard && card != null) ...<Widget>[
                PaymentProfileTile(profile: card),
                const SizedBox(height: 12),
                PrimeButton(label: 'Regularizar assinatura · ${Fmt.money(b.amount)}', onPressed: _payCurrent),
              ],
              if (_option == _PayOption.pix)
                pixSource.pix != null
                    ? PixPanel(bill: pixSource, onRegenerate: _generatePix)
                    : PrimeButton(label: 'Gerar PIX · ${Fmt.money(b.amount)}', onPressed: _generatePix),
              if (_option == _PayOption.newCard)
                SurfaceCard(child: NewCardForm(submitLabel: 'Pagar ${Fmt.money(b.amount)}', onTokenized: _payNewCard)),
              const SizedBox(height: 16),
              PrimeButton(
                label: 'Fale conosco',
                variant: PrimeButtonVariant.ghost,
                onPressed: () async {
                  final String url = ref.read(appConfigValueProvider).links.support;
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) showSuccessToast(context, 'Link de atendimento copiado', body: url);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// QR Code do PIX a partir de `qrCodeText`, copia e cola, prazo e regenerar.
class PixPanel extends StatefulWidget {
  const PixPanel({super.key, required this.bill, required this.onRegenerate});

  final Bill bill;
  final Future<void> Function() onRegenerate;

  @override
  State<PixPanel> createState() => _PixPanelState();
}

class _PixPanelState extends State<PixPanel> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant PixPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tick();
  }

  void _tick() {
    // Prazo absoluto: compara instantes (não hora de parede).
    final DateTime? exp = DateTime.tryParse(widget.bill.pix?.expiresAt ?? '');
    final Duration left = exp == null ? Duration.zero : exp.difference(DateTime.now());
    if (mounted) setState(() => _left = left.isNegative ? Duration.zero : left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes % 60;
    final int s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final PixCharge pix = widget.bill.pix!;
    final bool expired = _left == Duration.zero;
    return SurfaceCard(
      child: Column(
        children: <Widget>[
          if (!expired)
            QrImageView(data: pix.qrCodeText, version: QrVersions.auto, size: 220, backgroundColor: Colors.white)
          else
            Container(
              width: 220,
              height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.bgSubtle, borderRadius: BorderRadius.circular(12)),
              child: Text('PIX expirado', style: AppTypography.bodyBold.copyWith(color: AppColors.textMuted)),
            ),
          const SizedBox(height: 12),
          Text(
            expired ? 'Este PIX expirou. Gere um novo.' : 'Você deve pagar até ${Fmt.dateTime(pix.expiresAt)}',
            style: AppTypography.bodyBold,
            textAlign: TextAlign.center,
          ),
          if (!expired) Text('Expira em ${_fmt(_left)}', style: AppTypography.small.copyWith(color: AppColors.warningText)),
          const SizedBox(height: 12),
          if (!expired)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.bgSubtle, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(pix.qrCodeText, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                  ),
                  const SizedBox(width: 8),
                  PrimeButton(
                    label: 'Copiar',
                    small: true,
                    expanded: false,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: pix.qrCodeText));
                      if (context.mounted) showSuccessToast(context, 'Código PIX copiado');
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          PrimeButton(
            label: expired ? 'Gerar novo PIX' : 'Gerar outro PIX',
            variant: expired ? PrimeButtonVariant.primary : PrimeButtonVariant.secondary,
            onPressed: widget.onRegenerate,
          ),
          const SizedBox(height: 8),
          Text(
            'Após o pagamento, a confirmação pode levar alguns minutos. O PIX vencido é recobrado no cartão à meia-noite.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
