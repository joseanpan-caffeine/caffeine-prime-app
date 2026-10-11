import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/auth.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/auth_controller.dart';

/// Criação de conta (POST /auth/register).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _cpf = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_firstName, _lastName, _email, _password, _cpf, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_birthDate == null) {
      showErrorToast(context, 'Informe sua data de nascimento', title: 'Falta um dado');
      return;
    }
    try {
      await ref.read(authControllerProvider).register(
            RegisterRequest(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              cpf: _cpf.text.replaceAll(RegExp(r'\D'), ''),
              phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
              birthDate: _isoDate(_birthDate!),
            ),
          );
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível criar a conta');
    }
  }

  String? _required(String? v, [String msg = 'Campo obrigatório']) => (v ?? '').trim().isEmpty ? msg : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text('Seus dados', style: AppTypography.h1),
            const SizedBox(height: 4),
            Text('Usamos o mínimo necessário para identificar sua assinatura (LGPD).', style: AppTypography.body),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: _required,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Sobrenome'),
                    validator: _required,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (String? v) => (v ?? '').contains('@') ? null : 'Informe um e-mail válido',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha (mín. 8 caracteres)'),
              validator: (String? v) => (v ?? '').length >= 8 ? null : 'Use pelo menos 8 caracteres',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cpf,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'CPF (só números)'),
              validator: (String? v) =>
                  (v ?? '').replaceAll(RegExp(r'\D'), '').length == 11 ? null : 'CPF deve ter 11 dígitos',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Celular com DDD'),
              validator: (String? v) =>
                  (v ?? '').replaceAll(RegExp(r'\D'), '').length >= 10 ? null : 'Informe o celular com DDD',
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data de nascimento', suffixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text(
                  _birthDate == null
                      ? 'Selecionar'
                      : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                  style: AppTypography.body,
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimeButton(label: 'Criar conta', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
