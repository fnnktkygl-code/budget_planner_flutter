import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';
import '../core/providers/bonus_provider.dart';
import '../widgets/dashed_border_painter.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  final _dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');

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
                        'Ajouter un revenu',
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
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentGold)),
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
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentGold)),
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
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.black,
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
                      child: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          color: isSelected ? AppColors.accentGold.withValues(alpha: 0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.accentGold : AppColors.borderSubtle),
        ),
        child: Icon(icon, color: isSelected ? AppColors.accentGold : AppColors.textSecondary),
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
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black,
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
                    'Ajouter PEE / PERCO',
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
                      color: AppColors.accentGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant à ventiler :', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        Text(
                          _currencyFormat.format(totalPending),
                          style: const TextStyle(color: AppColors.accentGold, fontSize: 20, fontWeight: FontWeight.bold),
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
                                backgroundColor: isExact ? AppColors.accentGold : AppColors.cardBackground,
                                foregroundColor: isExact ? Colors.black : AppColors.textMuted,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Revenus exceptionnels',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.schedule_rounded, color: AppColors.textMuted, size: 12),
                        SizedBox(width: 6),
                        Text(
                          'Hors répartition mensuelle',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Primes, bonus, tontine — tout ce qui n\'est pas votre salaire courant',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // PENDING BUCKET CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    // Graphic Circle
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(alpha: 0.5),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(45)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome_rounded, color: AppColors.accentGold, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'En attente de ventilation',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(totalPending),
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pendingEvents.length} revenus non répartis${pendingEvents.isNotEmpty ? ' - dernier : ${pendingEvents.first.label}' : ''}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentGold,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: totalPending > 0 ? () => _showVentilateModal(pendingEvents, bonusState.destinations) : null,
                                child: Row(
                                  children: const [
                                    Text('Ventiler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    SizedBox(width: 6),
                                    Icon(Icons.check_rounded, size: 16),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.borderSubtle),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Ajouter un revenu', style: TextStyle(fontSize: 13)),
                                onPressed: _showAddEventModal,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // CUMUL INVESTI VIA PRIMES
              const Text(
                'CUMUL INVESTI VIA PRIMES',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    ...bonusState.destinations.map((dest) {
                      return Container(
                        width: 140,
                        height: 140,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: dest.color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getIconData(dest.iconName), color: dest.color, size: 20),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMuted),
                                  onPressed: () => ref.read(bonusProvider.notifier).removeDestination(dest.id),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dest.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  _currencyFormat.format(dest.total),
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    // Ajouter une destination
                    GestureDetector(
                      onTap: _showAddDestinationModal,
                      child: CustomPaint(
                        painter: DashedBorderPainter(color: AppColors.textMuted, radius: 20, strokeWidth: 1.5, dashWidth: 6, dashSpace: 4),
                        child: Container(
                          width: 140,
                          height: 140,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add_rounded, color: AppColors.textMuted, size: 18),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Ajouter une\ndestination',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // HISTORIQUE DES EVENEMENTS
              const Text(
                'HISTORIQUE DES ÉVÉNEMENTS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              if (bonusState.events.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Center(
                    child: Text('Aucun événement pour le moment.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bonusState.events.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ev = bonusState.events[index];
                    final isPending = !ev.isVentilated;

                    String breakdownText = '';
                    if (!isPending && ev.breakdown.isNotEmpty) {
                      breakdownText = ev.breakdown.map((b) {
                        final d = bonusState.destinations.firstWhere(
                          (x) => x.id == b.destId,
                          orElse: () => BonusDestination(id: '', name: 'Inconnu', iconName: '', color: Colors.grey, total: 0),
                        );
                        return '${b.pct.round()}% ${d.name}';
                      }).join(' • ');
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPending ? AppColors.accentGold.withValues(alpha: 0.15) : AppColors.cardBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconData(ev.iconName),
                              color: isPending ? AppColors.accentGold : AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ev.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(_dateFormat.format(ev.date), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    if (!isPending && breakdownText.isNotEmpty) ...[
                                      const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                      Expanded(
                                        child: Text(
                                          breakdownText,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currencyFormat.format(ev.amount),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending ? AppColors.accentGold.withValues(alpha: 0.15) : AppColors.accentEmerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isPending ? 'En attente' : 'Ventilé',
                                  style: TextStyle(
                                    color: isPending ? AppColors.accentGold : AppColors.accentEmerald,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),

              // PEE BLOCK
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
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
                            Icon(Icons.business_center_rounded, color: AppColors.accentGold, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Épargne Salariale (PEE / PERCO)',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Exonéré IR', style: TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'L\'intéressement et la participation versés directement sur votre PEE ne transitent pas par votre compte bancaire mais constituent une réserve de valeur majeure.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Cumul Intéressement & Participation PEE :', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Text(_currencyFormat.format(bonusState.peeTotal), style: const TextStyle(color: AppColors.accentGold, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showAddPeeModal,
                          icon: const Icon(Icons.add_rounded, color: AppColors.accentGold, size: 18),
                          label: const Text('Ajouter manuellement', style: TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
