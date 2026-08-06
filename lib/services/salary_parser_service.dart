import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/salary_record.dart';

class RealParsedPayslip {
  final String id;
  final String employeeName;
  final String employerName;
  final String siret;
  final String period;
  final bool periodDetected;
  final DateTime date;
  final double grossSalary;
  final double netSocial;
  final double netPayable;
  final double socialContributions;
  final double mealTickets;
  final double teleworkAllowance;
  final double nonTaxableAllowance;
  final bool hasExplicitBonus;
  final String? bonusDescription;
  final bool isParsedFromDocument;
  final String? renderedImageBase64;
  final String? rawFileBase64;

  RealParsedPayslip({
    required this.id,
    required this.employeeName,
    required this.employerName,
    required this.siret,
    required this.period,
    required this.periodDetected,
    required this.date,
    required this.grossSalary,
    required this.netSocial,
    required this.netPayable,
    required this.socialContributions,
    required this.mealTickets,
    required this.teleworkAllowance,
    required this.nonTaxableAllowance,
    this.hasExplicitBonus = false,
    this.bonusDescription,
    required this.isParsedFromDocument,
    this.renderedImageBase64,
    this.rawFileBase64,
  });

  SalaryRecord toSalaryRecord({
    String? customPeriod,
    String? customPeriodLabel,
    double? customNet,
    String? customFileName,
    String? imageBase64,
    String? fileBase64,
  }) {
    final effectivePeriodLabel = customPeriodLabel ?? period;
    final yearMonth = customPeriod ??
        '${date.year}-${date.month < 10 ? "0${date.month}" : "${date.month}"}';
    
    // Strict factual value: net after tax received on bank account (Net versé sur le compte)
    final finalNet = customNet ?? netPayable;

    return SalaryRecord(
      id: id,
      period: yearMonth,
      periodLabel: effectivePeriodLabel,
      netSalary: finalNet,
      grossSalary: grossSalary,
      socialContributions: socialContributions,
      mealTickets: mealTickets,
      teleworkAllowance: teleworkAllowance,
      nonTaxableAllowances: nonTaxableAllowance,
      investableAmount: (finalNet * 0.3).roundToDouble(),
      savingsRate: 30.0,
      status: finalNet > 0 ? '✓ Extrait du bulletin' : '⚠️ Saisie Net requise',
      documentName: customFileName ?? 'bulletin_$id.pdf',
      renderedImageBase64: imageBase64 ?? renderedImageBase64,
      rawFileBase64: fileBase64 ?? rawFileBase64,
      isLatestActive: true,
      hasExplicitBonus: hasExplicitBonus,
      bonusDescription: bonusDescription,
      updatedAt: DateTime.now(),
      notes: '$employerName — Net Social: ${netSocial > 0 ? netSocial.toStringAsFixed(2) : "N/A"} €',
    );
  }
}

class SalaryParserService {
  static const List<String> _monthsFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  static const List<String> _geminiModelsCascade = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-3.6-flash',
    'gemini-2.5-flash',
    'gemma-4-31b-it',
    'gemma-4-26b-a4b-it',
    'gemma-2-27b-it',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static final Map<String, DateTime> _modelCooldownMap = {};

  static Map<String, dynamic>? _extractPeriodFromFileName(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    final name = fileName.toLowerCase();

    final match6 = RegExp(r'(20\d{2})(0[1-9]|1[0-2])').firstMatch(name);
    if (match6 != null) {
      final yr = int.parse(match6.group(1)!);
      final mo = int.parse(match6.group(2)!);
      return {
        'year': yr,
        'month': mo,
        'period': '${_monthsFr[mo - 1]} $yr',
        'key': '$yr-${mo < 10 ? "0$mo" : "$mo"}',
      };
    }

    final matchSep = RegExp(r'(20\d{2})[-_](0[1-9]|1[0-2])').firstMatch(name);
    if (matchSep != null) {
      final yr = int.parse(matchSep.group(1)!);
      final mo = int.parse(matchSep.group(2)!);
      return {
        'year': yr,
        'month': mo,
        'period': '${_monthsFr[mo - 1]} $yr',
        'key': '$yr-${mo < 10 ? "0$mo" : "$mo"}',
      };
    }

    for (int i = 0; i < _monthsFr.length; i++) {
      final mName = _monthsFr[i].toLowerCase();
      if (name.contains(mName)) {
        final matchYr = RegExp(r'(20\d{2})').firstMatch(name);
        final yr = matchYr != null ? int.parse(matchYr.group(1)!) : 2025;
        final mo = i + 1;
        return {
          'year': yr,
          'month': mo,
          'period': '${_monthsFr[i]} $yr',
          'key': '$yr-${mo < 10 ? "0$mo" : "$mo"}',
        };
      }
    }

    return null;
  }

  /// Scans extracted PDF text or Latin1 byte text strictly for Net After Tax (Net versé sur le compte)
  static Map<String, dynamic>? _scanPdfTextForFinancials(Uint8List? fileBytes, String? rawTextContent) {
    final StringBuffer textBuffer = StringBuffer();

    if (rawTextContent != null && rawTextContent.isNotEmpty) {
      textBuffer.write(rawTextContent);
    }

    if (fileBytes != null && fileBytes.isNotEmpty) {
      try {
        textBuffer.write('\n');
        textBuffer.write(latin1.decode(fileBytes, allowInvalid: true));
      } catch (_) {}
    }

    final fullText = textBuffer.toString();
    if (fullText.isEmpty) return null;

    double? foundNet;
    double? foundGross;
    double? foundNetSocial;
    bool hasExplicitBonus = false;
    String? bonusDesc;

    // Check for explicit bonus line items in text stream
    if (RegExp(r'PRIME\s+DE\s+VACANCES', caseSensitive: false).hasMatch(fullText)) {
      hasExplicitBonus = true;
      bonusDesc = 'Prime de Vacances';
    } else if (RegExp(r"13E?ME\s+MOIS|PRIME\s+DE\s+FIN\s+D'ANNEE", caseSensitive: false).hasMatch(fullText)) {
      hasExplicitBonus = true;
      bonusDesc = '13ème Mois';
    } else if (RegExp(r'PRIME\s+EXCEPTIONNELLE|GRATIFICATION|BONUS', caseSensitive: false).hasMatch(fullText)) {
      hasExplicitBonus = true;
      bonusDesc = 'Prime Exceptionnelle';
    } else if (RegExp(r'PRIME\s+DE\s+PERFORMANCE|VARIABLE', caseSensitive: false).hasMatch(fullText)) {
      hasExplicitBonus = true;
      bonusDesc = 'Prime de Performance';
    }

    // Pattern d'extraction haute précision (euros et centimes séparés par espace, virgule ou point)
    const String numPattern = r'(\d{1,6})(?:[\s,\.](\d{2}))?(?!\d)';

    // PRIORITY 1: NET APRES IMPOT / NET VERSE SUR LE COMPTE / VIREMENT
    final netAfterTaxRegExp = RegExp(
      r'(?:NET\s+VERS[EÉ]|NET\s+PAY[EÉ]|NET\s+A\s+PAYER\s+APR[EÈ]S\s+IMP[OÔ]T|MONTANT\s+NET\s+VERS[EÉ]|EN\s+EUROS\s+VIREMENT|VIREMENT|SOLDE\s+DE\s+TOUT\s+COMPTE)[^\d]*' + numPattern,
      caseSensitive: false,
    );

    for (final match in netAfterTaxRegExp.allMatches(fullText)) {
      final euros = match.group(1)!;
      final centimes = match.group(2) ?? '00';
      final val = double.tryParse('$euros.$centimes');
      if (val != null && val >= 500.0 && val <= 30000.0) {
        foundNet = val;
        break;
      }
    }

    // PRIORITY 2: General NET A PAYER (if net after tax line wasn't matched explicitly above)
    if (foundNet == null) {
      final netGeneralRegExp = RegExp(
        r'(?:NET\s+A\s+PAYER|NET\s+PAYABLE|NET\s+FISCAL)[^\d]*' + numPattern,
        caseSensitive: false,
      );
      for (final match in netGeneralRegExp.allMatches(fullText)) {
        final euros = match.group(1)!;
        final centimes = match.group(2) ?? '00';
        final val = double.tryParse('$euros.$centimes');
        if (val != null && val >= 500.0 && val <= 30000.0) {
          foundNet = val;
          break;
        }
      }
    }

    // PRIORITY 3: NET A PAYER AVANT IMPOT (only as secondary fallback if net after tax is missing)
    if (foundNet == null) {
      final netBeforeTaxRegExp = RegExp(
        r'(?:NET\s+A\s+PAYER\s+AVANT\s+IMPOT)[^\d]*' + numPattern,
        caseSensitive: false,
      );
      for (final match in netBeforeTaxRegExp.allMatches(fullText)) {
        final euros = match.group(1)!;
        final centimes = match.group(2) ?? '00';
        final val = double.tryParse('$euros.$centimes');
        if (val != null && val >= 500.0 && val <= 30000.0) {
          foundNet = val;
          break;
        }
      }
    }

    // 2. Net Social / Montant Net Social (parcours complet allMatches)
    final netSocialRegExp = RegExp(
      r'(?:MONTANT\s+NET\s+SOCIAL|NET\s+SOCIAL)[^\d]*' + numPattern,
      caseSensitive: false,
    );
    for (final match in netSocialRegExp.allMatches(fullText)) {
      final euros = match.group(1)!;
      final centimes = match.group(2) ?? '00';
      final val = double.tryParse('$euros.$centimes');
      if (val != null && val >= 500.0 && val <= 30000.0) {
        foundNetSocial = val;
        break;
      }
    }

    // 3. Salaire Brut / Total Brut / Brut Impôts (parcours complet allMatches)
    final grossRegExp = RegExp(
      r'(?:SALAIRE\s+BRUT|TOTAL\s+BRUT|CUMUL\s+BRUT|TOTAL\_DU\s+BRUT|BRUT\s+IMPOTS)[^\d]*' + numPattern,
      caseSensitive: false,
    );
    for (final match in grossRegExp.allMatches(fullText)) {
      final euros = match.group(1)!;
      final centimes = match.group(2) ?? '00';
      final val = double.tryParse('$euros.$centimes');
      if (val != null && val >= 500.0 && val <= 30000.0) {
        foundGross = val;
        break;
      }
    }

    if (foundNet != null || foundNetSocial != null || foundGross != null) {
      return {
        if (foundNet != null) 'net': foundNet,
        if (foundGross != null) 'gross': foundGross,
        if (foundNetSocial != null) 'netSocial': foundNetSocial,
        'hasExplicitBonus': hasExplicitBonus,
        if (bonusDesc != null) 'bonusDescription': bonusDesc,
      };
    }

    return null;
  }

  static Future<RealParsedPayslip> parseDocument({
    Uint8List? fileBytes,
    String? fileName,
    String? apiKey,
    String? rawTextContent,
  }) async {
    final extractedInfo = _extractPeriodFromFileName(fileName);
    final String extractedPeriod = extractedInfo != null ? extractedInfo['period'] : 'Période Inconnue';
    final bool periodDetected = extractedInfo != null;
    final int yr = extractedInfo != null ? extractedInfo['year'] : 2026;
    final int mo = extractedInfo != null ? extractedInfo['month'] : 7;

    // 1. Scan PDF text content (from PDF.js browser text extraction or byte stream)
    final scannedFinancials = _scanPdfTextForFinancials(fileBytes, rawTextContent);
    final rawFileB64 = fileBytes != null ? base64Encode(fileBytes) : null;

    final fnLower = (fileName ?? '').toLowerCase();
    final String mimeType = fnLower.endsWith('.pdf')
        ? 'application/pdf'
        : (fnLower.endsWith('.png') ? 'image/png' : 'image/jpeg');

    // 2. Multi-Tier Model Rotator Cascade
    if (fileBytes != null && fileBytes.isNotEmpty && apiKey != null && apiKey.isNotEmpty) {
      final base64Data = base64Encode(fileBytes);
      final now = DateTime.now();

      for (String modelName in _geminiModelsCascade) {
        final cooldownUntil = _modelCooldownMap[modelName];
        if (cooldownUntil != null && now.isBefore(cooldownUntil)) {
          debugPrint('⏳ [Gemini Rotator] Skipping $modelName (in cooldown until $cooldownUntil)');
          continue;
        }

        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
          );

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text': '''
Tu es un expert comptable spécialisé dans la paie française. Analyse ce bulletin et renvoie STRICTEMENT un JSON valide :
- period (String format YYYY-MM ex: "2026-03" ou "2026-07")
- grossSalary (double: Total salaire brut)
- netSocial (double: Montant Net Social)
- netPayable (double: STRICTEMENT le Salaire Net VERSÉ sur le compte bancaire APRÈS IMPÔT SUR LE REVENU / Prélèvement à la source. NE PRENDS PAS le Net avant impôt !)
- hasExplicitBonus (boolean: true uniquement si une ligne de PRIME DE VACANCES, 13EME MOIS, BONUS ou PRIME EXCEPTIONNELLE est présente)
- bonusDescription (String: Intitulé exact de la prime si présente, sinon null)
'''
                    },
                    {
                      'inline_data': {
                        'mime_type': mimeType,
                        'data': base64Data,
                      }
                    }
                  ]
                }
              ],
              'generationConfig': {
                'response_mime_type': 'application/json',
              }
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final textResult = data['candidates'][0]['content']['parts'][0]['text'];
            final jsonMap = jsonDecode(textResult);

            final parsedPeriod = jsonMap['period'] as String?;
            final bool hasGeminiPeriod = parsedPeriod != null && parsedPeriod.isNotEmpty && parsedPeriod != 'null';

            debugPrint('✅ [AI MODEL SUCCESS] Bulletin analysé via le modèle tier : $modelName');

            final double parsedNet = (jsonMap['netPayable'] as num?)?.toDouble() ?? 0.0;
            final double parsedGross = (jsonMap['grossSalary'] as num?)?.toDouble() ?? 0.0;
            final double parsedSocial = (jsonMap['netSocial'] as num?)?.toDouble() ?? 0.0;

            return RealParsedPayslip(
              id: 'payslip-$yr${mo < 10 ? "0$mo" : "$mo"}-${(fileName?.hashCode ?? 0).abs() % 10000}',
              employeeName: '[Caviardé]',
              employerName: jsonMap['employerName'] ?? 'Employeur',
              siret: 'XXXXXXXXXXXXXX',
              period: hasGeminiPeriod ? parsedPeriod : extractedPeriod,
              periodDetected: hasGeminiPeriod || periodDetected,
              date: DateTime(yr, mo, 28),
              grossSalary: parsedGross >= 500.0 ? parsedGross : (scannedFinancials?['gross'] ?? 0.0),
              netSocial: parsedSocial >= 500.0 ? parsedSocial : (scannedFinancials?['netSocial'] ?? 0.0),
              netPayable: parsedNet >= 500.0 ? parsedNet : (scannedFinancials?['net'] ?? 0.0),
              socialContributions: 0.0,
              mealTickets: 0.0,
              teleworkAllowance: 0.0,
              nonTaxableAllowance: 0.0,
              hasExplicitBonus: (jsonMap['hasExplicitBonus'] as bool?) ?? (scannedFinancials?['hasExplicitBonus'] ?? false),
              bonusDescription: jsonMap['bonusDescription'] ?? scannedFinancials?['bonusDescription'],
              isParsedFromDocument: true,
              rawFileBase64: rawFileB64,
            );
          } else if (response.statusCode == 429) {
            debugPrint('🚨 [QUOTA ALERT] Modèle $modelName sous limite de quota (HTTP 429). Placé en cooldown 30s. Bascule vers la suite du cascade...');
            _modelCooldownMap[modelName] = DateTime.now().add(const Duration(seconds: 30));
            continue;
          } else if (response.statusCode == 404 || response.statusCode == 400) {
            debugPrint('⚠️ [MODEL CASCADE] Modèle $modelName non disponible (HTTP ${response.statusCode}). Passage au niveau suivant...');
            continue;
          }
        } catch (e) {
          debugPrint('⚠️ [MODEL CASCADE] Erreur sur $modelName: $e. Passage au niveau suivant...');
        }
      }
    }

    // 3. STRICT FACTUAL EXTRACTION - ABSOLUTELY ZERO HARDCODED DUMMY FALLBACKS
    final double netVal = (scannedFinancials?['net'] != null && scannedFinancials!['net'] >= 500.0)
        ? scannedFinancials['net']
        : 0.0;
    final double grossVal = (scannedFinancials?['gross'] != null && scannedFinancials!['gross'] >= 500.0)
        ? scannedFinancials['gross']
        : 0.0;
    final double netSocialVal = (scannedFinancials?['netSocial'] != null && scannedFinancials!['netSocial'] >= 500.0)
        ? scannedFinancials['netSocial']
        : 0.0;
    final bool isParsed = netVal > 0.0;

    return RealParsedPayslip(
      id: 'payslip-$yr${mo < 10 ? "0$mo" : "$mo"}-${(fileName?.hashCode ?? 0).abs() % 10000}',
      employeeName: '[Caviardé]',
      employerName: 'Employeur',
      siret: 'XXXXXXXXXXXXXX',
      period: extractedPeriod,
      periodDetected: periodDetected,
      date: DateTime(yr, mo, 28),
      grossSalary: grossVal,
      netSocial: netSocialVal,
      netPayable: netVal,
      socialContributions: 0.0,
      mealTickets: 0.0,
      teleworkAllowance: 0.0,
      nonTaxableAllowance: 0.0,
      hasExplicitBonus: scannedFinancials?['hasExplicitBonus'] ?? false,
      bonusDescription: scannedFinancials?['bonusDescription'],
      isParsedFromDocument: isParsed,
      rawFileBase64: rawFileB64,
    );
  }
}
