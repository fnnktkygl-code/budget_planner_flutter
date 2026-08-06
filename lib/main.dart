import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/colors.dart';
import 'core/providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/salary_audit_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/crisis_screen.dart';
import 'screens/clic_screen.dart';
import 'widgets/app_drawer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AuraBudgetApp(),
    ),
  );
}

class AuraBudgetApp extends ConsumerWidget {
  const AuraBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'AuraBudget Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.accentCyan,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentCyan,
          secondary: AppColors.accentEmerald,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: authState.isLoading
          ? const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.accentCyan),
              ),
            )
          : authState.isSignedIn
              ? const ResponsiveMainLayout()
              : const LoginScreen(),
    );
  }
}

class ResponsiveMainLayout extends StatefulWidget {
  const ResponsiveMainLayout({super.key});

  @override
  State<ResponsiveMainLayout> createState() => _ResponsiveMainLayoutState();
}

class _ResponsiveMainLayoutState extends State<ResponsiveMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RulesScreen(),
    SalaryAuditScreen(),
    SettingsScreen(),
    SavingsScreen(),
    CrisisScreen(),
    ClicScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          // Desktop Layout: Permanent Left Sidebar + Content Area
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: AppDrawerWidget(
                    onSelectScreen: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                ),
                const VerticalDivider(color: AppColors.borderSubtle, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Layout: Drawer + Bottom Navigation Bar (Matching Screenshots)
          return Scaffold(
            backgroundColor: AppColors.background,
            drawer: AppDrawerWidget(
              onSelectScreen: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex < 4 ? _currentIndex : 0,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.accentCyan.withValues(alpha: 0.2),
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Tableau de bord',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_tree_outlined),
                  label: 'Règles de Répartition',
                ),
                NavigationDestination(
                  icon: Icon(Icons.document_scanner_outlined),
                  label: 'Analyseur de bulletin...',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Configuration',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
