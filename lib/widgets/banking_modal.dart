import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/salary_provider.dart';
import '../services/truelayer_service.dart';

class BankingModalContent extends ConsumerStatefulWidget {
  const BankingModalContent({super.key});

  @override
  ConsumerState<BankingModalContent> createState() => _BankingModalContentState();
}

class _BankingModalContentState extends ConsumerState<BankingModalContent> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _connectBoursoBank() async {
    final settings = ref.read(settingsProvider);
    final redirectUri = Uri.base.origin;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Force Live mode with BoursoBank provider ID
      final authUrl = TrueLayerService.getAuthorizationUrl(
        clientId: settings.truelayerClientId.isNotEmpty ? settings.truelayerClientId : 'aurabudget-076e60',
        redirectUri: redirectUri,
        isSandbox: false,
        providerId: 'stet-boursorama',
      );

      final uri = Uri.parse(authUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          webOnlyWindowName: '_self', // Direct redirect in same tab for seamless OAuth flow
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible d\'ouvrir la page d\'authentification BoursoBank.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors de la redirection : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final salary = ref.watch(salaryProvider);

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: AppColors.accentCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Connexion BoursoBank',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Open Banking Live — TrueLayer Secure',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (settings.bankConnected) ...[
            // Connected Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.connectedBankName.isNotEmpty ? settings.connectedBankName : 'BoursoBank Connecté',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Solde actif : ${salary.accountBalance.toStringAsFixed(2)} €',
                              style: const TextStyle(color: AppColors.accentEmerald, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // If multiple accounts are detected, display the list
                  if (settings.connectedAccounts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    const SizedBox(height: 12),
                    const Text(
                      'COMPTES BOURSOBANK DÉTECTÉS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...settings.connectedAccounts.map((acc) {
                      final accId = acc['account_id'] as String? ?? '';
                      final isSelected = (accId == settings.primaryAccountId) ||
                          (settings.primaryAccountId == null && acc == settings.connectedAccounts.first);
                      final displayName = acc['display_name'] as String? ?? 'Compte';
                      final ibanMasked = acc['iban_masked'] as String? ?? '';
                      final bal = ((acc['current_balance'] ?? acc['balance']) as num?)?.toDouble() ?? 0.0;
                      final cat = acc['category'] as String? ?? 'checking';

                      String catBadge = 'Compte';
                      Color catColor = AppColors.accentCyan;
                      IconData catIcon = Icons.account_balance_wallet_outlined;

                      if (cat == 'tampon' || displayName.toLowerCase().contains('tampon') || ibanMasked.contains('4455')) {
                        catBadge = 'Tampon';
                        catColor = AppColors.accentPurple;
                        catIcon = Icons.archive_outlined;
                      } else if (cat == 'tontine' || displayName.toLowerCase().contains('tontine') || ibanMasked.contains('4424')) {
                        catBadge = 'Tontine';
                        catColor = AppColors.accentGold;
                        catIcon = Icons.handshake_outlined;
                      } else if (cat == 'savings' || displayName.toLowerCase().contains('livret')) {
                        catBadge = 'Épargne';
                        catColor = AppColors.accentEmerald;
                        catIcon = Icons.savings_outlined;
                      } else if (cat == 'checking' || ibanMasked.contains('0429')) {
                        catBadge = 'Courant';
                        catColor = AppColors.accentCyan;
                        catIcon = Icons.credit_card_rounded;
                      }

                      return InkWell(
                        onTap: () {
                          if (accId.isNotEmpty) {
                            ref.read(settingsProvider.notifier).selectPrimaryAccount(accId);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentCyan.withValues(alpha: 0.12)
                                : AppColors.surfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.accentCyan : AppColors.borderSubtle.withValues(alpha: 0.5),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(catIcon, size: 18, color: catColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (ibanMasked.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            ibanMasked,
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        catBadge,
                                        style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${bal.toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      color: isSelected ? AppColors.accentCyan : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Text(
                                      'Actif (Dashboard)',
                                      style: TextStyle(color: AppColors.accentEmerald, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text('Actualiser le solde', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref.read(settingsProvider.notifier).syncTrueLayerData(ref);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentCyan,
                          side: BorderSide(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _connectBoursoBank,
                        child: const Text('Re-connecter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger.withValues(alpha: 0.8)),
                      icon: const Icon(Icons.link_off_rounded, size: 14),
                      label: const Text('Déconnecter la banque', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        await ref.read(settingsProvider.notifier).disconnectBank();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Direct Connect BoursoBank Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🏦', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'BoursoBank (Compte Courant)',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Synchronisation sécurisée en direct',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'En connectant votre compte BoursoBank :',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureBullet('Récupération automatique de votre solde réel de compte courant'),
                  _buildFeatureBullet('Calcul dynamique du reste à vivre et de votre seuil de sécurité'),
                  _buildFeatureBullet('Sécurité certifiée Open Banking (ACPR / Banque de France)'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bolt_rounded, size: 20),
                      label: Text(
                        _isLoading ? 'Redirection en cours...' : 'Se connecter à BoursoBank',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isLoading ? null : _connectBoursoBank,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, color: AppColors.accentEmerald, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
