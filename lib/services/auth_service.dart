import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keycloak configuration
  static const String _issuer =
      'http://localhost:8060/realms/gateway-demo';
  static const String _clientId = 'mobile-app';
  static const String _redirectUri =
      'com.recodextech.fixflow://callback';
  static const List<String> _scopes = ['openid', 'email', 'profile'];

  // Secure storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _userIdKey = 'auth_user_id';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userNameKey = 'auth_user_name';

  /// Sign in with Google via Keycloak.
  /// Uses authorization code + PKCE flow.
  Future<bool> signInWithGoogle() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          issuer: _issuer,
          scopes: _scopes,
          additionalParameters: {'kc_idp_hint': 'google'},
          allowInsecureConnections: true, // localhost dev only
        ),
      );

      if (result.accessToken == null) {
        return false;
      }

      await _storeTokens(result);
      return true;
    } catch (e) {
      print('Auth error: $e');
      return false;
    }
  }

  /// Refresh the access token using the stored refresh token.
  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUri,
          issuer: _issuer,
          refreshToken: refreshToken,
          allowInsecureConnections: true,
        ),
      );

      if (result.accessToken == null) {
        return false;
      }

      await _storeTokens(result);
      return true;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  /// Get a valid access token — refreshes automatically if expired.
  Future<String?> getAccessToken() async {
    final expiryStr = await _secureStorage.read(key: _accessTokenExpiryKey);
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null &&
          expiry.isBefore(DateTime.now().subtract(const Duration(seconds: 30)))) {
        // Token expired or about to expire — refresh
        final refreshed = await refreshTokens();
        if (!refreshed) return null;
      }
    }
    return _secureStorage.read(key: _accessTokenKey);
  }

  /// Check if the user is currently authenticated.
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null) return false;

    // Try refreshing if token might be expired
    final expiryStr = await _secureStorage.read(key: _accessTokenExpiryKey);
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && expiry.isBefore(DateTime.now())) {
        return await refreshTokens();
      }
    }
    return true;
  }

  /// Logout — clear all stored tokens.
  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _accessTokenExpiryKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userEmailKey);
    await _secureStorage.delete(key: _userNameKey);
  }

  /// Get stored user email.
  Future<String?> getUserEmail() =>
      _secureStorage.read(key: _userEmailKey);

  /// Get stored user name.
  Future<String?> getUserName() =>
      _secureStorage.read(key: _userNameKey);

  /// Get stored Keycloak user ID (sub claim).
  Future<String?> getUserId() =>
      _secureStorage.read(key: _userIdKey);

  // -- Private helpers --

  Future<void> _storeTokens(TokenResponse result) async {
    await _secureStorage.write(
        key: _accessTokenKey, value: result.accessToken);

    if (result.refreshToken != null) {
      await _secureStorage.write(
          key: _refreshTokenKey, value: result.refreshToken);
    }

    if (result.accessTokenExpirationDateTime != null) {
      await _secureStorage.write(
          key: _accessTokenExpiryKey,
          value: result.accessTokenExpirationDateTime!.toIso8601String());
    }

    // Decode JWT to extract user info
    _extractAndStoreUserInfo(result.accessToken!);
  }

  Future<void> _extractAndStoreUserInfo(String accessToken) async {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return;

      String payload = parts[1];
      // Pad base64 to multiple of 4
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      final sub = claims['sub'] as String?;
      final email = claims['email'] as String?;
      final name = claims['name'] as String? ??
          claims['preferred_username'] as String?;

      if (sub != null) {
        await _secureStorage.write(key: _userIdKey, value: sub);
      }
      if (email != null) {
        await _secureStorage.write(key: _userEmailKey, value: email);
      }
      if (name != null) {
        await _secureStorage.write(key: _userNameKey, value: name);
      }
    } catch (e) {
      print('Error extracting user info from token: $e');
    }
  }
}
