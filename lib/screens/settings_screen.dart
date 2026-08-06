import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _clientIdController = TextEditingController(text: settings.truelayerClientId);
    _clientSecretController = TextEditingController(text: settings.truelayerClientSecret);
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Paramètres & Configuration', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Utilisateur Connecté
            if (authState.user != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accentCyan.withValues(alpha: 0.2),
                      radius: 22,
                      child: Text(
                        (authState.user!.displayName)[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(authState.user!.displayName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(authState.user!.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                      tooltip: 'Se déconnecter',
                      onPressed: () => ref.read(authProvider.notifier).signOut(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text('Configuration TrueLayer Open Banking', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Environnement Sandbox (Test)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Utiliser les banques de test TrueLayer (Mock Bank). Désactivez pour les vraies banques comme BoursoBank.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    value: settings.truelayerUseSandbox,
                    activeThumbColor: AppColors.accentCyan,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setSandboxMode(val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientIdController,
                    decoration: const InputDecoration(labelText: 'TrueLayer Client ID', border: OutlineInputBorder()),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientSecretController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'TrueLayer Client Secret', border: OutlineInputBorder()),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan, foregroundColor: AppColors.background),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Enregistrer les identifiants'),
                      onPressed: () {
                        ref.read(settingsProvider.notifier).updateTrueLayerCredentials(
                              _clientIdController.text.trim(),
                              _clientSecretController.text.trim(),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Identifiants TrueLayer mis à jour avec succès !'), backgroundColor: AppColors.accentEmerald),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Préférences de l\'Application', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Langue d\'affichage', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(settings.languageCode == 'fr' ? 'Français' : 'English', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                trailing: DropdownButton<String>(
                  value: settings.languageCode,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'fr', child: Text('Français (FR)')),
                    DropdownMenuItem(value: 'en', child: Text('English (EN)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).setLanguage(val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
