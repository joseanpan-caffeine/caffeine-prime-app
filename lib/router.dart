import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'data/session_store.dart';
import 'features/address/address_screen.dart';
import 'features/assistant/assistant_chat_screen.dart';
import 'features/assistant/assistant_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/magic_link_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/box_editor/box_editor_screen.dart';
import 'features/cards/cards_screen.dart';
import 'features/cards/new_card_screen.dart';
import 'features/health/health_consent_screen.dart';
import 'features/health/health_screen.dart';
import 'features/home/home_screen.dart';
import 'features/orders/order_detail_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/pay/pay_screen.dart';
import 'features/profile/consents_screen.dart';
import 'features/profile/notifications_screen.dart';
import 'features/profile/profile_data_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/routine/routine_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/splash_screen.dart';
import 'features/subscription/cancel_screen.dart';
import 'features/subscription/pause_screen.dart';
import 'features/subscription/plan_screen.dart';
import 'features/subscription/subscription_status_screen.dart';

/// Rotas nomeadas (strings) para evitar erro de digitação nas telas.
class Routes {
  Routes._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String magic = '/magic';
  static const String magicExchange = '/auth/magic/:token';

  static const String home = '/home';
  static const String routine = '/routine';
  static const String assistant = '/assistant';
  static const String profile = '/profile';

  static const String box = '/box';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:billId';
  static const String pay = '/pay/:billId';
  static const String cards = '/cards';
  static const String newCard = '/cards/new';
  static const String address = '/address';
  static const String plan = '/plan';
  static const String pause = '/pause';
  static const String cancel = '/cancel';
  static const String subscription = '/subscription';
  static const String profileData = '/profile/data';
  static const String notifications = '/profile/notifications';
  static const String consents = '/consents';
  static const String health = '/health';
  static const String healthConsent = '/health/consent';
  static const String assistantThread = '/assistant/:threadId';

  static String orderDetailOf(String billId) => '/orders/$billId';
  static String payOf(String billId) => '/pay/$billId';
  static String assistantThreadOf(String threadId) => '/assistant/$threadId';
  static String magicExchangeOf(String token) => '/auth/magic/${Uri.encodeComponent(token)}';

  static const Set<String> _public = <String>{splash, welcome, login, register, magic};

  static bool isPublic(String location) {
    if (location.startsWith('/auth/magic/')) return true;
    return _public.contains(location);
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final SessionStore session = ref.watch(sessionProvider.notifier);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: session,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.matchedLocation;
      if (!session.isRestored) {
        return location == Routes.splash ? null : Routes.splash;
      }
      final bool signedIn = session.isSignedIn;
      final bool public = Routes.isPublic(location);
      if (location == Routes.splash) return signedIn ? Routes.home : Routes.welcome;
      if (!signedIn && !public) return Routes.welcome;
      if (signedIn && public && !location.startsWith('/auth/magic/')) return Routes.home;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: Routes.magic, builder: (_, __) => const MagicLinkScreen()),
      GoRoute(
        path: Routes.magicExchange,
        builder: (BuildContext context, GoRouterState state) =>
            MagicLinkExchangeScreen(token: state.pathParameters['token'] ?? ''),
      ),

      // Abas
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(
            routes: <RouteBase>[GoRoute(path: Routes.routine, builder: (_, __) => const RoutineScreen())],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[GoRoute(path: Routes.assistant, builder: (_, __) => const AssistantScreen())],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen())],
          ),
        ],
      ),

      // Telas de detalhe (cobrem a barra de abas)
      GoRoute(path: Routes.box, builder: (_, __) => const BoxEditorScreen()),
      GoRoute(path: Routes.orders, builder: (_, __) => const OrdersScreen()),
      GoRoute(
        path: Routes.orderDetail,
        builder: (BuildContext context, GoRouterState state) =>
            OrderDetailScreen(billId: state.pathParameters['billId'] ?? ''),
      ),
      GoRoute(
        path: Routes.pay,
        builder: (BuildContext context, GoRouterState state) => PayScreen(billId: state.pathParameters['billId'] ?? ''),
      ),
      GoRoute(path: Routes.cards, builder: (_, __) => const CardsScreen()),
      GoRoute(path: Routes.newCard, builder: (_, __) => const NewCardScreen()),
      GoRoute(path: Routes.address, builder: (_, __) => const AddressScreen()),
      GoRoute(path: Routes.plan, builder: (_, __) => const PlanScreen()),
      GoRoute(path: Routes.pause, builder: (_, __) => const PauseScreen()),
      GoRoute(path: Routes.cancel, builder: (_, __) => const CancelScreen()),
      GoRoute(path: Routes.subscription, builder: (_, __) => const SubscriptionStatusScreen()),
      GoRoute(path: Routes.profileData, builder: (_, __) => const ProfileDataScreen()),
      GoRoute(path: Routes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: Routes.consents, builder: (_, __) => const ConsentsScreen()),
      GoRoute(path: Routes.health, builder: (_, __) => const HealthScreen()),
      GoRoute(path: Routes.healthConsent, builder: (_, __) => const HealthConsentScreen()),
      GoRoute(
        path: Routes.assistantThread,
        builder: (BuildContext context, GoRouterState state) =>
            AssistantChatScreen(threadId: state.pathParameters['threadId']),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: TextButton(onPressed: () => context.go(Routes.home), child: const Text('Voltar ao início')),
      ),
    ),
  );
});
