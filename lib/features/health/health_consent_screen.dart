import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/common.dart';
import '../../api/models/config.dart';
import '../../core/env.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import 'health_controller.dart';

/// Tela de consentimento `health_data`, exibida ANTES de qualquer pedido de
/// permissão ao sistema. Texto claro sobre o que é lido e para quê.
class HealthConsentScreen extends ConsumerStatefulWidget {
  const HealthConsentScreen({super.key});

  @override
  ConsumerState<HealthConsentScreen> createState() => _HealthConsentScreenState();
}

class _HealthConsentScreenState extends ConsumerState<HealthConsentScreen> {
  bool _agree = false;

  Future<void> _connect() async {
    try {
      await ref.read(healthControllerProvider).connect();
      if (!mounted) return;
      showSuccessToast(context, 'Saúde conectada', body: 'Sincronizamos os últimos 7 dias.');
      context.pop();
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível conectar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppConfig config = ref.watch(appConfigValueProvider);
    final String providerName = Env.isIOS ? 'Apple Health' : 'Health Connect';
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar saúde')),
      body: ListView(
        padding: const EdgeInsets.all(AppDims.pageMargin),
        children: <Widget>[
          const Icon(Icons.favorite_rounded, color: AppColors.brandGold, size: 44),
          const SizedBox(height: 12),
          Text('Conecte seu relógio ou app de exercício', style: AppTypography.h1, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Com os dados do $providerName, o Prime sugere o melhor momento para cada produto da sua caixa — '
            'por exemplo, Morning Shot antes do treino nos dias em que você treina.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('O que lemos (só leitura)', style: AppTypography.h3),
                const SizedBox(height: 8),
                _line(Icons.directions_walk_rounded, 'Passos por dia'),
                _line(Icons.local_fire_department_outlined, 'Energia e minutos ativos por dia'),
                _line(Icons.fitness_center_rounded, 'Quantidade e duração de treinos por dia'),
                _line(Icons.bedtime_outlined, 'Minutos de sono por noite'),
                const Divider(height: 24),
                Text('Como usamos', style: AppTypography.h3),
                const SizedBox(height: 8),
                _line(Icons.calendar_view_week_rounded, 'Só totais por dia dos últimos 7 dias — nunca séries brutas nem localização'),
                _line(Icons.lightbulb_outline_rounded, 'Sugestões simples de rotina baseadas em regras, dentro do app'),
                _line(Icons.lock_outline_rounded, 'Nada é vendido ou compartilhado com parceiros; não entra em marketing'),
                _line(Icons.undo_rounded, 'Você pode desconectar quando quiser em Perfil › Consentimentos'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agree,
            onChanged: (bool? v) => setState(() => _agree = v ?? false),
            title: Text(
              'Autorizo o Caffeine Army Prime a ler esses dados do $providerName e a guardar os totais diários na minha conta '
              '(termo versão ${config.consentVersion(ConsentKind.healthData)}).',
              style: AppTypography.small,
            ),
          ),
          const SizedBox(height: 8),
          PrimeButton(label: 'Aceitar e conectar', onPressed: _agree ? _connect : null),
          const SizedBox(height: 8),
          if (config.links.healthPrivacy != null)
            TextButton(
              onPressed: () async {
                final Uri? u = Uri.tryParse(config.links.healthPrivacy!);
                if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
              },
              child: const Text('Política de privacidade de dados de saúde'),
            ),
          Text(
            'Na próxima tela, o sistema pedirá a permissão de leitura. Sem ela, nada é lido.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.brandGold),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.small)),
        ],
      ),
    );
  }
}
