import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/auth_controller.dart';
import '../../router.dart';
import 'fake_account_picker.dart';

/// Boas-vindas: entrar com e-mail, Google, Apple ou link mágico; criar conta.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _social(BuildContext context, WidgetRef ref, {required bool apple}) async {
    try {
      String? fakeEmail;
      if (Env.fakeAuth) {
        fakeEmail = await pickFakeAccount(context);
        if (fakeEmail == null) return;
      }
      if (apple) {
        await ref.read(authControllerProvider).loginWithApple(fakeEmail: fakeEmail);
      } else {
        await ref.read(authControllerProvider).loginWithGoogle(fakeEmail: fakeEmail);
      }
    } catch (e) {
      if (context.mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Spacer(),
              const PrimeLogo(height: 32, onDark: true),
              const SizedBox(height: 20),
              Text(
                'Sua assinatura, sua rotina.\nTudo em um só lugar.',
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Edite sua caixa, acompanhe entregas, pontos e benefícios.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.brandPrimary),
              ),
              const Spacer(),
              PrimeButton(
                label: 'Entrar com e-mail',
                icon: Icons.mail_outline_rounded,
                onPressed: () async => context.push(Routes.login),
              ),
              const SizedBox(height: 10),
              PrimeButton(
                label: 'Entrar com Google',
                icon: Icons.g_mobiledata_rounded,
                variant: PrimeButtonVariant.secondary,
                onPressed: () => _social(context, ref, apple: false),
              ),
              if (Env.isIOS || Env.fakeAuth) ...<Widget>[
                const SizedBox(height: 10),
                PrimeButton(
                  label: 'Entrar com Apple',
                  icon: Icons.apple_rounded,
                  variant: PrimeButtonVariant.secondary,
                  onPressed: () => _social(context, ref, apple: true),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.push(Routes.magic),
                child: Text('Receber link de acesso por e-mail', style: AppTypography.bodyBold.copyWith(color: Colors.white)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => context.push(Routes.register),
                child: Text(
                  'Ainda não tem conta? Criar conta',
                  style: AppTypography.small.copyWith(color: AppColors.brandPrimary),
                ),
              ),
              if (Env.fakeAuth)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Modo de teste (FAKE_AUTH) · ${Env.apiUrl}',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
