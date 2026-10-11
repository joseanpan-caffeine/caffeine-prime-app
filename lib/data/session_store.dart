import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/models/auth.dart';
import '../api/models/json.dart';
import '../api/models/profile.dart';

/// Sessão do usuário: tokens no armazenamento seguro + perfil em memória.
/// É um ChangeNotifier para servir de `refreshListenable` do go_router.
class SessionStore extends ChangeNotifier {
  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _kTokens = 'prime.auth.tokens';
  static const String _kUser = 'prime.auth.user';

  final FlutterSecureStorage _storage;

  AuthTokens? _tokens;
  UserProfile? _user;
  bool _restored = false;

  AuthTokens? get tokens => _tokens;
  UserProfile? get user => _user;
  String? get accessToken => _tokens?.accessToken;
  String? get refreshToken => _tokens?.refreshToken;
  bool get isRestored => _restored;
  bool get isSignedIn => _tokens != null && _tokens!.accessToken.isNotEmpty;

  /// Carrega a sessão salva. Nunca lança: erro de storage = sessão vazia.
  Future<void> restore() async {
    try {
      final String? rawTokens = await _storage.read(key: _kTokens);
      final String? rawUser = await _storage.read(key: _kUser);
      if (rawTokens != null) {
        final Json? t = asMap(jsonDecode(rawTokens));
        if (t != null) _tokens = AuthTokens.fromJson(t);
      }
      if (rawUser != null) {
        final Json? u = asMap(jsonDecode(rawUser));
        if (u != null) _user = UserProfile.fromJson(u);
      }
    } catch (e) {
      debugPrint('SessionStore.restore falhou: $e');
      _tokens = null;
      _user = null;
    }
    _restored = true;
    notifyListeners();
  }

  Future<void> setSession(AuthTokens tokens, UserProfile user) async {
    _tokens = tokens;
    _user = user;
    await _persist();
    notifyListeners();
  }

  Future<void> updateTokens(AuthTokens tokens) async {
    _tokens = tokens;
    await _persist();
    // Não notifica: a troca de token não muda o estado de navegação.
  }

  Future<void> updateUser(UserProfile user) async {
    _user = user;
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    _tokens = null;
    _user = null;
    try {
      await _storage.delete(key: _kTokens);
      await _storage.delete(key: _kUser);
    } catch (e) {
      debugPrint('SessionStore.clear falhou: $e');
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      if (_tokens != null) {
        await _storage.write(key: _kTokens, value: jsonEncode(_tokens!.toJson()));
      }
      if (_user != null) {
        await _storage.write(key: _kUser, value: jsonEncode(_user!.toJson()));
      }
    } catch (e) {
      debugPrint('SessionStore._persist falhou: $e');
    }
  }
}
