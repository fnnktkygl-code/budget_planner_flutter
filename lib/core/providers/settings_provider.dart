import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/secure_storage_service.dart';
import '../../services/truelayer_service.dart';
import 'auth_provider.dart';

class SettingsState {
  final String languageCode;
  final bool bankConnected;
  final String connectedBankName;
  final String truelayerClientId;
  final String truelayerClientSecret;
  final String truelayerAccessToken;
  final bool truelayerUseSandbox;

  SettingsState({
    required this.languageCode,
    required this.bankConnected,
    required this.connectedBankName,
    required this.truelayerClientId,
    required this.truelayerClientSecret,
    required this.truelayerAccessToken,
    required this.truelayerUseSandbox,
  });

  SettingsState copyWith({
    String? languageCode,
    bool? bankConnected,
    String? connectedBankName,
    String? truelayerClientId,
    String? truelayerClientSecret,
    String? truelayerAccessToken,
    bool? truelayerUseSandbox,
  }) {
    return SettingsState(
      languageCode: languageCode ?? this.languageCode,
      bankConnected: bankConnected ?? this.bankConnected,
      connectedBankName: connectedBankName ?? this.connectedBankName,
      truelayerClientId: truelayerClientId ?? this.truelayerClientId,
      truelayerClientSecret: truelayerClientSecret ?? this.truelayerClientSecret,
      truelayerAccessToken: truelayerAccessToken ?? this.truelayerAccessToken,
      truelayerUseSandbox: truelayerUseSandbox ?? this.truelayerUseSandbox,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final String userId;

  SettingsNotifier({required this.userId})
      : super(SettingsState(
          languageCode: 'fr',
          bankConnected: false,
          connectedBankName: '',
          truelayerClientId: 'aurabudgetpro-f0ea54',
          truelayerClientSecret: '',
          truelayerAccessToken: '',
          truelayerUseSandbox: false,
        )) {
    if (userId.isNotEmpty) {
      init();
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('${userId}_app_language_code') ?? 'fr';
    final bankConnected = prefs.getBool('${userId}_bank_connected') ?? false;
    final connectedBankName = prefs.getString('${userId}_connected_bank_name') ?? '';
    final truelayerUseSandbox = prefs.getBool('${userId}_truelayer_use_sandbox') ?? false;

    var clientId = await SecureStorageService.getTrueLayerClientId(userId) ?? '';
    var clientSecret = await SecureStorageService.getTrueLayerClientSecret(userId) ?? '';
    final accessToken = await SecureStorageService.getTrueLayerAccessToken(userId) ?? '';

    // Auto-migration vers l'ID Live si ancien sandbox trouvé
    if (clientId.isEmpty || clientId == 'sandbox-aurabudgetpro-f0ea54') {
      clientId = 'aurabudgetpro-f0ea54';
      clientSecret = '';
      await SecureStorageService.saveTrueLayerCredentials(clientId, clientSecret, userId);
    }

    if (clientSecret.isEmpty) {
      try {
        try {
          final loadedSecret = await rootBundle.loadString('assets/aurabudgetpro-f0ea54-secret.txt');
          clientSecret = loadedSecret.trim();
        } catch (_) {
          final loadedSecret = await rootBundle.loadString('assets/sandbox-aurabudgetpro-f0ea54-secret.txt');
          clientSecret = loadedSecret.trim();
        }
        await SecureStorageService.saveTrueLayerCredentials(clientId, clientSecret, userId);
      } catch (_) {}
    }

    state = SettingsState(
      languageCode: languageCode,
      bankConnected: bankConnected,
      connectedBankName: connectedBankName,
      truelayerClientId: clientId,
      truelayerClientSecret: clientSecret,
      truelayerAccessToken: accessToken,
      truelayerUseSandbox: truelayerUseSandbox,
    );
  }

  Future<void> setLanguage(String code) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${userId}_app_language_code', code);
    state = state.copyWith(languageCode: code);
  }

  Future<void> setSandboxMode(bool useSandbox) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${userId}_truelayer_use_sandbox', useSandbox);
    state = state.copyWith(truelayerUseSandbox: useSandbox);
  }

  Future<void> updateTrueLayerCredentials(String clientId, String clientSecret) async {
    if (userId.isEmpty) return;
    await SecureStorageService.saveTrueLayerCredentials(clientId, clientSecret, userId);
    state = state.copyWith(
      truelayerClientId: clientId,
      truelayerClientSecret: clientSecret,
    );
  }

  Future<void> setBankConnected(bool connected, String bankName) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${userId}_bank_connected', connected);
    await prefs.setString('${userId}_connected_bank_name', bankName);
    state = state.copyWith(
      bankConnected: connected,
      connectedBankName: bankName,
    );
  }

  Future<void> setAccessToken(String token) async {
    if (userId.isEmpty) return;
    await SecureStorageService.saveTrueLayerTokens(accessToken: token, userId: userId);
    state = state.copyWith(truelayerAccessToken: token);
  }

  Future<bool> processTrueLayerCode(String code) async {
    if (userId.isEmpty) return false;
    final redirectUri = Uri.base.origin;
    
    try {
      final tokenData = await TrueLayerService.exchangeCodeForToken(
        code: code,
        clientId: state.truelayerClientId,
        clientSecret: state.truelayerClientSecret,
        redirectUri: redirectUri,
        isSandbox: state.truelayerUseSandbox,
      );

      if (tokenData != null && tokenData['access_token'] != null) {
        final accessToken = tokenData['access_token'] as String;
        await setAccessToken(accessToken);
        await setBankConnected(true, 'Connecté via TrueLayer');
        return true;
      }
    } catch (e) {
      // Ignored for now
    }
    return false;
  }

  Future<void> disconnectBank() async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${userId}_bank_connected', false);
    await prefs.setString('${userId}_connected_bank_name', '');
    await SecureStorageService.clearTrueLayerTokens(userId);
    state = state.copyWith(
      bankConnected: false,
      connectedBankName: '',
      truelayerAccessToken: '',
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final authState = ref.watch(authProvider);
  return SettingsNotifier(userId: authState.user?.id ?? '');
});
