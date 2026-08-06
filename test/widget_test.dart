import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_planner_flutter/main.dart';

void main() {
  testWidgets('Smoke test AuraBudgetApp with Auth', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: AuraBudgetApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('AuraBudget Pro'), findsWidgets);
  });
}
