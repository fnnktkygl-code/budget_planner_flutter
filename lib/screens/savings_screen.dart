import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';
import '../core/providers/bonus_provider.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  IconData _getIconData(String name) {
    switch (name) {
      case 'target':
        return Icons.radar_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'trending':
        return Icons.trending_up_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'banknote':
        return Icons.payments_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'business':
        return Icons.business_center_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  void _showAddEventModal() {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'gift';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ajouter un revenu exceptionnel',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Libellé (ex: Prime, Tontine)',
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderSubtle)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentCyan)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Montant (€)',
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderSubtle)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentCyan)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Type de revenu', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTypeChoice('gift', Icons.card_giftcard_rounded, type, () => setModalState(() => type = 'gift')),
                      const SizedBox(width: 12),
                      _buildTypeChoice('banknote', Icons.payments_rounded, type, () => setModalState(() => type = 'banknote')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final label = labelCtrl.text.trim();
                        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        if (label.isNotEmpty && amount > 0) {
                          ref.read(bonusProvider.notifier).addPendingEvent(
                                label: label,
                                amount: amount,
                                date: DateTime.now(),
                                type: type,
                              );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Ajouter au bucket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChoice(String id, IconData icon, String selected, VoidCallback onTap) {
    final isSelected = id == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.accentCyan : AppColors.borderSubtle),
        ),
        child: Icon(icon, color: isSelected ? AppColors.accentCyan : AppColors.textSecondary),
      ),
    );
  }

  void _showAddDestinationModal() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nouvelle Destination', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Ex: Crypto, Voyage...',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  ref.read(bonusProvider.notifier).addDestination(nameCtrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPeeModal() {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ajouter Intéressement / PEE',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Libellé (ex: Intéressement 2026)',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderSubtle)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentGold)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.accentGold, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Montant (€)',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderSubtle)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentGold)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final label = labelCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                    if (label.isNotEmpty && amount > 0) {
                      ref.read(bonusProvider.notifier).addPeeAmount(
                            label: label,
                            amount: amount,
                            date: DateTime.now(),
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Ajouter au PEE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showVentilateModal(List<BonusEvent> pendingEvents, List<BonusDestination> destinations) {
    if (destinations.isEmpty) return;

    final totalPending = pendingEvents.fold(0.0, (s, e) => s + e.amount);
    final eventIds = pendingEvents.map((e) => e.id).toList();

    Map<String, double> allocations = {
      for (var d in destinations) d.id: 0.0
    };
    allocations[destinations.first.id] = 100.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ventiler les revenus',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant à ventiler :', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        Text(
                          _currencyFormat.format(totalPending),
                          style: const TextStyle(color: AppColors.accentCyan, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Répartition (%)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: destinations.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 16),
                      itemBuilder: (c, i) {
                        final dest = destinations[i];
                        final pct = allocations[dest.id] ?? 0.0;
                        final amount = totalPending * pct / 100;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(_getIconData(dest.iconName), color: dest.color, size: 18),
                                    const SizedBox(width: 8),
                                    Text(dest.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('${pct.round()}%', style: TextStyle(color: dest.color, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text(_currencyFormat.format(amount), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            Slider(
                              value: pct,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: dest.color,
                              inactiveColor: AppColors.borderSubtle,
                              onChanged: (val) {
                                setModalState(() {
                                  allocations[dest.id] = val;
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final totalPct = allocations.values.fold(0.0, (s, p) => s + p);
                      final isExact = (totalPct - 100).abs() < 1;
                      return Column(
                        children: [
                          if (!isExact)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Total actuel : ${totalPct.round()}% (doit être 100%)',
                                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isExact ? AppColors.accentCyan : AppColors.cardBackground,
                                foregroundColor: isExact ? Colors.white : AppColors.textMuted,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: isExact
                                  ? () {
                                      ref.read(bonusProvider.notifier).ventilate(eventIds, allocations);
                                      Navigator.pop(ctx);
                                    }
                                  : null,
                              child: const Text('Valider la ventilation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bonusState = ref.watch(bonusProvider);
    final pendingEvents = bonusState.pending;
    final totalPending = pendingEvents.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Entonnoir d\'Épargne',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REVENUS EXCEPTIONNELS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // Pending Bucket (Matches Screenshot)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.hourglass_empty_rounded, color: AppColors.accentCyan, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'En attente de ventilation',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary, size: 20),
                        onPressed: _showAddEventModal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _currencyFormat.format(totalPending),
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('Ventiler vers les comptes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: totalPending > 0 ? () => _showVentilateModal(pendingEvents, bonusState.destinations) : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Destinations Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DESTINATIONS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: _showAddDestinationModal,
                  child: Row(
                    children: const [
                      Icon(Icons.add_rounded, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text('Ajouter', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Destinations Grid (Matches Screenshot: Icon top-left, close top-right, title/amount bottom-left)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: bonusState.destinations.length,
              itemBuilder: (context, index) {
                final dest = bonusState.destinations[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(_getIconData(dest.iconName), color: dest.color, size: 18),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                            onPressed: () => ref.read(bonusProvider.notifier).removeDestination(dest.id),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dest.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            _currencyFormat.format(dest.total),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // PEE Block (Matches Screenshot)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.business_center_rounded, color: AppColors.accentGold, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Épargne Salariale (PEE/PERCO)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Exonéré IR', style: TextStyle(color: AppColors.accentEmerald, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Saisissez manuellement vos intéressements et participations qui ne transitent pas par le compte courant.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cumul total', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormat.format(bonusState.peeTotal),
                              style: const TextStyle(color: AppColors.accentGold, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGold.withValues(alpha: 0.15),
                            foregroundColor: AppColors.accentGold,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: _showAddPeeModal,
                        ),
                      ],
                    ),
                  ),
                  if (bonusState.peeEvents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    const SizedBox(height: 12),
                    const Text('Historique des versements PEE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...bonusState.peeEvents.map((ev) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_dateFormat.format(ev.date)} - ${ev.label}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Text('+ ${_currencyFormat.format(ev.amount)}', style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 32),

            // History
            const Text(
              'HISTORIQUE DE L\'ENTONNOIR',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            if (bonusState.history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Aucun événement ventilé pour le moment.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bonusState.history.length,
                separatorBuilder: (c, i) => const Divider(color: AppColors.borderSubtle, height: 1),
                itemBuilder: (context, index) {
                  final ev = bonusState.history[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getIconData(ev.iconName), color: AppColors.textSecondary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev.label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(_dateFormat.format(ev.date), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFormat.format(ev.amount),
                              style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: ev.breakdown.map((b) {
                                final d = bonusState.destinations.firstWhere((x) => x.id == b.destId, orElse: () => BonusDestination(id: '', name: 'Inconnu', iconName: '', color: Colors.grey, total: 0));
                                return Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: d.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Text('${b.pct.round()}% ${d.name}', style: TextStyle(color: d.color, fontSize: 8, fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
