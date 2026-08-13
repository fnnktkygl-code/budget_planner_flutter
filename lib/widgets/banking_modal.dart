import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/settings_provider.dart';
import '../services/truelayer_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BankingModalContent extends ConsumerStatefulWidget {
  const BankingModalContent({super.key});

  @override
  ConsumerState<BankingModalContent> createState() => _BankingModalContentState();
}

class _BankingModalContentState extends ConsumerState<BankingModalContent> {
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _banks = [
    {'name': 'BoursoBank', 'id': 'stet-boursorama', 'icon': '🏦'},
    {'name': 'BNP Paribas', 'id': 'stet-bnp', 'icon': '🏛️'},
    {'name': 'Crédit Agricole', 'id': 'stet-ca', 'icon': '🌾'},
    {'name': 'Société Générale', 'id': 'stet-sg', 'icon': '🔴'},
    {'name': 'Revolut', 'id': 'revolut', 'icon': '💳'},
    {'name': 'Mock Bank (Sandbox Test)', 'id': 'mock-bank', 'icon': '🧪'},
  ];

  Future<void> _connectBank(String bankName, String bankId) async {
    final settings = ref.read(settingsProvider);
    // Dynamically use the current web origin if running on Web, fallback to a deep link scheme for mobile
    final redirectUri = Uri.base.origin; // Will resolve to https://aurabudgetpro.vercel.app on Vercel

    try {
      final authUrl = TrueLayerService.getAuthorizationUrl(
        clientId: settings.truelayerClientId,
        redirectUri: redirectUri,
        isSandbox: settings.truelayerUseSandbox,
      );

      final uri = Uri.parse(authUrl);
      
      // Save the selected bank name and ID in SharedPreferences or just pass it as state in the TrueLayer URL if possible.
      // TrueLayer doesn't let us pass custom state easily without validating it, but we'll assume the connected bank when they return.
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          webOnlyWindowName: '_self', // Open in the same window so redirect flow works naturally
        );
      } else {
        setState(() {
          _errorMessage = 'Impossible d\'ouvrir le lien TrueLayer.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la redirection : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connexion Bancaire Secure', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('TrueLayer Open Banking — ${settings.truelayerUseSandbox ? 'Mode Sandbox' : 'Mode Live'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
            const SizedBox(height: 14),
          ],

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentCyan),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              itemCount: _banks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final bank = _banks[idx];
                return ListTile(
                  tileColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Text(bank['icon']!, style: const TextStyle(fontSize: 24)),
                  title: Text(bank['name']!, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _connectBank(bank['name']!, bank['id']!),
                );
              },
            ),
        ],
      ),
    );
  }
}
