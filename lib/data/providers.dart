import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/endpoints/account_api.dart';
import '../api/endpoints/auth_api.dart';
import '../api/endpoints/engagement_api.dart';
import '../api/endpoints/payment_api.dart';
import '../api/endpoints/subscription_api.dart';
import '../api/endpoints/vindi_api.dart';
import '../api/models/models.dart';
import '../core/env.dart';
import 'session_store.dart';

// ---------- Sessão e cliente ----------

/// Sessão (tokens + usuário). Também é o `refreshListenable` do router.
final ChangeNotifierProvider<SessionStore> sessionProvider = ChangeNotifierProvider<SessionStore>((ref) {
  return SessionStore();
});

/// Usuário logado (ou null). Rebuilda quando a sessão muda.
final Provider<UserProfile?> currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(sessionProvider).user;
});

/// Id do cliente logado (shopifyCustomerId). Usado como "chave" dos providers
/// de dados para que troquem de usuário sem vazar cache.
final Provider<String?> currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider.select((s) => s.user?.id));
});

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  // `.notifier` não rebuilda a cada notifyListeners: o cliente é único.
  final SessionStore session = ref.watch(sessionProvider.notifier);
  return ApiClient(session: session, baseUrl: Env.apiUrl);
});

final Provider<AuthApi> authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));
final Provider<AccountApi> accountApiProvider = Provider<AccountApi>((ref) => AccountApi(ref.watch(apiClientProvider)));
final Provider<SubscriptionApi> subscriptionApiProvider =
    Provider<SubscriptionApi>((ref) => SubscriptionApi(ref.watch(apiClientProvider)));
final Provider<PaymentApi> paymentApiProvider = Provider<PaymentApi>((ref) => PaymentApi(ref.watch(apiClientProvider)));
final Provider<RoutineApi> routineApiProvider = Provider<RoutineApi>((ref) => RoutineApi(ref.watch(apiClientProvider)));
final Provider<HealthApi> healthApiProvider = Provider<HealthApi>((ref) => HealthApi(ref.watch(apiClientProvider)));
final Provider<AssistantApi> assistantApiProvider =
    Provider<AssistantApi>((ref) => AssistantApi(ref.watch(apiClientProvider)));
final Provider<VindiTokenizer> vindiTokenizerProvider = Provider<VindiTokenizer>((ref) => VindiTokenizer());

// ---------- Config pública ----------

final FutureProvider<AppConfig> appConfigProvider = FutureProvider<AppConfig>((ref) async {
  try {
    return await ref.watch(accountApiProvider).config();
  } catch (_) {
    // Config é opcional: sem ela o app usa defaults.
    return AppConfig.defaults;
  }
});

/// Config síncrona com fallback (para leituras em widgets).
final Provider<AppConfig> appConfigValueProvider = Provider<AppConfig>((ref) {
  return ref.watch(appConfigProvider).valueOrNull ?? AppConfig.defaults;
});

// ---------- Dados da conta (dependem do usuário logado) ----------

String _requireUser(Ref ref) {
  final String? id = ref.watch(currentUserIdProvider);
  if (id == null) throw StateError('Sem sessão');
  return id;
}

final FutureProvider<Dashboard> dashboardProvider = FutureProvider<Dashboard>((ref) async {
  _requireUser(ref);
  final Dashboard d = await ref.watch(accountApiProvider).dashboard();
  // Mantém o perfil da sessão atualizado (hasSubscription etc.).
  final SessionStore session = ref.read(sessionProvider.notifier);
  if (session.user != null && session.user!.id == d.user.id) {
    // não await: não bloqueia a tela
    session.updateUser(d.user);
  }
  return d;
});

/// Assinatura corrente (null quando não há). Nunca guardar o id.
final FutureProvider<Subscription?> subscriptionProvider = FutureProvider<Subscription?>((ref) async {
  _requireUser(ref);
  return ref.watch(subscriptionApiProvider).current();
});

final FutureProvider<Catalog> catalogProvider = FutureProvider<Catalog>((ref) async {
  _requireUser(ref);
  return ref.watch(subscriptionApiProvider).catalog();
});

final FutureProvider<List<Bill>> billsProvider = FutureProvider<List<Bill>>((ref) async {
  _requireUser(ref);
  return ref.watch(paymentApiProvider).bills();
});

final FutureProviderFamily<Bill, String> billProvider = FutureProvider.family<Bill, String>((ref, billId) async {
  _requireUser(ref);
  return ref.watch(paymentApiProvider).bill(billId);
});

final FutureProvider<List<PaymentProfile>> paymentProfilesProvider = FutureProvider<List<PaymentProfile>>((ref) async {
  _requireUser(ref);
  return ref.watch(paymentApiProvider).paymentProfiles();
});

final FutureProvider<ShippingAddress?> shippingAddressProvider = FutureProvider<ShippingAddress?>((ref) async {
  _requireUser(ref);
  try {
    return await ref.watch(accountApiProvider).shippingAddress();
  } catch (_) {
    return null;
  }
});

final FutureProvider<Fulfillment?> trackingProvider = FutureProvider<Fulfillment?>((ref) async {
  _requireUser(ref);
  return ref.watch(accountApiProvider).tracking();
});

final FutureProvider<NotificationPreferences> notificationPrefsProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  _requireUser(ref);
  return ref.watch(accountApiProvider).notificationPreferences();
});

final FutureProvider<List<ReasonOption>> cancelReasonsProvider = FutureProvider<List<ReasonOption>>((ref) async {
  _requireUser(ref);
  return ref.watch(subscriptionApiProvider).cancelReasons();
});

final FutureProvider<List<ReasonOption>> pauseReasonsProvider = FutureProvider<List<ReasonOption>>((ref) async {
  _requireUser(ref);
  return ref.watch(subscriptionApiProvider).pauseReasons();
});

final FutureProvider<VindiConfig> vindiConfigProvider = FutureProvider<VindiConfig>((ref) async {
  return ref.watch(paymentApiProvider).vindiConfig();
});

// ---------- Consentimentos ----------

final FutureProvider<List<Consent>> consentsProvider = FutureProvider<List<Consent>>((ref) async {
  _requireUser(ref);
  try {
    return await ref.watch(accountApiProvider).consents();
  } catch (_) {
    // BFF antigo sem a rota: trata como nenhum consentimento concedido.
    return <Consent>[];
  }
});

/// `true` quando o consentimento está concedido (false enquanto carrega).
final ProviderFamily<bool, ConsentKind> consentGrantedProvider = Provider.family<bool, ConsentKind>((ref, kind) {
  final List<Consent> list = ref.watch(consentsProvider).valueOrNull ?? const <Consent>[];
  for (final Consent c in list) {
    if (c.kind == kind) return c.granted;
  }
  return false;
});

// ---------- Rotina / saúde / assistente ----------

final FutureProvider<RoutinePlan> routinePlanProvider = FutureProvider<RoutinePlan>((ref) async {
  _requireUser(ref);
  return ref.watch(routineApiProvider).plan();
});

final FutureProvider<RoutineSummary> routineSummaryProvider = FutureProvider<RoutineSummary>((ref) async {
  _requireUser(ref);
  return ref.watch(routineApiProvider).summary();
});

final FutureProvider<HealthSummary> healthSummaryProvider = FutureProvider<HealthSummary>((ref) async {
  _requireUser(ref);
  return ref.watch(healthApiProvider).summary();
});

final FutureProvider<AssistantConfig> assistantConfigProvider = FutureProvider<AssistantConfig>((ref) async {
  _requireUser(ref);
  try {
    return await ref.watch(assistantApiProvider).config();
  } catch (_) {
    return AssistantConfig.disabled;
  }
});

final FutureProvider<List<AssistantThread>> assistantThreadsProvider = FutureProvider<List<AssistantThread>>((ref) async {
  _requireUser(ref);
  return ref.watch(assistantApiProvider).threads();
});

// ---------- Invalidação após mutações ----------

/// Depois de qualquer ação que escreve na assinatura, recarrega tudo que
/// depende dela. O estado pode levar instantes para refletir (§3.3).
void invalidateSubscriptionData(Ref ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(subscriptionProvider);
  ref.invalidate(billsProvider);
  ref.invalidate(trackingProvider);
}

/// Versão para uso em widgets (WidgetRef).
void refreshSubscriptionData(WidgetRef ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(subscriptionProvider);
  ref.invalidate(billsProvider);
  ref.invalidate(trackingProvider);
}
