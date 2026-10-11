import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/common.dart';
import '../../api/models/device.dart';
import '../../api/models/routine.dart';
import '../../core/notifications/local_notifications.dart';
import '../../core/push/push_provider.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/consents_controller.dart';
import '../../data/providers.dart';

/// Preferências de notificação (PATCH /me/notification-preferences), incluindo
/// lembretes da rotina (locais). Ativar push pede o consentimento `push`.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _update(BuildContext context, WidgetRef ref, NotificationPreferences current, String key, bool value) async {
    try {
      // Push exige consentimento `push`; ao ligar qualquer canal remoto, garante o consentimento e registra o token.
      if (key != 'routine' && value && !ref.read(consentGrantedProvider(ConsentKind.push))) {
        await ref.read(consentsControllerProvider).setConsent(ConsentKind.push, true);
        // ignore: unawaited_futures
        ref.read(pushRegistrarProvider).registerCurrentToken();
      }
      await ref.read(accountApiProvider).updateNotificationPreferences(<String, dynamic>{key: value});
      ref.invalidate(notificationPrefsProvider);
      if (key == 'routine') {
        final LocalNotifications local = ref.read(localNotificationsProvider);
        if (value) {
          final bool granted = await local.requestPermission();
          if (granted) {
            final RoutinePlan plan = await ref.read(routinePlanProvider.future);
            await local.scheduleRoutine(plan);
          } else if (context.mounted) {
            showErrorToast(context, 'Permita notificações nas configurações do aparelho.', title: 'Sem permissão');
          }
        } else {
          await local.cancelAll();
        }
      }
    } catch (e) {
      if (context.mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<NotificationPreferences> prefs = ref.watch(notificationPrefsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: prefs.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(notificationPrefsProvider)),
        data: (NotificationPreferences p) => ListView(
          padding: const EdgeInsets.all(AppDims.pageMargin),
          children: <Widget>[
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _tile('Cobrança', 'Fatura paga, pendente e PIX', p.billing, (bool v) => _update(context, ref, p, 'billing', v)),
                  const Divider(height: 1),
                  _tile('Envio', 'Pronto para envio, em trânsito, entregue', p.shipping, (bool v) => _update(context, ref, p, 'shipping', v)),
                  const Divider(height: 1),
                  _tile('Renovação', 'Lembrete antes da cobrança e da janela de edição', p.renewal, (bool v) => _update(context, ref, p, 'renewal', v)),
                  const Divider(height: 1),
                  _tile('Novidades e ofertas', 'Campanhas, brindes e sabores novos', p.marketing, (bool v) => _update(context, ref, p, 'marketing', v)),
                ],
              ),
            ),
            const SizedBox(height: AppDims.sectionGap),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: _tile(
                'Lembretes da rotina',
                'Notificações locais nos horários dos seus itens (sem passar pelo servidor)',
                p.routine ?? false,
                (bool v) => _update(context, ref, p, 'routine', v),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Push depende do Firebase configurado no app. Os lembretes da rotina funcionam mesmo sem push.',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: AppTypography.bodyBold),
      subtitle: Text(subtitle, style: AppTypography.small),
      value: value,
      onChanged: onChanged,
    );
  }
}
