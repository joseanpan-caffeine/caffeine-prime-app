import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/auth.dart';
import '../../core/env.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/auth_controller.dart';
import '../../router.dart';

/// Pede o link mágico por e-mail. Em FAKE_AUTH o BFF devolve `debugToken`,
/// exibido aqui com um botão para entrar direto.
class MagicLinkScreen extends ConsumerStatefulWidget {
  const MagicLinkScreen({super.key});

  @override
  ConsumerState<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends ConsumerState<MagicLinkScreen> {
  final TextEditingController _email = TextEditingController();
  MagicLinkSent? _sent;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showErrorToast(context, 'Informe um e-mail válido', title: 'E-mail inválido');
      return;
    }
    try {
      final MagicLinkSent sent = await ref.read(authControllerProvider).requestMagicLink(email);
      if (mounted) setState(() => _sent = sent);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MagicLinkSent? sent = _sent;
    return Scaffold(
      appBar: AppBar(title: const Text('Link de acesso')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text('Entrar sem senha', style: AppTypography.h1),
          const SizedBox(height: 4),
          Text(
            'Enviamos um link para o seu e-mail. Ao abrir no celular, você entra automaticamente.',
            style: AppTypography.body,
          ),
          const SizedBox(height: 24),
          if (sent == null) ...<Widget>[
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'E-mail'),
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 20),
            PrimeButton(label: 'Enviar link', onPressed: _send),
          ] else ...<Widget>[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 32),
                  const SizedBox(height: 8),
                  Text('Link enviado', style: AppTypography.h3),
                  Text('Confira a caixa de entrada de ${_email.text.trim()}.', style: AppTypography.body),
                  if (sent.debugToken != null) ...<Widget>[
                    const Divider(height: 24),
                    Text('Modo de teste · debugToken', style: AppTypography.smallBold.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    SelectableText(sent.debugToken!, style: AppTypography.caption),
                    const SizedBox(height: 12),
                    PrimeButton(
                      label: 'Entrar com este token',
                      onPressed: () async => context.go(Routes.magicExchangeOf(sent.debugToken!)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => setState(() => _sent = null), child: const Text('Enviar de novo')),
          ],
          if (Env.fakeAuth && sent == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Em FAKE_AUTH o BFF devolve o token aqui mesmo, sem enviar e-mail.',
                style: AppTypography.caption,
              ),
            ),
        ],
      ),
    );
  }
}

/// Troca o token do link mágico (`caffeineprime://auth/magic/:token`) por sessão.
class MagicLinkExchangeScreen extends ConsumerStatefulWidget {
  const MagicLinkExchangeScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<MagicLinkExchangeScreen> createState() => _MagicLinkExchangeScreenState();
}

class _MagicLinkExchangeScreenState extends ConsumerState<MagicLinkExchangeScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _exchange());
  }

  Future<void> _exchange() async {
    setState(() => _error = null);
    try {
      await ref.read(authControllerProvider).exchangeMagicLink(Uri.decodeComponent(widget.token));
      if (mounted) context.go(Routes.home);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrando…')),
      body: _error == null
          ? const LoadingView(message: 'Validando seu link de acesso')
          : Column(
              children: <Widget>[
                Expanded(child: ErrorView(error: _error!, onRetry: _exchange)),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: PrimeButton(
                    label: 'Pedir um novo link',
                    variant: PrimeButtonVariant.secondary,
                    onPressed: () async => context.go(Routes.magic),
                  ),
                ),
              ],
            ),
    );
  }
}
