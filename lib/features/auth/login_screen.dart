import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/auth_controller.dart';
import '../../router.dart';
import 'fake_account_picker.dart';

/// Login com e-mail e senha.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    try {
      await ref.read(authControllerProvider).loginWithEmail(_email.text, _password.text);
      // O redirect do router leva para a Home.
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível entrar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Text('Bem-vindo de volta', style: AppTypography.h1),
              const SizedBox(height: 4),
              Text('Use o mesmo e-mail e senha da loja Caffeine Army.', style: AppTypography.body),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (String? v) {
                  final String s = (v ?? '').trim();
                  if (s.isEmpty || !s.contains('@')) return 'Informe um e-mail válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (String? v) => (v ?? '').isEmpty ? 'Informe a senha' : null,
              ),
              const SizedBox(height: 20),
              PrimeButton(label: 'Entrar', onPressed: _submit),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push(Routes.magic),
                child: const Text('Esqueci a senha / receber link por e-mail'),
              ),
              if (Env.fakeAuth) ...<Widget>[
                const Divider(height: 32),
                Text('Contas de teste', style: AppTypography.smallBold.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                PrimeButton(
                  label: 'Escolher conta fake',
                  variant: PrimeButtonVariant.secondary,
                  icon: Icons.science_outlined,
                  onPressed: () async {
                    final String? email = await pickFakeAccount(context);
                    if (email == null) return;
                    _email.text = email;
                    _password.text = fakePassword;
                    await _submit();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
