/// Mapeia deep links para rotas do go_router.
///
/// Esquemas aceitos:
/// - `app://<destino>[?query]` (banners, assistente, push, lembretes locais)
/// - `caffeineprime://auth/magic/:token` (link mágico)
/// - `caffeineprime://<destino>` (mesmo que `app://`)
/// - `https://…/account/prime/<destino>` (links universais da web)
class DeepLinks {
  DeepLinks._();

  /// Rotas-alvo conhecidas (destino → rota). Destinos desconhecidos vão para a Home.
  static const Map<String, String> _targets = <String, String>{
    'home': '/home',
    'dashboard': '/home',
    'box': '/box',
    'edit-box': '/box',
    'editar-caixa': '/box',
    'orders': '/orders',
    'pedidos': '/orders',
    'cards': '/cards',
    'cartoes': '/cards',
    'address': '/address',
    'endereco': '/address',
    'plan': '/plan',
    'plano': '/plan',
    'subscription': '/subscription',
    'assinatura': '/subscription',
    'pause': '/pause',
    'cancel': '/cancel',
    'routine': '/routine',
    'rotina': '/routine',
    'health': '/health',
    'saude': '/health',
    'assistant': '/assistant',
    'assistente': '/assistant',
    'profile': '/profile',
    'perfil': '/profile',
    'consents': '/consents',
    'notifications': '/profile/notifications',
  };

  /// Converte uma URI de deep link em rota interna, ou null se não reconhecida.
  static String? routeFor(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();
    List<String> segments;
    if (scheme == 'app' || scheme == 'caffeineprime') {
      segments = <String>[if (uri.host.isNotEmpty) uri.host, ...uri.pathSegments];
    } else if (scheme == 'https' || scheme == 'http') {
      final List<String> all = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final int idx = all.indexOf('prime');
      segments = idx >= 0 ? all.sublist(idx + 1) : all;
    } else {
      return null;
    }
    segments = segments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/home';

    final String head = segments.first.toLowerCase();
    final String query = uri.query.isEmpty ? '' : '?${uri.query}';

    // caffeineprime://auth/magic/:token
    if (head == 'auth' && segments.length >= 3 && segments[1] == 'magic') {
      return '/auth/magic/${Uri.encodeComponent(segments[2])}';
    }
    // app://pay/:billId | app://orders/:billId | app://assistant/:threadId
    if ((head == 'pay' || head == 'pagar') && segments.length >= 2) return '/pay/${segments[1]}$query';
    if ((head == 'orders' || head == 'pedidos') && segments.length >= 2) return '/orders/${segments[1]}$query';
    if ((head == 'assistant' || head == 'assistente') && segments.length >= 2) {
      return '/assistant/${segments[1]}$query';
    }
    final String? target = _targets[head];
    if (target != null) return '$target$query';
    return '/home';
  }

  /// Aceita também uma string (ex.: `deepLink` do BFF). Strings sem esquema
  /// são tratadas como rota interna ("/box").
  static String? routeForString(String? link) {
    if (link == null || link.isEmpty) return null;
    if (link.startsWith('/')) return link;
    final Uri? uri = Uri.tryParse(link);
    if (uri == null) return null;
    return routeFor(uri);
  }
}
