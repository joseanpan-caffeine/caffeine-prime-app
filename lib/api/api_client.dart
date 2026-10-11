import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/idempotency.dart';
import '../data/session_store.dart';
import 'api_error.dart';
import 'models/auth.dart';
import 'models/json.dart';

/// Cliente HTTP do BFF.
///
/// - Bearer token da sessão em toda chamada, exceto `extra['noAuth'] = true`.
/// - Em 401: refresh único (single-flight) com `refreshToken` e nova tentativa
///   da requisição original; se o refresh falhar, a sessão é limpa.
/// - Mutações (POST/PUT/PATCH/DELETE) recebem `Idempotency-Key` (UUID v4),
///   gerado uma única vez por requisição, inclusive na retentativa pós-refresh.
/// - Erros viram [ApiError].
class ApiClient {
  ApiClient({required this.session, required String baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: <String, dynamic>{'Accept': 'application/json'},
            contentType: 'application/json',
            responseType: ResponseType.json,
          ),
        ),
        _raw = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: <String, dynamic>{'Accept': 'application/json'},
            contentType: 'application/json',
            responseType: ResponseType.json,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false, logPrint: (o) => debugPrint('$o')));
    }
  }

  final SessionStore session;
  final Dio dio;

  /// Dio sem interceptors, usado só no refresh (evita recursão).
  final Dio _raw;

  Future<bool>? _refreshing;

  static const String _kNoAuth = 'noAuth';
  static const String _kRetried = 'retried';

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final bool noAuth = options.extra[_kNoAuth] == true;
    final String? token = session.accessToken;
    if (!noAuth && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final String method = options.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD' && !options.headers.containsKey('Idempotency-Key')) {
      options.headers['Idempotency-Key'] = uuidV4();
    }
    handler.next(options);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    final RequestOptions req = e.requestOptions;
    final bool noAuth = req.extra[_kNoAuth] == true;
    final bool retried = req.extra[_kRetried] == true;
    final int? status = e.response?.statusCode;

    if (status == 401 && !noAuth && !retried && session.refreshToken != null) {
      final bool ok = await _refreshTokens();
      if (ok) {
        try {
          req.extra[_kRetried] = true;
          req.headers['Authorization'] = 'Bearer ${session.accessToken}';
          final Response<dynamic> res = await dio.fetch<dynamic>(req);
          handler.resolve(res);
          return;
        } on DioException catch (retryError) {
          handler.reject(retryError);
          return;
        }
      }
      // Refresh falhou: sessão encerrada.
      await session.clear();
    }
    handler.next(e);
  }

  /// Refresh single-flight: chamadas concorrentes aguardam a mesma Future.
  Future<bool> _refreshTokens() {
    final Future<bool>? inFlight = _refreshing;
    if (inFlight != null) return inFlight;
    final Future<bool> fut = _doRefresh().whenComplete(() => _refreshing = null);
    _refreshing = fut;
    return fut;
  }

  Future<bool> _doRefresh() async {
    final String? refresh = session.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final Response<dynamic> res = await _raw.post<dynamic>(
        '/auth/refresh',
        data: RefreshRequest(refreshToken: refresh).toJson(),
      );
      final Json? body = asMap(res.data);
      if (body == null) return false;
      final AuthTokens tokens = AuthTokens.fromJson(body);
      if (tokens.accessToken.isEmpty) return false;
      await session.updateTokens(tokens);
      return true;
    } catch (e) {
      debugPrint('Refresh de token falhou: $e');
      return false;
    }
  }

  // ---------- Helpers de chamada ----------

  Options _opts({bool noAuth = false, String? idempotencyKey}) {
    return Options(
      extra: <String, dynamic>{_kNoAuth: noAuth},
      headers: idempotencyKey == null ? null : <String, dynamic>{'Idempotency-Key': idempotencyKey},
    );
  }

  Future<dynamic> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final Response<dynamic> res = await call();
      return res.data;
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// GET que devolve um objeto JSON (ou `{}` para corpo vazio).
  Future<Json> getJson(String path, {Map<String, dynamic>? query, bool noAuth = false}) async {
    final dynamic data = await _run(() => dio.get<dynamic>(path, queryParameters: query, options: _opts(noAuth: noAuth)));
    return asMap(data) ?? <String, dynamic>{};
  }

  /// GET que devolve uma lista de objetos JSON.
  Future<List<Json>> getList(String path, {Map<String, dynamic>? query, bool noAuth = false}) async {
    final dynamic data = await _run(() => dio.get<dynamic>(path, queryParameters: query, options: _opts(noAuth: noAuth)));
    return asMapList(data);
  }

  Future<Json> postJson(String path, {Object? body, bool noAuth = false, String? idempotencyKey}) async {
    final dynamic data = await _run(
      () => dio.post<dynamic>(path, data: body, options: _opts(noAuth: noAuth, idempotencyKey: idempotencyKey)),
    );
    return asMap(data) ?? <String, dynamic>{};
  }

  Future<Json> putJson(String path, {Object? body, String? idempotencyKey}) async {
    final dynamic data = await _run(() => dio.put<dynamic>(path, data: body, options: _opts(idempotencyKey: idempotencyKey)));
    return asMap(data) ?? <String, dynamic>{};
  }

  /// GET que devolve o corpo cru (objeto ou lista).
  Future<dynamic> getRaw(String path, {Map<String, dynamic>? query}) async {
    return _run(() => dio.get<dynamic>(path, queryParameters: query, options: _opts()));
  }

  /// PUT que devolve o corpo cru (objeto ou lista).
  Future<dynamic> putRaw(String path, {Object? body}) async {
    return _run(() => dio.put<dynamic>(path, data: body, options: _opts()));
  }

  Future<Json> patchJson(String path, {Object? body, String? idempotencyKey}) async {
    final dynamic data =
        await _run(() => dio.patch<dynamic>(path, data: body, options: _opts(idempotencyKey: idempotencyKey)));
    return asMap(data) ?? <String, dynamic>{};
  }

  Future<List<Json>> postList(String path, {Object? body}) async {
    final dynamic data = await _run(() => dio.post<dynamic>(path, data: body, options: _opts()));
    return asMapList(data);
  }

  Future<void> delete(String path, {Object? body, bool noAuth = false}) async {
    await _run(() => dio.delete<dynamic>(path, data: body, options: _opts(noAuth: noAuth)));
  }
}
