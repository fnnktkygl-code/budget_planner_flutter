import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/secure_storage_service.dart';
import '../../services/truelayer_service.dart';
import 'auth_provider.dart';
import 'salary_provider.dart';
import 'budget_provider.dart';

class SettingsState {
  final String languageCode;
  final bool bankConnected;
  final String connectedBankName;
  final String truelayerClientId;
  final String truelayerClientSecret;
  final String truelayerAccessToken;
  final bool truelayerUseSandbox;
  final String? primaryAccountId;
  final DateTime? lastSyncTimestamp;
  final bool isSyncing;

  SettingsState({
    required this.languageCode,
    required this.bankConnected,
    required this.connectedBankName,
    required this.truelayerClientId,
    required this.truelayerClientSecret,
    required this.truelayerAccessToken,
    required this.truelayerUseSandbox,
    this.primaryAccountId,
    this.lastSyncTimestamp,
    this.isSyncing = false,
  });

  SettingsState copyWith({
    String? languageCode,
    bool? bankConnected,
    String? connectedBankName,
    String? truelayerClientId,
    String? truelayerClientSecret,
    String? truelayerAccessToken,
    bool? truelayerUseSandbox,
    String? primaryAccountId,
    DateTime? lastSyncTimestamp,
    bool? isSyncing,
  }) {
    return SettingsState(
      languageCode: languageCode ?? this.languageCode,
      bankConnected: bankConnected ?? this.bankConnected,
      connectedBankName: connectedBankName ?? this.connectedBankName,
      truelayerClientId: truelayerClientId ?? this.truelayerClientId,
      truelayerClientSecret: truelayerClientSecret ?? this.truelayerClientSecret,
      truelayerAccessToken: truelayerAccessToken ?? this.truelayerAccessToken,
      truelayerUseSandbox: truelayerUseSandbox ?? this.truelayerUseSandbox,
      primaryAccountId: primaryAccountId ?? this.primaryAccountId,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      isSyncing: isSyncing ?? this.isSyncing,
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
          truelayerClientId: 'aurabudget-076e60',
          truelayerClientSecret: 'tlcs_live_93v3rjwgbbn4_UB8V1f3DirjKcNcGd3uQ0sYboJlBdbLpc1Bstac3rUN8',
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
    final primaryAccountId = prefs.getString('${userId}_primary_account_id');
    final rawSyncTime = prefs.getString('${userId}_last_bank_sync');
    final lastSyncTimestamp = rawSyncTime != null ? DateTime.tryParse(rawSyncTime) : null;

    var clientId = await SecureStorageService.getTrueLayerClientId(userId);
    if (clientId == null || clientId.isEmpty || clientId == 'aurabudgetpro-f0ea54') {
      clientId = 'aurabudget-076e60';
      await SecureStorageService.saveTrueLayerCredentials(clientId, 'tlcs_live_93v3rjwgbbn4_UB8V1f3DirjKcNcGd3uQ0sYboJlBdbLpc1Bstac3rUN8', userId);
    }

    var clientSecret = await SecureStorageService.getTrueLayerClientSecret(userId) ?? '';
    final accessToken = await SecureStorageService.getTrueLayerAccessToken(userId) ?? '';

    if (clientSecret.isEmpty || clientSecret.startsWith('0bb238e2')) {
      try {
        try {
          final loadedSecret = await rootBundle.loadString('assets/aurabudget-076e60-secret.txt');
          clientSecret = loadedSecret.trim();
        } catch (_) {
          clientSecret = 'tlcs_live_93v3rjwgbbn4_UB8V1f3DirjKcNcGd3uQ0sYboJlBdbLpc1Bstac3rUN8';
        }
        await SecureStorageService.saveTrueLayerCredentials(clientId, clientSecret, userId);
      } catch (_) {
        clientSecret = 'tlcs_live_93v3rjwgbbn4_UB8V1f3DirjKcNcGd3uQ0sYboJlBdbLpc1Bstac3rUN8';
      }
    }

    // Force Live mode for aurabudget-076e60 (clean stale test flags from localStorage)
    final truelayerUseSandbox = clientId.startsWith('sandbox-');
    if (!truelayerUseSandbox) {
      await prefs.setBool('${userId}_truelayer_use_sandbox', false);
    }

    state = SettingsState(
      languageCode: languageCode,
      bankConnected: bankConnected,
      connectedBankName: connectedBankName.isNotEmpty ? connectedBankName : 'BoursoBank',
      truelayerClientId: clientId,
      truelayerClientSecret: clientSecret,
      truelayerAccessToken: accessToken,
      truelayerUseSandbox: truelayerUseSandbox,
      primaryAccountId: primaryAccountId,
      lastSyncTimestamp: lastSyncTimestamp,
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

  Future<void> setBankConnected(bool connected, String bankName, {String? accountId}) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${userId}_bank_connected', connected);
    await prefs.setString('${userId}_connected_bank_name', bankName);
    if (accountId != null) {
      await prefs.setString('${userId}_primary_account_id', accountId);
    }
    final now = DateTime.now();
    await prefs.setString('${userId}_last_bank_sync', now.toIso8601String());

    state = state.copyWith(
      bankConnected: connected,
      connectedBankName: bankName,
      primaryAccountId: accountId ?? state.primaryAccountId,
      lastSyncTimestamp: now,
    );
  }

  Future<void> setAccessToken(String token) async {
    if (userId.isEmpty) return;
    await SecureStorageService.saveTrueLayerTokens(accessToken: token, userId: userId);
    state = state.copyWith(truelayerAccessToken: token);
  }

  Future<String?> processTrueLayerCode(String code, {WidgetRef? ref}) async {
    if (userId.isEmpty) return 'Utilisateur non connecté';
    final redirectUri = Uri.base.origin;
    state = state.copyWith(isSyncing: true);
    
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
        final refreshToken = tokenData['refresh_token'] as String?;
        await SecureStorageService.saveTrueLayerTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: userId,
        );
        state = state.copyWith(truelayerAccessToken: accessToken);

        // Fetch Accounts & Live Balance immediately
        await _fetchAndApplyLiveBankData(accessToken, ref: ref);

        state = state.copyWith(isSyncing: false);
        return null; // Success (no error)
      } else {
        state = state.copyWith(isSyncing: false);
        return 'Erreur inconnue lors de la récupération du token.';
      }
    } catch (e) {
      state = state.copyWith(isSyncing: false);
      return e.toString();
    }
  }

  Future<bool> syncTrueLayerData(WidgetRef ref) async {
    if (state.truelayerAccessToken.isEmpty) return false;
    state = state.copyWith(isSyncing: true);
    try {
      final success = await _fetchAndApplyLiveBankData(state.truelayerAccessToken, ref: ref);
      state = state.copyWith(isSyncing: false);
      return success;
    } catch (e) {
      debugPrint('[SettingsNotifier] Sync exception: $e');
      state = state.copyWith(isSyncing: false);
      return false;
    }
  }

  Future<bool> _fetchAndApplyLiveBankData(String accessToken, {WidgetRef? ref}) async {
    try {
      final accounts = await TrueLayerService.fetchAccounts(
        accessToken: accessToken,
        isSandbox: state.truelayerUseSandbox,
      );

      if (accounts.isEmpty) {
        await setBankConnected(true, 'Compte Connecté');
        return false;
      }

      // Prioritize checking account (TRANSACTION) or first account
      final mainAccount = accounts.firstWhere(
        (a) => (a['account_type'] == 'TRANSACTION') || (a['account_type'] == 'CURRENT'),
        orElse: () => accounts.first,
      );

      final accountId = mainAccount['account_id'] as String? ?? '';
      final providerName = (mainAccount['provider']?['display_name'] as String?) ??
                           (mainAccount['display_name'] as String?) ??
                           'BoursoBank';

      double? balance;
      if (accountId.isNotEmpty) {
        balance = await TrueLayerService.fetchBalance(
          accountId: accountId,
          accessToken: accessToken,
          isSandbox: state.truelayerUseSandbox,
        );
      }

      // If ref is available, update providers dynamically
      if (ref != null && balance != null) {
        ref.read(salaryProvider.notifier).updateAccountBalance(
          balance,
          bankName: providerName,
          syncTime: DateTime.now(),
        );

        // Fetch recent transactions
        if (accountId.isNotEmpty) {
          final txs = await TrueLayerService.fetchTransactions(
            accountId: accountId,
            accessToken: accessToken,
            isSandbox: state.truelayerUseSandbox,
          );
          if (txs.isNotEmpty) {
            ref.read(budgetProvider.notifier).setTransactions(txs);
          }
        }
      } else if (balance != null) {
        // Fallback save to SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('${userId}_aura_account_balance_v1', balance);
        await prefs.setString('${userId}_aura_sync_bank_name_v1', providerName);
        await prefs.setString('${userId}_aura_last_bank_sync_v1', DateTime.now().toIso8601String());
      }

      await setBankConnected(true, providerName, accountId: accountId);
      return true;
    } catch (e) {
      debugPrint('[SettingsNotifier] Live bank fetch error: $e');
      return false;
    }
  }

  Future<void> disconnectBank() async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${userId}_bank_connected', false);
    await prefs.setString('${userId}_connected_bank_name', '');
    await prefs.remove('${userId}_primary_account_id');
    await prefs.remove('${userId}_last_bank_sync');
    await SecureStorageService.clearTrueLayerTokens(userId);
    state = state.copyWith(
      bankConnected: false,
      connectedBankName: '',
      truelayerAccessToken: '',
      primaryAccountId: null,
      lastSyncTimestamp: null,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final authState = ref.watch(authProvider);
  return SettingsNotifier(userId: authState.user?.id ?? '');
});

