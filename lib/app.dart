import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/deep_links.dart';
import 'core/notifications/local_notifications.dart';
import 'core/push/push_provider.dart';
import 'core/push/push_service.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'router.dart';

class CaffeinePrimeApp extends ConsumerWidget {
  const CaffeinePrimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Caffeine Army Prime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) {
        return DeepLinkListener(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Escuta deep links (app_links), toques em push e em lembretes locais e
/// navega para a rota correspondente. Links recebidos sem sessão ficam
/// pendentes até o login.
///
/// VERIFICAR na compilação: API do app_links 6.x (`getInitialLink`,
/// `uriLinkStream`).
class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
  String? _pending;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    // Sessão: quando logar, consome o link pendente.
    ref.read(sessionProvider.notifier).addListener(_onSessionChanged);

    // Deep links (universal/app links e esquema customizado).
    if (!kIsWeb) {
      try {
        final AppLinks appLinks = AppLinks();
        final Uri? initial = await appLinks.getInitialLink();
        if (initial != null) _handleUri(initial);
        _subs.add(appLinks.uriLinkStream.listen(_handleUri));
      } catch (e) {
        debugPrint('app_links indisponível: $e');
      }
    }

    // Push: inicializa (Firebase opcional) e trata toques.
    final PushRegistrar registrar = ref.read(pushRegistrarProvider);
    await registrar.ensureInitialized();
    final PushService push = ref.read(pushServiceProvider);
    _subs.add(push.onNotificationOpened.listen(_handleUri));
    final Uri? pushInitial = await push.initialNotificationLink();
    if (pushInitial != null) _handleUri(pushInitial);

    // Lembretes locais.
    final LocalNotifications local = ref.read(localNotificationsProvider);
    await local.init();
    _subs.add(local.onTap.listen((String payload) {
      final String? route = DeepLinks.routeForString(payload);
      if (route != null) _go(route);
    }));
    await local.emitInitialTap();
  }

  void _handleUri(Uri uri) {
    final String? route = DeepLinks.routeFor(uri);
    if (route != null) _go(route);
  }

  void _go(String route) {
    final bool signedIn = ref.read(sessionProvider.notifier).isSignedIn;
    final bool isMagic = route.startsWith('/auth/magic/');
    if (!signedIn && !isMagic) {
      _pending = route;
      return;
    }
    ref.read(routerProvider).go(route);
  }

  void _onSessionChanged() {
    if (!mounted) return;
    final bool signedIn = ref.read(sessionProvider.notifier).isSignedIn;
    if (signedIn && _pending != null) {
      final String route = _pending!;
      _pending = null;
      // Deixa o redirect do router assentar antes de navegar.
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) ref.read(routerProvider).go(route);
      });
    }
  }

  @override
  void dispose() {
    for (final StreamSubscription<dynamic> s in _subs) {
      s.cancel();
    }
    try {
      ref.read(sessionProvider.notifier).removeListener(_onSessionChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
