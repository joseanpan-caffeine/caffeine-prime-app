import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/address.dart';
import '../../api/models/subscription.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../data/subscription_actions.dart';

/// Endereço de entrega: CEP → cotação (POST /quote) → formulário → PATCH.
/// Frete é sempre grátis para o assinante; a opção escolhida define prazo.
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _cep = TextEditingController();
  final TextEditingController _recipient = TextEditingController();
  final TextEditingController _street = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _complement = TextEditingController();
  final TextEditingController _neighborhood = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  AddressQuote? _quote;
  String? _optionId;
  bool _quoting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _cep, _recipient, _street, _number, _complement, _neighborhood, _city, _state,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(ShippingAddress? a) {
    if (_prefilled || a == null) return;
    _prefilled = true;
    _cep.text = a.postalCode;
    _recipient.text = a.recipient;
    _street.text = a.street;
    _number.text = a.number;
    _complement.text = a.complement ?? '';
    _neighborhood.text = a.neighborhood;
    _city.text = a.city;
    _state.text = a.state;
  }

  Future<void> _requestQuote() async {
    final String cep = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      showErrorToast(context, 'Informe um CEP com 8 dígitos', title: 'CEP inválido');
      return;
    }
    setState(() {
      _quoting = true;
      _quote = null;
      _optionId = null;
    });
    try {
      final AddressQuote q = await ref.read(accountApiProvider).quoteAddress(AddressQuoteRequest(postalCode: cep));
      if (!mounted) return;
      setState(() {
        _quote = q;
        _city.text = q.city;
        _state.text = q.state;
        if (q.street != null && q.street!.isNotEmpty) _street.text = q.street!;
        if (q.neighborhood != null && q.neighborhood!.isNotEmpty) _neighborhood.text = q.neighborhood!;
        if (q.options.length == 1) _optionId = q.options.first.id;
      });
      if (q.options.isEmpty) {
        showErrorToast(context, 'Não entregamos neste CEP ainda.', title: 'Sem opções de entrega');
      }
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível cotar o CEP');
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_quote == null || _optionId == null) {
      showErrorToast(context, 'Consulte o CEP e escolha a opção de entrega.', title: 'Falta a cotação');
      return;
    }
    try {
      await ref.read(subscriptionActionsProvider).updateAddress(
            UpdateAddressRequest(
              recipient: _recipient.text.trim(),
              postalCode: _cep.text.replaceAll(RegExp(r'\D'), ''),
              street: _street.text.trim(),
              number: _number.text.trim(),
              complement: _complement.text.trim().isEmpty ? null : _complement.text.trim(),
              neighborhood: _neighborhood.text.trim(),
              city: _city.text.trim(),
              state: _state.text.trim().toUpperCase(),
              quoteOptionId: _optionId!,
            ),
          );
      if (!mounted) return;
      showSuccessToast(context, 'Endereço atualizado', body: 'Vale a partir da próxima caixa.');
      context.pop();
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível salvar');
    }
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ShippingAddress?> current = ref.watch(shippingAddressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Endereço de entrega')),
      body: current.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(shippingAddressProvider)),
        data: (ShippingAddress? a) {
          _prefill(a);
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(AppDims.pageMargin),
              children: <Widget>[
                if (a != null)
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Endereço atual', style: AppTypography.smallBold.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(a.recipient, style: AppTypography.bodyBold),
                        Text(a.line1, style: AppTypography.body),
                        Text(a.line2, style: AppTypography.small),
                        if (a.deliveryEstimateDays != null)
                          Text(
                            '${a.deliveryMethod ?? 'Entrega'} · até ${a.deliveryEstimateDays} dias úteis',
                            style: AppTypography.caption,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Novo endereço', style: AppTypography.h3),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _cep,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                        decoration: const InputDecoration(labelText: 'CEP'),
                        validator: (String? v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length == 8 ? null : 'CEP com 8 dígitos',
                        onChanged: (_) => setState(() {
                          _quote = null;
                          _optionId = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 50,
                      child: PrimeButton(
                        label: 'Consultar',
                        expanded: false,
                        variant: PrimeButtonVariant.secondary,
                        loading: _quoting,
                        onPressed: _requestQuote,
                      ),
                    ),
                  ],
                ),
                if (_quote != null && _quote!.options.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('Opção de entrega', style: AppTypography.smallBold),
                  for (final AddressQuoteOption o in _quote!.options)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: o.id,
                      groupValue: _optionId,
                      onChanged: (String? v) => setState(() => _optionId = v),
                      title: Text('${o.method} · ${o.carrier}', style: AppTypography.bodyBold),
                      subtitle: Text(
                        'Até ${o.estimateDays} dias úteis · frete grátis para assinantes'
                        '${o.price.amount > 0 ? ' (valor de referência ${Fmt.money(o.price)})' : ''}',
                        style: AppTypography.small,
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                TextFormField(controller: _recipient, decoration: const InputDecoration(labelText: 'Destinatário'), validator: _required),
                const SizedBox(height: 12),
                TextFormField(controller: _street, decoration: const InputDecoration(labelText: 'Rua / Avenida'), validator: _required),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(controller: _number, decoration: const InputDecoration(labelText: 'Número'), validator: _required),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(controller: _complement, decoration: const InputDecoration(labelText: 'Complemento (opcional)')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _neighborhood, decoration: const InputDecoration(labelText: 'Bairro'), validator: _required),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'Cidade'), validator: _required),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _state,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(2)],
                        decoration: const InputDecoration(labelText: 'UF'),
                        validator: (String? v) => (v ?? '').trim().length == 2 ? null : 'UF',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimeButton(label: 'Salvar endereço', onPressed: _save),
                const SizedBox(height: 8),
                Text(
                  'A troca vale para a próxima caixa. Pedidos já em preparo seguem para o endereço anterior.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
