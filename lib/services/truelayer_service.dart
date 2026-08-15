import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/budget_category.dart';

class TrueLayerService {
  static String getAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    required bool isSandbox,
    String providerId = 'stet-boursorama',
  }) {
    final effectiveClientId = clientId.isEmpty ? 'aurabudget-076e60' : clientId;
    final effectiveIsSandbox = isSandbox || effectiveClientId.startsWith('sandbox-');
    final baseUrl = effectiveIsSandbox ? 'https://auth.truelayer-sandbox.com' : 'https://auth.truelayer.com';
    final scope = Uri.encodeComponent('info accounts balance transactions offline_access');
    final encodedRedirect = Uri.encodeComponent(redirectUri);
    var url = '$baseUrl/?response_type=code&client_id=$effectiveClientId&redirect_uri=$encodedRedirect&scope=$scope&country_code=FR&providers=$providerId&provider_id=$providerId';
    if (effectiveIsSandbox) {
      url += '&enable_mock=true';
    }
    debugPrint('[TrueLayer Service] Auth URL: $url');
    return url;
  }

  static Future<Map<String, dynamic>?> exchangeCodeForToken({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    required bool isSandbox,
  }) async {
    // Fallback to Live secret for Aura Budget if empty (due to secure storage / asset loading issues on web)
    final effectiveClientSecret = clientSecret.isEmpty 
        ? 'tlcs_live_93v3rjwgbbn4_UB8V1f3DirjKcNcGd3uQ0sYboJlBdbLpc1Bstac3rUN8'
        : clientSecret;

    final effectiveClientId = clientId.isEmpty
        ? 'aurabudget-076e60'
        : clientId;

    // Call our own Vercel API route to bypass CORS
    final proxyUrl = Uri.parse('${Uri.base.origin}/api/truelayer-token');

    debugPrint('[TrueLayer API] Exchanging code via proxy: $proxyUrl (ClientId: $effectiveClientId)');
    try {
      final response = await http.post(
        proxyUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'client_id': effectiveClientId,
          'client_secret': effectiveClientSecret,
          'redirect_uri': redirectUri,
          'code': code,
          'is_sandbox': (isSandbox || effectiveClientId.contains('sandbox')).toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[TrueLayer API] Token Exchange Success!');
        return data;
      } else {
        debugPrint('[TrueLayer API] Token Exchange Error ${response.statusCode}: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Exception during token exchange: $e');
      throw Exception('Exception: $e');
    }
  }

  /// Fetches unified summary (accounts, balance, transactions) via Vercel proxy to bypass browser CORS
  static Future<Map<String, dynamic>?> fetchSummary({
    required String accessToken,
    required bool isSandbox,
  }) async {
    final proxyUrl = Uri.parse('${Uri.base.origin}/api/truelayer-data?action=summary');
    debugPrint('[TrueLayer API] Fetching summary via proxy: $proxyUrl');

    try {
      final response = await http.post(
        proxyUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'action': 'summary',
          'accessToken': accessToken,
          'isSandbox': isSandbox,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[TrueLayer API] Summary response: success=${data['success']}, ${data['accounts']?.length ?? 0} accounts found');
        return Map<String, dynamic>.from(data);
      } else {
        Map<String, dynamic>? errJson;
        try {
          errJson = jsonDecode(response.body);
        } catch (_) {}
        final errMessage = errJson?['error'] ?? errJson?['details'] ?? 'HTTP ${response.statusCode}: ${response.body}';
        debugPrint('[TrueLayer API] Summary Proxy Error ${response.statusCode}: $errMessage');
        return {
          'success': false,
          'error': errMessage,
          'details': errJson?['details'],
        };
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Summary Proxy Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Fetches user accounts from TrueLayer Data API.
  static Future<List<Map<String, dynamic>>> fetchAccounts({
    required String accessToken,
    required bool isSandbox,
  }) async {
    // 1. Try Vercel proxy first (Web CORS bypass)
    final proxyUrl = Uri.parse('${Uri.base.origin}/api/truelayer-data?action=accounts');
    try {
      final response = await http.post(
        proxyUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'action': 'accounts',
          'accessToken': accessToken,
          'isSandbox': isSandbox,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? data['accounts'] ?? [];
        return results.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Accounts Proxy Exception: $e');
    }

    // 2. Fallback direct call (for Native Mobile/Desktop)
    final baseUrl = isSandbox ? 'https://api.truelayer-sandbox.com' : 'https://api.truelayer.com';
    final url = Uri.parse('$baseUrl/data/v1/accounts');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.cast<Map<String, dynamic>>();
      } else {
        debugPrint('[TrueLayer API] Accounts Direct Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Accounts Direct Exception: $e');
      return [];
    }
  }

  /// Fetches the real-time balance for a given account.
  static Future<double?> fetchBalance({
    required String accountId,
    required String accessToken,
    required bool isSandbox,
  }) async {
    // 1. Try Vercel proxy first (Web CORS bypass)
    final proxyUrl = Uri.parse('${Uri.base.origin}/api/truelayer-data?action=balance');
    try {
      final response = await http.post(
        proxyUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'action': 'balance',
          'accountId': accountId,
          'accessToken': accessToken,
          'isSandbox': isSandbox,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        if (results.isNotEmpty) {
          final balanceData = results.first;
          final balance = (balanceData['available'] as num?)?.toDouble() ?? 
                          (balanceData['current'] as num?)?.toDouble();
          return balance;
        }
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Balance Proxy Exception: $e');
    }

    // 2. Fallback direct call
    final baseUrl = isSandbox ? 'https://api.truelayer-sandbox.com' : 'https://api.truelayer.com';
    final url = Uri.parse('$baseUrl/data/v1/accounts/$accountId/balance');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        if (results.isNotEmpty) {
          final balanceData = results.first;
          final balance = (balanceData['available'] as num?)?.toDouble() ?? 
                          (balanceData['current'] as num?)?.toDouble();
          return balance;
        }
      } else {
        debugPrint('[TrueLayer API] Balance Direct Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Balance Direct Exception: $e');
    }
    return null;
  }

  /// Fetches recent transactions for a given account.
  static Future<List<TransactionItem>> fetchTransactions({
    required String accountId,
    required String accessToken,
    required bool isSandbox,
  }) async {
    // 1. Try Vercel proxy first (Web CORS bypass)
    final proxyUrl = Uri.parse('${Uri.base.origin}/api/truelayer-data?action=transactions');
    try {
      final response = await http.post(
        proxyUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'action': 'transactions',
          'accountId': accountId,
          'accessToken': accessToken,
          'isSandbox': isSandbox,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        return results.map((t) {
          final amountVal = (t['amount'] as num?)?.toDouble() ?? 0.0;
          final isIncome = amountVal > 0;
          return TransactionItem(
            id: t['transaction_id'] ?? 'tx-${DateTime.now().millisecondsSinceEpoch}',
            title: t['description'] ?? 'Transaction',
            amount: amountVal.abs(),
            date: DateTime.tryParse(t['timestamp'] ?? '') ?? DateTime.now(),
            category: (t['transaction_classification'] as List<dynamic>?)?.first ?? 'Général',
            isIncome: isIncome,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Transactions Proxy Exception: $e');
    }

    // 2. Fallback direct call
    final baseUrl = isSandbox ? 'https://api.truelayer-sandbox.com' : 'https://api.truelayer.com';
    final url = Uri.parse('$baseUrl/data/v1/accounts/$accountId/transactions');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        return results.map((t) {
          final amountVal = (t['amount'] as num?)?.toDouble() ?? 0.0;
          final isIncome = amountVal > 0;
          return TransactionItem(
            id: t['transaction_id'] ?? 'tx-${DateTime.now().millisecondsSinceEpoch}',
            title: t['description'] ?? 'Transaction',
            amount: amountVal.abs(),
            date: DateTime.tryParse(t['timestamp'] ?? '') ?? DateTime.now(),
            category: (t['transaction_classification'] as List<dynamic>?)?.first ?? 'Général',
            isIncome: isIncome,
          );
        }).toList();
      } else {
        debugPrint('[TrueLayer API] Transactions Direct Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Transactions Direct Exception: $e');
      return [];
    }
  }
}

