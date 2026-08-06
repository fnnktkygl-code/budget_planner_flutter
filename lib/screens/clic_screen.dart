import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ClicScreen extends StatefulWidget {
  const ClicScreen({super.key});

  @override
  State<ClicScreen> createState() => _ClicScreenState();
}

class _ClicScreenState extends State<ClicScreen> {
  double _loanAmount = 200000;
  double _interestRate = 3.45;
  double _durationYears = 20;

  @override
  Widget build(BuildContext context) {
    final monthlyRate = _interestRate / 100 / 12;
    final numMonths = _durationYears * 12;
    final monthlyPayment = monthlyRate > 0
        ? (_loanAmount * monthlyRate) / (1 - (1 / ((1 + monthlyRate))))
        : _loanAmount / numMonths;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('CLIC — Comparateur de Financement', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simulateur de Crédit Immobilier & Conso', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Text('Montant emprunté : ${_loanAmount.toStringAsFixed(0)} €', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Slider(
              value: _loanAmount,
              min: 10000,
              max: 600000,
              divisions: 59,
              activeColor: AppColors.accentCyan,
              onChanged: (val) => setState(() => _loanAmount = val),
            ),

            Text('Taux d\'intérêt : ${_interestRate.toStringAsFixed(2)} %', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Slider(
              value: _interestRate,
              min: 0.5,
              max: 8.0,
              divisions: 150,
              activeColor: AppColors.accentCyan,
              onChanged: (val) => setState(() => _interestRate = val),
            ),

            Text('Durée : ${_durationYears.toStringAsFixed(0)} ans', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Slider(
              value: _durationYears,
              min: 5,
              max: 25,
              divisions: 20,
              activeColor: AppColors.accentCyan,
              onChanged: (val) => setState(() => _durationYears = val),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accentCyan)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MENSUALITÉ ESTIMÉE (HORS ASSURANCE)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${monthlyPayment.toStringAsFixed(0)} € / mois', style: const TextStyle(color: AppColors.accentCyan, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
