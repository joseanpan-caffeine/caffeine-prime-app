import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/config.dart';
import '../../api/models/profile.dart';
import '../../core/analytics.dart';
import '../../core/env.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/section_list.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/auth_controller.dart';
import '../../data/providers.dart';
import '../../router.dart';

/// Perfil: dados, cartões, endereço, notificações, consentimentos, saúde,
/// links legais, excluir conta e sair.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserProfile? user = ref.watch(currentUserProvider);
    final AppConfig config = ref.watch(appConfigValueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppDims.pageMargin),
        children: <Widget>[
          SurfaceCard(
            color: AppColors.brandDark,
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.brandPrimary,
                  child: Text(
                    (user?.firstName.isNotEmpty ?? false) ? user!.firstName[0].toUpperCase() : '?',
                    style: AppTypography.h2.copyWith(color: AppColors.brandDark),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(user?.fullName ?? '—', style: AppTypography.h3.copyWith(color: Colors.white)),
                      Text(user?.email ?? '', style: AppTypography.small.copyWith(color: AppColors.brandPrimary)),
                      if (user != null)
                        Text('Cliente #${user.id}', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDims.sectionGap),
          const SectionTitle(title: 'Minha conta'),
          SectionListCard(
            children: <Widget>[
              SectionRow(icon: Icons.person_outline_rounded, title: 'Meus dados', subtitle: 'Nome, telefone, CPF', onTap: () => context.push(Routes.profileData)),
              SectionRow(icon: Icons.credit_card_outlined, title: 'Cartões', onTap: () => context.push(Routes.cards)),
              SectionRow(icon: Icons.location_on_outlined, title: 'Endereço de entrega', onTap: () => context.push(Routes.address)),
              SectionRow(icon: Icons.receipt_long_outlined, title: 'Pedidos e faturas', onTap: () => context.push(Routes.orders)),
            ],
          ),
          const SizedBox(height: AppDims.sectionGap),
          const SectionTitle(title: 'Preferências e privacidade'),
          SectionListCard(
            children: <Widget>[
              SectionRow(
                icon: Icons.notifications_outlined,
                title: 'Notificações',
                subtitle: 'Cobrança, envio, renovação, novidades e rotina',
                onTap: () => context.push(Routes.notifications),
              ),
              SectionRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Consentimentos (LGPD)',
                subtitle: 'Push, saúde, rotina, assistente, análise de uso',
                onTap: () => context.push(Routes.consents),
              ),
              if (config.feature('health'))
                SectionRow(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Saúde e wearables',
                  subtitle: 'Apple Health / Health Connect',
                  onTap: () => context.push(Routes.health),
                ),
            ],
          ),
          const SizedBox(height: AppDims.sectionGap),
          const SectionTitle(title: 'Sobre'),
          SectionListCard(
            children: <Widget>[
              SectionRow(icon: Icons.description_outlined, title: 'Termos de serviço', onTap: () => _open(config.links.terms)),
              SectionRow(icon: Icons.shield_outlined, title: 'Política de privacidade', onTap: () => _open(config.links.privacy)),
              if (config.links.healthPrivacy != null)
                SectionRow(icon: Icons.health_and_safety_outlined, title: 'Privacidade de dados de saúde', onTap: () => _open(config.links.healthPrivacy!)),
              SectionRow(icon: Icons.support_agent_outlined, title: 'Fale conosco', onTap: () => _open(config.links.support)),
              const _VersionRow(),
            ],
          ),
          const SizedBox(height: AppDims.sectionGap),
          SectionListCard(
            children: <Widget>[
              SectionRow(
                icon: Icons.logout_rounded,
                title: 'Sair da conta',
                onTap: () async {
                  final bool? ok = await _confirm(context, 'Sair da conta?', 'Seus lembretes locais serão cancelados neste aparelho.', 'Sair');
                  if (ok == true) await ref.read(authControllerProvider).logout();
                },
              ),
              SectionRow(
                icon: Icons.delete_forever_outlined,
                title: 'Excluir minha conta',
                subtitle: 'Pedido de exclusão de dados (LGPD)',
                danger: true,
                onTap: () => _requestDeletion(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Ambiente: ${Env.apiUrl}${Env.fakeAuth ? ' · FAKE_AUTH' : ''}',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Future<bool?> _confirm(BuildContext context, String title, String body, String action) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(action)),
        ],
      ),
    );
  }

  static Future<void> _requestDeletion(BuildContext context, WidgetRef ref) async {
    final TextEditingController reason = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Vamos registrar seu pedido de exclusão de dados. Se houver assinatura ativa, ela precisa ser cancelada antes. '
              'O atendimento confirma por e-mail.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 12),
            TextField(controller: reason, decoration: const InputDecoration(labelText: 'Motivo (opcional)')),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Pedir exclusão', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(accountApiProvider).requestDeletion(reason: reason.text.trim().isEmpty ? null : reason.text.trim());
      ref.read(analyticsProvider).track(AnalyticsEvents.deleteAccountRequest);
      if (context.mounted) showSuccessToast(context, 'Pedido registrado', body: 'Você receberá a confirmação por e-mail.');
    } catch (e) {
      if (context.mounted) showErrorToast(context, e);
    } finally {
      reason.dispose();
    }
  }

  static Future<void> _open(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (BuildContext context, AsyncSnapshot<PackageInfo> snap) {
        final String v = snap.hasData ? '${snap.data!.version} (${snap.data!.buildNumber})' : '—';
        return SectionRow(icon: Icons.info_outline_rounded, title: 'Versão do app', subtitle: v);
      },
    );
  }
}

/// Botão de login usado em outras telas quando não há sessão (não usado no shell).
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimeButton(label: 'Entrar', onPressed: () async => context.go(Routes.welcome));
  }
}
