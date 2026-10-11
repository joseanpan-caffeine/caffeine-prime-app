import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../api/models/payment.dart';
import '../../core/card_brands.dart';
import '../../core/env.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';

/// Resultado da tokenização: token do gateway + bandeira detectada.
class TokenizedCard {
  const TokenizedCard({required this.gatewayToken, this.paymentCompanyCode, required this.lastFour, this.brand});

  final String gatewayToken;
  final String? paymentCompanyCode;
  final String lastFour;
  final String? brand;
}

/// Formulário de cartão novo. Tokeniza na Vindi (GET /payments/vindi-config) e
/// devolve o `gatewayToken` via [onTokenized]. Em FAKE_AUTH → "fake-token-<4>".
class NewCardForm extends ConsumerStatefulWidget {
  const NewCardForm({super.key, required this.onTokenized, this.submitLabel = 'Salvar cartão', this.showDefaultSwitch = false});

  final Future<void> Function(TokenizedCard card, bool setAsDefault) onTokenized;
  final String submitLabel;
  final bool showDefaultSwitch;

  @override
  ConsumerState<NewCardForm> createState() => _NewCardFormState();
}

class _NewCardFormState extends ConsumerState<NewCardForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _holder = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _expiry = TextEditingController();
  final TextEditingController _cvv = TextEditingController();
  bool _setDefault = true;
  String? _brand;

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final List<String> exp = _expiry.text.split('/');
    final NewCardInput input = NewCardInput(
      holderName: _holder.text.trim(),
      number: _number.text,
      expirationMonth: exp[0].trim(),
      expirationYear: exp[1].trim(),
      cvv: _cvv.text.trim(),
      paymentCompanyCode: CardBrands.vindiCompanyCode(_brand),
    );
    try {
      final VindiConfig config = await ref.read(vindiConfigProvider.future);
      final String token = await ref.read(vindiTokenizerProvider).tokenize(config, input);
      await widget.onTokenized(
        TokenizedCard(
          gatewayToken: token,
          paymentCompanyCode: input.paymentCompanyCode,
          lastFour: input.lastFour,
          brand: _brand,
        ),
        _setDefault,
      );
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Cartão não aceito');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? logo = CardBrands.forBrand(_brand);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _number,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19), _CardNumberFormatter()],
            decoration: InputDecoration(
              labelText: 'Número do cartão',
              suffixIcon: logo == null
                  ? const Icon(Icons.credit_card_outlined)
                  : Padding(padding: const EdgeInsets.all(10), child: SvgPicture.asset(logo, width: 32)),
            ),
            onChanged: (String v) => setState(() => _brand = CardBrands.detectFromNumber(v)),
            validator: (String? v) {
              final String d = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (d.length < 13 || d.length > 19) return 'Número inválido';
              if (!_luhn(d)) return 'Confira o número do cartão';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _holder,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Nome impresso no cartão'),
            validator: (String? v) => (v ?? '').trim().length < 3 ? 'Informe o nome como está no cartão' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _expiry,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), _ExpiryFormatter()],
                  decoration: const InputDecoration(labelText: 'Validade (MM/AA)'),
                  validator: (String? v) {
                    final List<String> p = (v ?? '').split('/');
                    if (p.length != 2) return 'MM/AA';
                    final int? m = int.tryParse(p[0]);
                    final int? y = int.tryParse(p[1]);
                    if (m == null || y == null || m < 1 || m > 12) return 'Validade inválida';
                    final DateTime now = DateTime.now();
                    final int fullYear = 2000 + y;
                    if (fullYear < now.year || (fullYear == now.year && m < now.month)) return 'Cartão vencido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvv,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  decoration: const InputDecoration(labelText: 'CVV'),
                  validator: (String? v) => ((v ?? '').length < 3) ? 'CVV inválido' : null,
                ),
              ),
            ],
          ),
          if (widget.showDefaultSwitch)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Usar como cartão principal', style: AppTypography.body),
              value: _setDefault,
              onChanged: (bool v) => setState(() => _setDefault = v),
            ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  Env.fakeAuth
                      ? 'Modo de teste: nenhum dado vai para a Vindi (token fake).'
                      : 'Os dados do cartão vão direto para a Vindi (gateway). O Prime recebe só um token.',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimeButton(label: widget.submitLabel, onPressed: _submit),
        ],
      ),
    );
  }

  static bool _luhn(String digits) {
    int sum = 0;
    bool alt = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) out.write(' ');
      out.write(digits[i]);
    }
    final String text = out.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String text = digits;
    if (digits.length > 2) text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
