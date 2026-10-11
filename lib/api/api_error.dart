import 'package:dio/dio.dart';

import 'models/json.dart';

/// Erro normalizado da API: `{code, message, details?}` + status HTTP.
/// Erros de rede/timeout também viram ApiError com códigos próprios.
class ApiError implements Exception {
  const ApiError({required this.code, required this.message, this.statusCode, this.details});

  final String code;
  final String message;
  final int? statusCode;
  final dynamic details;

  static const String codeNetwork = 'NETWORK_ERROR';
  static const String codeTimeout = 'TIMEOUT';
  static const String codeUnauthorized = 'UNAUTHORIZED';
  static const String codeUnknown = 'UNKNOWN';
  static const String codeCancelled = 'CANCELLED';

  bool get isNetwork => code == codeNetwork || code == codeTimeout;
  bool get isUnauthorized => statusCode == 401 || code == codeUnauthorized;
  bool get isNotFound => statusCode == 404;
  bool get isForbidden => statusCode == 403;
  bool get isRateLimited => statusCode == 429;

  /// `details.until` quando a ação está bloqueada por janela (ISO).
  String? get until {
    final Json? d = asMap(details);
    return asStringOrNull(d?['until']);
  }

  factory ApiError.fromDio(DioException e) {
    final Response<dynamic>? res = e.response;
    if (res != null) {
      final Json? body = asMap(res.data);
      if (body != null && (body['code'] != null || body['message'] != null)) {
        return ApiError(
          code: asString(body['code'], 'HTTP_${res.statusCode}'),
          message: asString(body['message'], _defaultMessage(res.statusCode)),
          statusCode: res.statusCode,
          details: body['details'],
        );
      }
      return ApiError(
        code: 'HTTP_${res.statusCode}',
        message: _defaultMessage(res.statusCode),
        statusCode: res.statusCode,
      );
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiError(code: codeTimeout, message: 'A conexão demorou demais. Tente novamente.');
      case DioExceptionType.cancel:
        return const ApiError(code: codeCancelled, message: 'Operação cancelada.');
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      case DioExceptionType.badResponse:
        return const ApiError(code: codeNetwork, message: 'Sem conexão com o servidor. Verifique sua internet.');
    }
  }

  /// Converte qualquer exceção em ApiError.
  static ApiError from(Object error) {
    if (error is ApiError) return error;
    if (error is DioException) return ApiError.fromDio(error);
    return ApiError(code: codeUnknown, message: 'Algo deu errado. Tente novamente. ($error)');
  }

  static String _defaultMessage(int? status) {
    switch (status) {
      case 400:
        return 'Dados inválidos. Revise e tente novamente.';
      case 401:
        return 'Sua sessão expirou. Entre novamente.';
      case 402:
        return 'Pagamento recusado.';
      case 403:
        return 'Ação não permitida no momento.';
      case 404:
        return 'Não encontrado.';
      case 409:
        return 'Conflito: a operação já foi realizada.';
      case 422:
        return 'Não foi possível processar a solicitação.';
      case 429:
        return 'Você atingiu o limite de uso. Tente mais tarde.';
      default:
        if (status != null && status >= 500) return 'O servidor está indisponível. Tente novamente em instantes.';
        return 'Algo deu errado. Tente novamente.';
    }
  }

  @override
  String toString() => 'ApiError($code${statusCode != null ? ' $statusCode' : ''}): $message';
}
