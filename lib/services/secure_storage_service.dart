import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kTrueLayerClientId = 'truelayer_client_id';
  static const _kTrueLayerClientSecret = 'truelayer_client_secret';
  static const _kTrueLayerAccessToken = 'truelayer_access_token';
  static const _kTrueLayerRefreshToken = 'truelayer_refresh_token';

  static Future<void> saveTrueLayerCredentials(String clientId, String clientSecret, String userId) async {
    if (userId.isEmpty) return;
    await _storage.write(key: '${userId}_$_kTrueLayerClientId', value: clientId);
    await _storage.write(key: '${userId}_$_kTrueLayerClientSecret', value: clientSecret);
  }

  static Future<String?> getTrueLayerClientId(String userId) async {
    if (userId.isEmpty) return null;
    return await _storage.read(key: '${userId}_$_kTrueLayerClientId');
  }

  static Future<String?> getTrueLayerClientSecret(String userId) async {
    if (userId.isEmpty) return null;
    return await _storage.read(key: '${userId}_$_kTrueLayerClientSecret');
  }

  static Future<void> saveTrueLayerTokens({required String accessToken, String? refreshToken, required String userId}) async {
    if (userId.isEmpty) return;
    await _storage.write(key: '${userId}_$_kTrueLayerAccessToken', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: '${userId}_$_kTrueLayerRefreshToken', value: refreshToken);
    }
  }

  static Future<String?> getTrueLayerAccessToken(String userId) async {
    if (userId.isEmpty) return null;
    return await _storage.read(key: '${userId}_$_kTrueLayerAccessToken');
  }

  static Future<String?> getTrueLayerRefreshToken(String userId) async {
    if (userId.isEmpty) return null;
    return await _storage.read(key: '${userId}_$_kTrueLayerRefreshToken');
  }

  static Future<void> clearTrueLayerTokens(String userId) async {
    if (userId.isEmpty) return;
    await _storage.delete(key: '${userId}_$_kTrueLayerAccessToken');
    await _storage.delete(key: '${userId}_$_kTrueLayerRefreshToken');
  }
}
