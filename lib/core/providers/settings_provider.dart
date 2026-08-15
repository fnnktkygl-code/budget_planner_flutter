import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/budget_category.dart';
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
  final List<Map<String, dynamic>> connectedAccounts;
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
    this.connectedAccounts = const [],
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
    List<Map<String, dynamic>>? connectedAccounts,
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
      connectedAccounts: connectedAccounts ?? this.connectedAccounts,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final String userId;
  final Ref ref;

  String _key(String base) => userId.isEmpty ? base : '${userId}_$base';

  SettingsNotifier({required this.userId, required this.ref})
      : super(SettingsState(
          languageCode: 'fr',
          bankConnected: false,
          connectedBankName: '',
          truelayerClientId: 'aurabudget-076e60',
          truelayerClientSecret: 'tlcs_live_93v3rjwgbbn4_UB8V1f3DirjKcNcGd3uQ0sYboJlBdbLpc1Bstac3rUN8',
          truelayerAccessToken: '',
          truelayerUseSandbox: false,
        )) {
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_key('app_language_code')) ?? 'fr';
    final bankConnected = prefs.getBool(_key('bank_connected')) ?? false;
    final connectedBankName = prefs.getString(_key('connected_bank_name')) ?? '';
    final primaryAccountId = prefs.getString(_key('primary_account_id'));
    final rawSyncTime = prefs.getString(_key('last_bank_sync'));
    final lastSyncTimestamp = rawSyncTime != null ? DateTime.tryParse(rawSyncTime) : null;

    List<Map<String, dynamic>> savedAccounts = [];
    final rawAccountsJson = prefs.getString(_key('connected_accounts_json'));
    if (rawAccountsJson != null && rawAccountsJson.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(rawAccountsJson);
        savedAccounts = parsed.map((a) => Map<String, dynamic>.from(a as Map)).toList();
      } catch (_) {}
    }

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
      await prefs.setBool(_key('truelayer_use_sandbox'), false);
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
      connectedAccounts: savedAccounts,
      lastSyncTimestamp: lastSyncTimestamp,
    );

    // Auto-sync if token is available
    if (accessToken.isNotEmpty) {
      _fetchAndApplyLiveBankData(accessToken);
    }
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('app_language_code'), code);
    state = state.copyWith(languageCode: code);
  }

  Future<void> setSandboxMode(bool useSandbox) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key('truelayer_use_sandbox'), useSandbox);
    state = state.copyWith(truelayerUseSandbox: useSandbox);
  }

  Future<void> updateTrueLayerCredentials(String clientId, String clientSecret) async {
    await SecureStorageService.saveTrueLayerCredentials(clientId, clientSecret, userId);
    state = state.copyWith(
      truelayerClientId: clientId,
      truelayerClientSecret: clientSecret,
    );
  }

  Future<void> setBankConnected(bool connected, String bankName, {String? accountId, List<Map<String, dynamic>>? accounts}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key('bank_connected'), connected);
    await prefs.setString(_key('connected_bank_name'), bankName);
    if (accountId != null) {
      await prefs.setString(_key('primary_account_id'), accountId);
    }
    if (accounts != null && accounts.isNotEmpty) {
      await prefs.setString(_key('connected_accounts_json'), jsonEncode(accounts));
    }
    final now = DateTime.now();
    await prefs.setString(_key('last_bank_sync'), now.toIso8601String());

    state = state.copyWith(
      bankConnected: connected,
      connectedBankName: bankName,
      primaryAccountId: accountId ?? state.primaryAccountId,
      connectedAccounts: accounts ?? state.connectedAccounts,
      lastSyncTimestamp: now,
    );
  }

  Future<void> selectPrimaryAccount(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('primary_account_id'), accountId);

    Map<String, dynamic>? selectedAcc;
    try {
      selectedAcc = state.connectedAccounts.firstWhere(
        (a) => a['account_id'] == accountId,
      );
    } catch (_) {}

    if (selectedAcc != null) {
      final bal = ((selectedAcc['current_balance'] ?? selectedAcc['balance']) as num?)?.toDouble() ?? 0.0;
      final name = (selectedAcc['display_name'] as String?) ?? state.connectedBankName;
      ref.read(salaryProvider.notifier).updateAccountBalance(
        bal,
        bankName: name,
        syncTime: DateTime.now(),
      );
      await prefs.setDouble(_key('aura_account_balance_v1'), bal);
      await prefs.setString(_key('aura_sync_bank_name_v1'), name);
    }

    state = state.copyWith(primaryAccountId: accountId);
  }

  Future<void> setAccessToken(String token) async {
    await SecureStorageService.saveTrueLayerTokens(accessToken: token, userId: userId);
    state = state.copyWith(truelayerAccessToken: token);
  }

  Future<String?> processTrueLayerCode(String code, {WidgetRef? ref}) async {
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
        try {
          final success = await _fetchAndApplyLiveBankData(accessToken);
          state = state.copyWith(isSyncing: false);
          if (!success) {
            return 'Connexion autorisée mais aucun compte BoursoBank n\'a été renvoyé par TrueLayer.';
          }
          return null; // Success (no error)
        } catch (fetchErr) {
          state = state.copyWith(isSyncing: false);
          final msg = fetchErr.toString().replaceAll('Exception: ', '');
          return msg;
        }
      } else {
        state = state.copyWith(isSyncing: false);
        final err = tokenData?['error_description'] ?? tokenData?['error'] ?? 'Échec de l\'échange de code TrueLayer';
        return 'Erreur token : $err';
      }
    } catch (e) {
      state = state.copyWith(isSyncing: false);
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<bool> syncTrueLayerData([WidgetRef? ref]) async {
    String token = state.truelayerAccessToken;
    if (token.isEmpty) {
      token = await SecureStorageService.getTrueLayerAccessToken(userId) ??
              await SecureStorageService.getTrueLayerAccessToken('') ?? '';
      if (token.isNotEmpty) {
        state = state.copyWith(truelayerAccessToken: token);
      }
    }
    if (token.isEmpty) return false;

    state = state.copyWith(isSyncing: true);
    try {
      final success = await _fetchAndApplyLiveBankData(token);
      state = state.copyWith(isSyncing: false);
      return success;
    } catch (e) {
      debugPrint('[SettingsNotifier] Sync exception: $e');
      state = state.copyWith(isSyncing: false);
      return false;
    }
  }

  Future<bool> _fetchAndApplyLiveBankData(String accessToken) async {
    try {
      debugPrint('[SettingsNotifier] Fetching live bank data with token...');
      // 1. Try unified summary via Vercel proxy first (Fastest & avoids CORS)
      final summary = await TrueLayerService.fetchSummary(
        accessToken: accessToken,
        isSandbox: state.truelayerUseSandbox,
      );

      if (summary != null && (summary['success'] == true || (summary['accounts'] as List?)?.isNotEmpty == true)) {
        final rawAccountsList = summary['accounts'] as List<dynamic>? ?? [];
        final rawAccounts = rawAccountsList.map((a) => Map<String, dynamic>.from(a as Map)).toList();
        final providerName = (summary['providerName'] as String?) ?? 'BoursoBank';
        final returnedPrimaryAccountId = (summary['primaryAccountId'] as String?) ?? '';
        final rawTxs = summary['transactions'] as List<dynamic>? ?? [];

        if (rawAccounts.isEmpty) {
          debugPrint('[SettingsNotifier] TrueLayer returned 0 accounts in summary.');
          throw Exception('Aucun compte BoursoBank n\'a été trouvé sur cette autorisation.');
        }

        // Check if user already had a selected primary account ID or use the smartly detected one
        final targetPrimaryId = state.primaryAccountId ?? returnedPrimaryAccountId;
        Map<String, dynamic>? selectedAcc;
        if (targetPrimaryId.isNotEmpty && rawAccounts.isNotEmpty) {
          selectedAcc = rawAccounts.firstWhere(
            (a) => a['account_id'] == targetPrimaryId,
            orElse: () => rawAccounts.first,
          );
        } else if (rawAccounts.isNotEmpty) {
          selectedAcc = rawAccounts.first;
        }

        final primaryBalance = selectedAcc != null
            ? ((selectedAcc['current_balance'] ?? selectedAcc['balance']) as num?)?.toDouble() ?? 0.0
            : ((summary['primaryCheckingBalance'] as num?)?.toDouble() ?? 0.0);
        final finalAccountId = selectedAcc != null ? (selectedAcc['account_id'] as String? ?? returnedPrimaryAccountId) : returnedPrimaryAccountId;
        final finalDisplayName = selectedAcc != null ? (selectedAcc['display_name'] as String? ?? providerName) : providerName;

        final List<TransactionItem> txs = [];
        for (final t in rawTxs) {
          try {
            final tMap = Map<String, dynamic>.from(t as Map);
            final amountVal = (tMap['amount'] as num?)?.toDouble() ?? 0.0;
            final isIncome = amountVal > 0;
            String catName = 'Général';
            final rawCat = tMap['transaction_classification'];
            if (rawCat is List && rawCat.isNotEmpty) {
              catName = rawCat.first.toString();
            } else if (rawCat is String && rawCat.isNotEmpty) {
              catName = rawCat;
            }

            txs.add(TransactionItem(
              id: (tMap['transaction_id'] ?? 'tx-${DateTime.now().millisecondsSinceEpoch}').toString(),
              title: (tMap['description'] ?? 'Transaction').toString(),
              amount: amountVal.abs(),
              date: DateTime.tryParse(tMap['timestamp']?.toString() ?? '') ?? DateTime.now(),
              category: catName,
              isIncome: isIncome,
            ));
          } catch (txErr) {
            debugPrint('[SettingsNotifier] Skipping malformed transaction: $txErr');
          }
        }

        // Update Riverpod salaryProvider and budgetProvider
        ref.read(salaryProvider.notifier).updateAccountBalance(
          primaryBalance,
          bankName: finalDisplayName,
          syncTime: DateTime.now(),
        );

        if (txs.isNotEmpty) {
          ref.read(budgetProvider.notifier).setTransactions(txs);
        }

        // Direct local storage persistence using consistent _key
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_key('aura_account_balance_v1'), primaryBalance);
        await prefs.setString(_key('aura_sync_bank_name_v1'), finalDisplayName);
        await prefs.setString(_key('aura_last_bank_sync_v1'), DateTime.now().toIso8601String());
        await prefs.setString(_key('connected_accounts_json'), jsonEncode(rawAccounts));

        await setBankConnected(true, finalDisplayName, accountId: finalAccountId, accounts: rawAccounts);
        debugPrint('[SettingsNotifier] Live Bank Data successfully applied: $primaryBalance EUR ($finalDisplayName, ${rawAccounts.length} accounts)');
        return true;
      }

      if (summary != null && summary['error'] != null) {
        debugPrint('[SettingsNotifier] Summary returned error: ${summary['error']}');
      }

      // 2. Fallback: individual account / balance calls
      final accounts = await TrueLayerService.fetchAccounts(
        accessToken: accessToken,
        isSandbox: state.truelayerUseSandbox,
      );

      if (accounts.isEmpty) {
        final err = (summary != null && summary['error'] != null)
            ? summary['error'].toString()
            : 'Aucun compte BoursoBank trouvé sur ce profil TrueLayer.';
        debugPrint('[SettingsNotifier] No accounts found: $err');
        throw Exception(err);
      }

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

      final effectiveBal = balance ?? ((mainAccount['current_balance'] ?? mainAccount['balance']) as num?)?.toDouble() ?? 0.0;
      ref.read(salaryProvider.notifier).updateAccountBalance(
        effectiveBal,
        bankName: providerName,
        syncTime: DateTime.now(),
      );

      if (accountId.isNotEmpty) {
        try {
          final txs = await TrueLayerService.fetchTransactions(
            accountId: accountId,
            accessToken: accessToken,
            isSandbox: state.truelayerUseSandbox,
          );
          if (txs.isNotEmpty) {
            ref.read(budgetProvider.notifier).setTransactions(txs);
          }
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key('aura_account_balance_v1'), effectiveBal);
      await prefs.setString(_key('aura_sync_bank_name_v1'), providerName);
      await prefs.setString(_key('aura_last_bank_sync_v1'), DateTime.now().toIso8601String());
      await prefs.setString(_key('connected_accounts_json'), jsonEncode(accounts));

      await setBankConnected(true, providerName, accountId: accountId, accounts: accounts);
      return true;
    } catch (e, stack) {
      debugPrint('[SettingsNotifier] Live bank fetch exception: $e\n$stack');
      rethrow;
    }
  }

  Future<void> disconnectBank() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key('bank_connected'), false);
    await prefs.setString(_key('connected_bank_name'), '');
    await prefs.remove(_key('primary_account_id'));
    await prefs.remove(_key('connected_accounts_json'));
    await prefs.remove(_key('last_bank_sync'));
    await SecureStorageService.clearTrueLayerTokens(userId);
    state = state.copyWith(
      bankConnected: false,
      connectedBankName: '',
      truelayerAccessToken: '',
      primaryAccountId: null,
      connectedAccounts: [],
      lastSyncTimestamp: null,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final authState = ref.watch(authProvider);
  return SettingsNotifier(userId: authState.user?.id ?? '', ref: ref);
});


