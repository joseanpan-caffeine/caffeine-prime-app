import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/common.dart';
import '../../api/models/config.dart';
import '../../api/models/dashboard.dart';
import '../../api/models/subscription.dart';
import '../../core/analytics.dart';
import '../../core/deep_links.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/auth_controller.dart';
import '../../data/providers.dart';
import '../../data/subscription_actions.dart';
import '../../router.dart';
import 'widgets/alert_cards.dart';
import 'widgets/duo_cards.dart';
import 'widgets/exclusive_items.dart';
import 'widgets/home_sections.dart';
import 'widgets/next_boxes_carousel.dart';
import 'widgets/welcome_card.dart';

/// Dashboard (GET /me/dashboard), espelhando a coluna 1 do Figma.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(analyticsProvider).screen('home'));
  }

  Future<void> _refresh() async {
    refreshSubscriptionData(ref);
    ref.invalidate(catalogProvider);
    await ref.read(dashboardProvider.future);
  }

  Future<void> _logout() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Seus lembretes locais serão cancelados neste aparelho.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sair')),
        ],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider).logout();
  }

  Future<void> _resume() async {
    try {
      await ref.read(subscriptionActionsProvider).resume();
      if (mounted) showSuccessToast(context, 'Assinatura retomada', body: 'Sua próxima caixa volta ao calendário normal.');
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  Future<void> _reactivate() async {
    try {
      await ref.read(subscriptionActionsProvider).reactivate();
      if (mounted) showSuccessToast(context, 'Assinatura reativada', body: 'Bem-vindo de volta ao Prime!');
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider);
    final AppConfig config = ref.watch(appConfigValueProvider);
    final bool assistantOn = config.feature('assistant');

    return Scaffold(
      appBar: AppHeader(onProfile: () => context.go(Routes.profile)),
      body: dashboard.when(
        loading: () => const LoadingView(message: 'Carregando sua assinatura…'),
        error: (Object e, StackTrace st) => ErrorView(error: e, onRetry: _refresh),
        data: (Dashboard d) {
          final Subscription? s = d.subscription;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, AppDims.pageMargin, 0, 32),
              children: <Widget>[
                _pad(WelcomeCard(
                  dashboard: d,
                  onLogout: _logout,
                  onAssistant: assistantOn ? () => context.go(Routes.assistant) : null,
                )),
                const SizedBox(height: AppDims.sectionGap),
                _pad(HomeAlerts(dashboard: d, onResume: _resume, onReactivate: _reactivate)),
                if (s == null) ...<Widget>[
                  const SizedBox(height: AppDims.sectionGap),
                  _pad(_NoSubscriptionCard(config: config)),
                ],
                if (d.banners.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppDims.sectionGap),
                  _pad(_BannerStrip(banners: d.banners)),
                ],
                if (s != null && s.status != SubscriptionStatus.canceled) ...<Widget>[
                  const SizedBox(height: AppDims.sectionGap),
                  NextBoxesCarousel(dashboard: d),
                ],
                const SizedBox(height: AppDims.sectionGap),
                _pad(DuoCards(dashboard: d)),
                if (s != null && s.status == SubscriptionStatus.active) ...<Widget>[
                  const SizedBox(height: AppDims.sectionGap),
                  ExclusiveItemsCarousel(subscription: s, canEdit: d.capabilities.canEdit),
                ],
                const SizedBox(height: AppDims.sectionGap),
                _pad(HomeSections(dashboard: d, config: config)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: AppDims.pageMargin), child: child);
}

/// Cliente Shopify sem assinatura.
class _NoSubscriptionCard extends StatelessWidget {
  const _NoSubscriptionCard({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Você ainda não tem uma assinatura Prime', style: AppTypography.h3),
          const SizedBox(height: 6),
          Text(
            'Monte sua caixa com desconto, frete grátis, pontos no Caffeine Army X e brindes exclusivos.',
            style: AppTypography.body,
          ),
          const SizedBox(height: 12),
          PrimeButton(
            label: 'Conhecer o Prime',
            onPressed: () async => context.push(Routes.subscription),
          ),
        ],
      ),
    );
  }
}

/// Banners do dashboard (placeholder: imagem + título; deep link do BFF).
class _BannerStrip extends StatelessWidget {
  const _BannerStrip({required this.banners});

  final List<PromoBanner> banners;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: banners.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int i) {
          final PromoBanner b = banners[i];
          return SizedBox(
            width: 300,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              color: AppColors.brandDark,
              onTap: () {
                final String? route = DeepLinks.routeForString(b.deepLink);
                if (route != null) context.push(route);
              },
              child: Row(
                children: <Widget>[
                  if (b.imageUrl != null)
                    SizedBox(
                      width: 110,
                      height: 120,
                      child: CachedNetworkImage(
                        imageUrl: b.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.brandDark2),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodyBold.copyWith(color: Colors.white)),
                          if (b.subtitle != null)
                            Text(b.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.brandPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
