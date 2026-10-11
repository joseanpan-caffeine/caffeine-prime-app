import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/env.dart';
import '../api_error.dart';
import '../models/json.dart';
import '../models/payment.dart';

/// Tokenização de cartão na API pública da Vindi (o número do cartão nunca
/// passa pelo BFF). Usa `VindiConfig` de GET /payments/vindi-config.
///
/// Documentação Vindi: POST {apiUrl}/public/payment_profiles com
/// Basic auth `base64(publicKey + ':')` → `{payment_profile: {gateway_token}}`.
///
/// Em FAKE_AUTH devolve "fake-token-<últimos 4>" sem chamar a Vindi.
class VindiTokenizer {
  VindiTokenizer({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  final Dio _dio;

  Future<String> tokenize(VindiConfig config, NewCardInput card) async {
    if (Env.fakeAuth || config.publicKey.isEmpty || config.publicKey.startsWith('fake')) {
      return 'fake-token-${card.lastFour}';
    }
    final String base = config.apiUrl.endsWith('/') ? config.apiUrl.substring(0, config.apiUrl.length - 1) : config.apiUrl;
    final String auth = base64Encode(utf8.encode('${config.publicKey}:'));
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '$base/public/payment_profiles',
        data: compact(<String, dynamic>{
          'holder_name': card.holderName,
          'card_expiration': card.vindiExpiration,
          'card_number': card.digits,
          'card_cvv': card.cvv,
          'payment_method_code': 'credit_card',
          'payment_company_code': card.paymentCompanyCode,
        }),
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Basic $auth',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      final Json? body = asMap(res.data);
      final Json? profile = asMap(body?['payment_profile']);
      final String? token = asStringOrNull(profile?['gateway_token']);
      if (token == null) {
        throw const ApiError(code: 'VINDI_NO_TOKEN', message: 'A Vindi não devolveu o token do cartão.');
      }
      return token;
    } on DioException catch (e) {
      // A Vindi responde `{errors: [{id, parameter, message}]}`.
      final Json? body = asMap(e.response?.data);
      final List<Json> errors = asMapList(body?['errors']);
      final String message = errors.isNotEmpty
          ? errors.map((er) => '${asString(er['parameter'])}: ${asString(er['message'])}'.trim()).join('; ')
          : 'Não foi possível validar o cartão. Confira os dados.';
      throw ApiError(code: 'VINDI_TOKENIZE_FAILED', message: message, statusCode: e.response?.statusCode);
    }
  }
}
