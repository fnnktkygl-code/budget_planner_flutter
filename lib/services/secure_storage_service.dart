import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kTrueLayerClientId = 'truelayer_client_id';
  static const _kTrueLayerClientSecret = 'truelayer_client_secret';
  static const _kTrueLayerAccessToken = 'truelayer_access_token';
  static const _kTrueLayerRefreshToken = 'truelayer_refresh_token';

  static String _key(String userId, String key) => userId.isEmpty ? 'guest_$key' : '${userId}_$key';

  static Future<void> saveTrueLayerCredentials(String clientId, String clientSecret, String userId) async {
    await _storage.write(key: _key(userId, _kTrueLayerClientId), value: clientId);
    await _storage.write(key: _key(userId, _kTrueLayerClientSecret), value: clientSecret);
  }

  static Future<String?> getTrueLayerClientId(String userId) async {
    return await _storage.read(key: _key(userId, _kTrueLayerClientId));
  }

  static Future<String?> getTrueLayerClientSecret(String userId) async {
    return await _storage.read(key: _key(userId, _kTrueLayerClientSecret));
  }

  static Future<void> saveTrueLayerTokens({required String accessToken, String? refreshToken, required String userId}) async {
    await _storage.write(key: _key(userId, _kTrueLayerAccessToken), value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _key(userId, _kTrueLayerRefreshToken), value: refreshToken);
    }
  }

  static Future<String?> getTrueLayerAccessToken(String userId) async {
    return await _storage.read(key: _key(userId, _kTrueLayerAccessToken));
  }

  static Future<String?> getTrueLayerRefreshToken(String userId) async {
    return await _storage.read(key: _key(userId, _kTrueLayerRefreshToken));
  }

  static Future<void> clearTrueLayerTokens(String userId) async {
    await _storage.delete(key: _key(userId, _kTrueLayerAccessToken));
    await _storage.delete(key: _key(userId, _kTrueLayerRefreshToken));
  }
}
