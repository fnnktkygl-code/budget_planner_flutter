import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kTrueLayerClientId = 'truelayer_client_id';
  static const _kTrueLayerClientSecret = 'truelayer_client_secret';
  static const _kTrueLayerAccessToken = 'truelayer_access_token';
  static const _kTrueLayerRefreshToken = 'truelayer_refresh_token';

  static Future<void> saveTrueLayerCredentials(String clientId, String clientSecret) async {
    await _storage.write(key: _kTrueLayerClientId, value: clientId);
    await _storage.write(key: _kTrueLayerClientSecret, value: clientSecret);
  }

  static Future<String?> getTrueLayerClientId() async {
    return await _storage.read(key: _kTrueLayerClientId);
  }

  static Future<String?> getTrueLayerClientSecret() async {
    return await _storage.read(key: _kTrueLayerClientSecret);
  }

  static Future<void> saveTrueLayerTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _kTrueLayerAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _kTrueLayerRefreshToken, value: refreshToken);
    }
  }

  static Future<String?> getTrueLayerAccessToken() async {
    return await _storage.read(key: _kTrueLayerAccessToken);
  }

  static Future<String?> getTrueLayerRefreshToken() async {
    return await _storage.read(key: _kTrueLayerRefreshToken);
  }

  static Future<void> clearTrueLayerTokens() async {
    await _storage.delete(key: _kTrueLayerAccessToken);
    await _storage.delete(key: _kTrueLayerRefreshToken);
  }
}
