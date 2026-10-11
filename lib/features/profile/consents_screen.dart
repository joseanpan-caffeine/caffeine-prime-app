import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/common.dart';
import '../../api/models/config.dart';
import '../../api/models/device.dart';
import '../../core/formatting.dart';
import '../../core/notifications/local_notifications.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/consents_controller.dart';
import '../../data/providers.dart';
import '../health/health_controller.dart';

/// Consentimentos LGPD (GET/PUT /me/consents). Revogar `health_data` também
/// desconecta a saúde; revogar `routine_data` cancela os lembretes locais.
class ConsentsScreen extends ConsumerWidget {
  const ConsentsScreen({super.key});

  static const List<ConsentKind> _kinds = <ConsentKind>[
    ConsentKind.push,
    ConsentKind.routineData,
    ConsentKind.healthData,
    ConsentKind.aiAssistant,
    ConsentKind.analytics,
  ];

  Future<void> _toggle(BuildContext context, WidgetRef ref, ConsentKind kind, bool value) async {
    try {
      if (!value) {
        final bool? ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: Text('Revogar "${kind.label}"?'),
            content: Text(_revokeText(kind)),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Manter')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Revogar')),
            ],
          ),
        );
        if (ok != true) return;
      }
      if (kind == ConsentKind.healthData && !value) {
        await ref.read(healthControllerProvider).disconnect();
        return; // disconnect já revoga o consentimento
      }
      await ref.read(consentsControllerProvider).setConsent(kind, value);
      if (kind == ConsentKind.routineData && !value) {
        await ref.read(localNotificationsProvider).cancelAll();
      }
    } catch (e) {
      if (context.mounted) showErrorToast(context, e);
    }
  }

  static String _revokeText(ConsentKind kind) {
    switch (kind) {
      case ConsentKind.healthData:
        return 'Paramos de ler dados do Apple Health / Health Connect e de enviá-los. Os agregados já enviados podem ser apagados pelo atendimento.';
      case ConsentKind.routineData:
        return 'Seus lembretes locais serão cancelados e a aba Rotina deixa de registrar check-ins.';
      case ConsentKind.aiAssistant:
        return 'O assistente Prime IA fica indisponível até você consentir de novo.';
      case ConsentKind.push:
        return 'Você deixa de receber notificações push neste aparelho.';
      case ConsentKind.analytics:
        return 'Paramos de registrar eventos de uso ligados ao seu id de cliente.';
      case ConsentKind.unknown:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Consent>> consents = ref.watch(consentsProvider);
    final AppConfig config = ref.watch(appConfigValueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e consentimentos')),
      body: consents.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(consentsProvider)),
        data: (List<Consent> list) {
          Consent? find(ConsentKind k) {
            for (final Consent c in list) {
              if (c.kind == k) return c;
            }
            return null;
          }

          return ListView(
            padding: const EdgeInsets.all(AppDims.pageMargin),
            children: <Widget>[
              Text(
                'Você controla o que o app pode usar. Cada item pode ser ligado ou desligado a qualquer momento; '
                'o Prime guarda a versão do termo aceito e a data.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < _kinds.length; i++) ...<Widget>[
                      _ConsentTile(
                        kind: _kinds[i],
                        consent: find(_kinds[i]),
                        version: config.consentVersion(_kinds[i]),
                        onChanged: (bool v) => _toggle(context, ref, _kinds[i], v),
                      ),
                      if (i < _kinds.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Ler a política de privacidade'),
                onPressed: () async {
                  final Uri? u = Uri.tryParse(config.links.privacy);
                  if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({required this.kind, required this.consent, required this.version, required this.onChanged});

  final ConsentKind kind;
  final Consent? consent;
  final String version;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool granted = consent?.granted ?? false;
    final bool outdated = consent != null && consent!.granted && consent!.version != version;
    return SwitchListTile(
      value: granted,
      onChanged: onChanged,
      title: Text(kind.label, style: AppTypography.bodyBold),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(kind.description, style: AppTypography.small),
          if (consent?.grantedAt != null && granted)
            Text('Aceito em ${Fmt.date(consent!.grantedAt)} · versão ${consent!.version}', style: AppTypography.caption),
          if (outdated)
            Text('Há uma nova versão do termo ($version). Desligue e ligue para aceitar.', style: AppTypography.caption.copyWith(color: AppColors.warningText)),
        ],
      ),
    );
  }
}
