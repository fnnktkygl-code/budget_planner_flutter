import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/budget_category.dart';

class TrueLayerService {
  static String getAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    required bool isSandbox,
    String? providerId,
  }) {
    final baseUrl = isSandbox ? 'https://auth.truelayer-sandbox.com' : 'https://auth.truelayer.com';
    final scope = Uri.encodeComponent('info accounts balance transactions offline_access');
    final encodedRedirect = Uri.encodeComponent(redirectUri);
    var url = '$baseUrl/?response_type=code&client_id=$clientId&redirect_uri=$encodedRedirect&scope=$scope';
    if (providerId != null && providerId.isNotEmpty) {
      url += '&provider_id=$providerId';
    }
    if (isSandbox) {
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
    // Fallback to hardcoded secret if empty (due to secure storage / asset loading issues on web)
    final effectiveClientSecret = clientSecret.isEmpty 
        ? '0bb238e2-27de-4cfa-a99f-eaeb0af46bc8'
        : clientSecret;

    // Call our own Vercel API route to bypass CORS
    final proxyUrl = Uri.parse('${Uri.base.origin}/api/truelayer-token');

    debugPrint('[TrueLayer API] Exchanging code via proxy: $proxyUrl');
    try {
      final response = await http.post(
        proxyUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': effectiveClientSecret,
          'redirect_uri': redirectUri,
          'code': code,
          'is_sandbox': (isSandbox || clientId.contains('-f0ea54') || clientId.contains('sandbox')).toString(),
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

  /// Fetches user accounts from TrueLayer Data API.
  static Future<List<Map<String, dynamic>>> fetchAccounts({
    required String accessToken,
    required bool isSandbox,
  }) async {
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
        debugPrint('[TrueLayer API] Accounts Fetch Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Accounts Exception: $e');
      return [];
    }
  }

  /// Fetches the real-time balance for a given account.
  static Future<double?> fetchBalance({
    required String accountId,
    required String accessToken,
    required bool isSandbox,
  }) async {
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
          // 'available' is the actual spendable money, 'current' includes pending txs.
          final balance = (balanceData['available'] as num?)?.toDouble() ?? 
                          (balanceData['current'] as num?)?.toDouble();
          return balance;
        }
      } else {
        debugPrint('[TrueLayer API] Balance Fetch Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Balance Exception: $e');
    }
    return null;
  }

  /// Fetches recent transactions for a given account.
  static Future<List<TransactionItem>> fetchTransactions({
    required String accountId,
    required String accessToken,
    required bool isSandbox,
  }) async {
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
          final amountVal = (t['amount'] as num).toDouble();
          final isIncome = amountVal > 0;
          return TransactionItem(
            id: t['transaction_id'] ?? 'tx-${DateTime.now().millisecondsSinceEpoch}',
            title: t['description'] ?? 'Transaction',
            amount: amountVal.abs(),
            date: DateTime.tryParse(t['timestamp'] ?? '') ?? DateTime.now(),
            category: t['transaction_classification']?.first ?? 'Général',
            isIncome: isIncome,
          );
        }).toList();
      } else {
        debugPrint('[TrueLayer API] Transactions Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[TrueLayer API] Transactions Exception: $e');
      return [];
    }
  }
}
