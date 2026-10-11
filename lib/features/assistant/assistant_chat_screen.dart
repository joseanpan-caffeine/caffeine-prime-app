import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_error.dart';
import '../../api/models/assistant.dart';
import '../../api/models/common.dart';
import '../../core/analytics.dart';
import '../../core/deep_links.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';

/// Conversa com o assistente: respostas em markdown, aviso (disclaimer) na
/// primeira resposta, chips de ação (deep links) e mensagem de limite (429).
class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key, this.threadId});

  /// null ou 'new' = nova conversa.
  final String? threadId;

  @override
  ConsumerState<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<AssistantMessage> _messages = <AssistantMessage>[];
  final Map<String, List<AssistantAction>> _actions = <String, List<AssistantAction>>{};
  String? _threadId;
  String? _disclaimer;
  bool _loading = false;
  bool _sending = false;
  bool _limitReached = false;
  Object? _error;
  bool _initialSent = false;

  bool get _isNew => widget.threadId == null || widget.threadId == 'new';

  @override
  void initState() {
    super.initState();
    if (!_isNew) {
      _threadId = widget.threadId;
      _loadThread();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialSent && _isNew) {
        _initialSent = true;
        final String? q = GoRouterState.of(context).uri.queryParameters['q'];
        if (q != null && q.isNotEmpty) _send(q);
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AssistantThread t = await ref.read(assistantApiProvider).thread(_threadId!);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(t.messages);
      });
      _scrollToEnd();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final String msg = text.trim();
    if (msg.isEmpty || _sending || _limitReached) return;
    _input.clear();
    final String tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _sending = true;
      _messages.add(AssistantMessage(id: tempId, role: AssistantRole.user, content: msg, createdAt: DateTime.now().toIso8601String()));
    });
    _scrollToEnd();
    try {
      final AssistantSendResponse res = await ref.read(assistantApiProvider).send(
            AssistantSendRequest(threadId: _threadId, message: msg, screen: 'assistant'),
          );
      ref.read(analyticsProvider).track(AnalyticsEvents.assistantSend, params: <String, Object?>{'thread': res.threadId});
      if (!mounted) return;
      setState(() {
        final bool firstReply = _threadId == null || _messages.where((m) => !m.isUser).isEmpty;
        _threadId = res.threadId;
        _messages.add(res.reply);
        if (res.actions != null && res.actions!.isNotEmpty) _actions[res.reply.id] = res.actions!;
        if (firstReply) _disclaimer = res.disclaimer ?? ref.read(assistantConfigProvider).valueOrNull?.disclaimer;
      });
      ref.invalidate(assistantThreadsProvider);
      _scrollToEnd();
    } catch (e) {
      final ApiError err = ApiError.from(e);
      if (!mounted) return;
      if (err.isRateLimited) {
        setState(() => _limitReached = true);
      } else {
        showErrorToast(context, err, title: 'Não foi possível enviar');
      }
      // Mantém a mensagem do usuário na tela para reenviar.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openAction(AssistantAction a) async {
    final String? route = DeepLinks.routeForString(a.deepLink);
    if (route != null) {
      context.push(route);
      return;
    }
    final Uri? u = Uri.tryParse(a.deepLink);
    if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final AssistantConfig? config = ref.watch(assistantConfigProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Prime IA')),
      body: Column(
        children: <Widget>[
          if (_disclaimer != null && _disclaimer!.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppColors.warningSoft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warningText),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_disclaimer!, style: AppTypography.caption.copyWith(color: AppColors.warningText))),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(error: _error!, onRetry: _loadThread)
                    : _messages.isEmpty
                        ? _EmptyChat(prompts: config?.suggestedPrompts ?? const <String>[], onPick: _send)
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length + (_sending ? 1 : 0),
                            itemBuilder: (BuildContext context, int i) {
                              if (i == _messages.length) return const _TypingBubble();
                              final AssistantMessage m = _messages[i];
                              return _MessageBubble(message: m, actions: _actions[m.id], onAction: _openAction);
                            },
                          ),
          ),
          if (_limitReached)
            Container(
              width: double.infinity,
              color: AppColors.infoSoft,
              padding: const EdgeInsets.all(12),
              child: Text(
                'Você atingiu o limite diário de ${config?.dailyMessageLimit ?? ''} mensagens. Volte amanhã!',
                style: AppTypography.small.copyWith(color: AppColors.info),
                textAlign: TextAlign.center,
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.bgSurface,
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_limitReached,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(hintText: 'Pergunte sobre sua caixa ou rotina…'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.brandDark, foregroundColor: AppColors.brandPrimary),
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary))
                        : const Icon(Icons.send_rounded),
                    onPressed: _sending || _limitReached ? null : () => _send(_input.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.prompts, required this.onPick});

  final List<String> prompts;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Icon(Icons.auto_awesome_rounded, color: AppColors.brandGold, size: 36),
        const SizedBox(height: 8),
        Text('Pergunte qualquer coisa sobre sua caixa', style: AppTypography.h3, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        for (final String p in prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(onPressed: () => onPick(p), child: Text(p, textAlign: TextAlign.center)),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.actions, required this.onAction});

  final AssistantMessage message;
  final List<AssistantAction>? actions;
  final ValueChanged<AssistantAction> onAction;

  @override
  Widget build(BuildContext context) {
    final bool user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: user ? AppColors.brandDark : AppColors.bgSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(user ? 14 : 4),
            bottomRight: Radius.circular(user ? 4 : 14),
          ),
          boxShadow: AppDims.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (user)
              Text(message.content, style: AppTypography.body.copyWith(color: Colors.white))
            else
              MarkdownBody(
                data: message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.body,
                  strong: AppTypography.bodyBold,
                  listBullet: AppTypography.body,
                  h1: AppTypography.h2,
                  h2: AppTypography.h3,
                  h3: AppTypography.bodyBold,
                  code: AppTypography.small.copyWith(fontFamily: 'monospace', backgroundColor: AppColors.bgSubtle),
                ),
                onTapLink: (String text, String? href, String title) async {
                  if (href == null) return;
                  final Uri? u = Uri.tryParse(href);
                  if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
                },
              ),
            if (actions != null && actions!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: actions!
                    .map((AssistantAction a) => ActionChip(
                          label: Text(a.label),
                          avatar: const Icon(Icons.arrow_outward_rounded, size: 14),
                          onPressed: () => onAction(a),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(14), boxShadow: AppDims.cardShadow),
        child: const SizedBox(width: 40, child: LinearProgressIndicator(minHeight: 3)),
      ),
    );
  }
}
