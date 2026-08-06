import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/colors.dart';
import 'core/providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/salary_audit_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/crisis_screen.dart';
import 'screens/clic_screen.dart';
import 'screens/settings_screen.dart';
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
  bool _isSidebarCollapsed = false;

  final List<Widget> _screens = const [
    DashboardScreen(),     // Index 0
    RulesScreen(),         // Index 1
    SalaryAuditScreen(),   // Index 2
    SavingsScreen(),       // Index 3
    CrisisScreen(),        // Index 4
    ClicScreen(),          // Index 5
    SettingsScreen(),      // Index 6
  ];

  // Map bottom nav destination index to screen index
  static const List<int> _bottomNavToScreenIndex = [0, 1, 2, 3, 6];

  int _getBottomNavIndex() {
    final navIdx = _bottomNavToScreenIndex.indexOf(_currentIndex);
    return navIdx != -1 ? navIdx : 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          // Desktop Layout: Collapsible Left Sidebar + Content Area
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isSidebarCollapsed ? 76 : 260,
                  child: AppDrawerWidget(
                    currentIndex: _currentIndex,
                    isCollapsed: _isSidebarCollapsed,
                    onToggleCollapse: () {
                      setState(() {
                        _isSidebarCollapsed = !_isSidebarCollapsed;
                      });
                    },
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
          // Mobile Layout: Drawer + Bottom Navigation Bar
          return Scaffold(
            backgroundColor: AppColors.background,
            drawer: AppDrawerWidget(
              currentIndex: _currentIndex,
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
              selectedIndex: _getBottomNavIndex(),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.accentCyan.withValues(alpha: 0.2),
              onDestinationSelected: (navIndex) {
                setState(() {
                  _currentIndex = _bottomNavToScreenIndex[navIndex];
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Tableau',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_rounded),
                  label: 'Règles',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Bulletins',
                ),
                NavigationDestination(
                  icon: Icon(Icons.savings_rounded),
                  label: 'Épargne',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Config',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
