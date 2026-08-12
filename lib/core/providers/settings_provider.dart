import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/secure_storage_service.dart';

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
  SettingsNotifier()
      : super(SettingsState(
          languageCode: 'fr',
          bankConnected: false,
          connectedBankName: '',
          truelayerClientId: 'aurabudgetpro-f0ea54',
          truelayerClientSecret: '',
          truelayerAccessToken: '',
          truelayerUseSandbox: false,
        )) {
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language_code') ?? 'fr';
    final bankConnected = prefs.getBool('bank_connected') ?? false;
    final connectedBankName = prefs.getString('connected_bank_name') ?? '';
    final truelayerUseSandbox = prefs.getBool('truelayer_use_sandbox') ?? false;

    var clientId = await SecureStorageService.getTrueLayerClientId() ?? '';
    var clientSecret = await SecureStorageService.getTrueLayerClientSecret() ?? '';
    final accessToken = await SecureStorageService.getTrueLayerAccessToken() ?? '';

    // Auto-migration vers l'ID Live si ancien sandbox trouvé
    if (clientId.isEmpty || clientId == 'sandbox-aurabudgetpro-f0ea54') {
      clientId = 'aurabudgetpro-f0ea54';
      clientSecret = '';
      await SecureStorageService.saveTrueLayerCredentials(clientId, clientSecret);
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
        await SecureStorageService.saveTrueLayerCredentials(clientId, clientSecret);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', code);
    state = state.copyWith(languageCode: code);
  }

  Future<void> setSandboxMode(bool useSandbox) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('truelayer_use_sandbox', useSandbox);
    state = state.copyWith(truelayerUseSandbox: useSandbox);
  }

  Future<void> updateTrueLayerCredentials(String clientId, String clientSecret) async {
    await SecureStorageService.saveTrueLayerCredentials(clientId, clientSecret);
    state = state.copyWith(
      truelayerClientId: clientId,
      truelayerClientSecret: clientSecret,
    );
  }

  Future<void> setBankConnected(bool connected, String bankName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bank_connected', connected);
    await prefs.setString('connected_bank_name', bankName);
    state = state.copyWith(
      bankConnected: connected,
      connectedBankName: bankName,
    );
  }

  Future<void> setAccessToken(String token) async {
    await SecureStorageService.saveTrueLayerTokens(accessToken: token);
    state = state.copyWith(truelayerAccessToken: token);
  }

  Future<void> disconnectBank() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bank_connected', false);
    await prefs.setString('connected_bank_name', '');
    await SecureStorageService.clearTrueLayerTokens();
    state = state.copyWith(
      bankConnected: false,
      connectedBankName: '',
      truelayerAccessToken: '',
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
