import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../controllers/auth_controller.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      UiHelpers.showError(
        context,
        'Enter your email, phone, or username and password.',
      );
      return;
    }

    SafeHaptics.lightImpact();
    setState(() => _isLoading = true);
    final errorMsg = await ref
        .read(authControllerProvider.notifier)
        .login(identifier, password);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (errorMsg != null) {
      UiHelpers.showError(context, errorMsg);
    } else {
      UiHelpers.showSuccess(context, 'Welcome back!');
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = LiquidGlassTheme.textSecondary(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -65,
            child: _LoginGlow(
              color: const Color(0xFFC913B9),
              opacity: isDark ? 0.22 : 0.17,
            ),
          ),
          Positioned(
            bottom: -70,
            right: -70,
            child: _LoginGlow(
              color: const Color(0xFF1781E6),
              opacity: isDark ? 0.20 : 0.16,
            ),
          ),
          Positioned(
            top: 210,
            right: -90,
            child: _LoginGlow(
              color: const Color(0xFF01E762),
              opacity: isDark ? 0.08 : 0.07,
              size: 200,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'bubble',
                        style: TextStyle(
                          fontFamily: 'Alan Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 44,
                          letterSpacing: -1.8,
                          height: 1,
                          color: LiquidGlassTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to catch up with your people.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondary, height: 1.4),
                      ),
                      const SizedBox(height: 30),
                      LiquidGlassContainer(
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Email, phone, or username',
                                labelStyle: TextStyle(color: secondary),
                                prefixIcon: const Icon(
                                  PhosphorIconsRegular.userCircle,
                                  size: 21,
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: secondary),
                                prefixIcon: const Icon(
                                  PhosphorIconsRegular.lockKey,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    _obscurePassword
                                        ? PhosphorIconsRegular.eyeSlash
                                        : PhosphorIconsRegular.eye,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: LiquidGlassButton(
                          height: 54,
                          label: 'Sign in',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _handleLogin,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New to Bubble? ',
                            style: TextStyle(color: secondary),
                          ),
                          GestureDetector(
                            onTap: () {
                              SafeHaptics.lightImpact();
                              context.push('/register/email');
                            },
                            child: Text(
                              'Create an account',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginGlow extends StatelessWidget {
  const _LoginGlow({
    required this.color,
    required this.opacity,
    this.size = 280,
  });

  final Color color;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: opacity),
    ),
  );
}
