import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/google_sign_in_button.dart';
import '../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  static const _features = [
    _Feature(icon: Icons.lock_outline_rounded, label: 'Chiffré'),
    _Feature(icon: Icons.account_balance_outlined, label: 'TrueLayer'),
    _Feature(icon: Icons.auto_awesome_outlined, label: 'Audit IA'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 750),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp,
                            child: Column(
                              children: [
                                const Spacer(flex: 3),
                                _Logo(colorScheme: colorScheme),
                                const SizedBox(height: 24),
                                Text(
                                  'AuraBudget Pro',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Budget, synchronisation bancaire\net audit IA',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                                const Spacer(flex: 2),
                                Row(
                                  children: [
                                    for (var i = 0; i < _features.length; i++) ...[
                                      Expanded(
                                        child: _FeatureChip(
                                          feature: _features[i],
                                          colorScheme: colorScheme,
                                        ),
                                      ),
                                      if (i != _features.length - 1)
                                        const SizedBox(width: 8),
                                    ],
                                  ],
                                ),
                                const Spacer(flex: 3),
                                const GoogleSignInButton(),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    // TODO: navigation vers le flow e-mail
                                  },
                                  child: Text(
                                    'Continuer avec e-mail',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _LegalFooter(colorScheme: colorScheme),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});
}

class _Logo extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Logo({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        color: colorScheme.onPrimary,
        size: 28,
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final _Feature feature;
  final ColorScheme colorScheme;
  const _FeatureChip({required this.feature, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(feature.icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(feature.label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  final ColorScheme colorScheme;
  const _LegalFooter({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 11,
        );
    final linkStyle = style?.copyWith(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(style: style, children: [
        const TextSpan(text: 'En continuant, vous acceptez nos '),
        TextSpan(text: 'Conditions', style: linkStyle),
        const TextSpan(text: ' et notre '),
        TextSpan(text: 'Politique de confidentialité', style: linkStyle),
        const TextSpan(text: '.'),
      ]),
    );
  }
}