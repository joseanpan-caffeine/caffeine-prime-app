import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/assistant.dart';
import '../../api/models/common.dart';
import '../../core/analytics.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/consents_controller.dart';
import '../../data/providers.dart';
import '../../router.dart';

/// Aba Prime IA: gate de consentimento `ai_assistant`, lista de conversas,
/// nova conversa e prompts sugeridos (GET /assistant/config).
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(analyticsProvider).screen('assistant'));
  }

  @override
  Widget build(BuildContext context) {
    final bool consent = ref.watch(consentGrantedProvider(ConsentKind.aiAssistant));
    final AsyncValue<AssistantConfig> config = ref.watch(assistantConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Prime IA')),
      body: config.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(assistantConfigProvider)),
        data: (AssistantConfig c) {
          if (!c.enabled) {
            return const EmptyView(
              icon: Icons.auto_awesome_outlined,
              title: 'Prime IA em breve',
              body: 'O assistente ainda não está disponível para a sua conta.',
            );
          }
          if (!consent) return _ConsentGate(config: c);
          return _ThreadsView(config: c);
        },
      ),
    );
  }
}

class _ConsentGate extends ConsumerWidget {
  const _ConsentGate({required this.config});

  final AssistantConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Icon(Icons.auto_awesome_rounded, color: AppColors.brandGold, size: 44),
        const SizedBox(height: 12),
        Text('Conheça a Prime IA', style: AppTypography.h1, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Tire dúvidas sobre os produtos da sua caixa, como e quando tomar, e peça sugestões de rotina. '
          'O assistente conhece sua caixa, seu plano e sua rotina para responder melhor.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Consentimento "Assistente de IA"', style: AppTypography.h3),
              const SizedBox(height: 6),
              Text(
                '• Suas perguntas e o contexto da caixa/rotina são enviados ao assistente para gerar a resposta.\n'
                '• As conversas ficam na sua conta e podem ser apagadas por você.\n'
                '• O que as pessoas perguntam ajuda a melhorar o produto (sem identificação individual).\n'
                '• Limite de ${config.dailyMessageLimit} mensagens por dia.',
                style: AppTypography.small,
              ),
              if (config.disclaimer.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(config.disclaimer, style: AppTypography.caption.copyWith(color: AppColors.warningText)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimeButton(
          label: 'Aceitar e começar',
          onPressed: () async {
            try {
              await ref.read(consentsControllerProvider).setConsent(ConsentKind.aiAssistant, true);
            } catch (e) {
              if (context.mounted) showErrorToast(context, e);
            }
          },
        ),
      ],
    );
  }
}

class _ThreadsView extends ConsumerWidget {
  const _ThreadsView({required this.config});

  final AssistantConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AssistantThread>> threads = ref.watch(assistantThreadsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(assistantThreadsProvider);
        await ref.read(assistantThreadsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppDims.pageMargin),
        children: <Widget>[
          SurfaceCard(
            color: AppColors.brandDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.brandGold),
                    const SizedBox(width: 8),
                    Text('Como posso ajudar hoje?', style: AppTypography.h3.copyWith(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: config.suggestedPrompts
                      .map((String p) => ActionChip(
                            label: Text(p, style: AppTypography.caption.copyWith(color: AppColors.brandDark)),
                            backgroundColor: AppColors.brandPrimary,
                            side: BorderSide.none,
                            onPressed: () => context.push('${Routes.assistant}/new?q=${Uri.encodeQueryComponent(p)}'),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                PrimeButton(
                  label: 'Nova conversa',
                  icon: Icons.add_comment_outlined,
                  onPressed: () async => context.push('${Routes.assistant}/new'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDims.sectionGap),
          Text('Conversas', style: AppTypography.h3),
          const SizedBox(height: 8),
          threads.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (Object e, _) => ErrorView(error: e, compact: true, onRetry: () async => ref.invalidate(assistantThreadsProvider)),
            data: (List<AssistantThread> list) {
              if (list.isEmpty) {
                return Text('Nenhuma conversa ainda. Comece com uma sugestão acima.', style: AppTypography.small);
              }
              final List<AssistantThread> sorted = List<AssistantThread>.from(list)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              return Column(
                children: <Widget>[
                  for (final AssistantThread t in sorted) ...<Widget>[
                    SurfaceCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => context.push(Routes.assistantThreadOf(t.id)),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brandGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  t.title ?? (t.messages.isNotEmpty ? t.messages.first.content : 'Conversa'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyBold,
                                ),
                                Text('${t.messages.length} mensagens', style: AppTypography.caption),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Apagar',
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
                            onPressed: () async {
                              try {
                                await ref.read(assistantApiProvider).deleteThread(t.id);
                                ref.invalidate(assistantThreadsProvider);
                              } catch (e) {
                                if (context.mounted) showErrorToast(context, e);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
