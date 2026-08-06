import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_planner_flutter/main.dart';

void main() {
  testWidgets('Smoke test AuraBudgetApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AuraBudgetApp(),
      ),
    );
    expect(find.text('AuraBudget Pro'), findsWidgets);
  });
}
