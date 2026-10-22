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
      UiHelpers.showError(context, "Please fill in all fields.");
      return;
    }

    SafeHaptics.lightImpact();
    setState(() => _isLoading = true);

    final errorMsg = await ref.read(authControllerProvider.notifier).login(identifier, password);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMsg != null) {
        UiHelpers.showError(context, errorMsg);
      } else {
        UiHelpers.showSuccess(context, "Welcome back!");
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient glowing orbs for real-time liquid glass refraction
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.20 : 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.18 : 0.22),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.12 : 0.15),
              ),
            ),
          ),

          // Backdrop blur over the ambient orbs
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox.expand(),
            ),
          ),

          // Center Form Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Orb
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LiquidGlassTheme.primaryLiquidGradient(context: context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIconsFill.circlesThree,
                          color: LiquidGlassTheme.primaryTextColor(context),
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Bubble',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live fluid moments, zero doomscrolling',
                      style: TextStyle(
                        fontSize: 14,
                        color: LiquidGlassTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Frosted Glass Login Container
                    LiquidGlassContainer(
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        children: [
                          // Identifier Field
                          TextField(
                            controller: _identifierController,
                            decoration: InputDecoration(
                              labelText: 'Email, Phone, or @username',
                              labelStyle: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                              ),
                              prefixIcon: const Icon(PhosphorIconsRegular.user, size: 20),
                              border: InputBorder.none,
                            ),
                          ),
                          Divider(
                            height: 12,
                            thickness: 0.8,
                            color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
                          ),
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                              ),
                              prefixIcon: const Icon(PhosphorIconsRegular.lockKey, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Primary Login Button
                    SizedBox(
                      width: double.infinity,
                      child: LiquidGlassButton(
                        height: 52,
                        label: 'Sign In',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleLogin,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sign up switch
                    GestureDetector(
                      onTap: () {
                        SafeHaptics.lightImpact();
                        context.push('/register/email');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: LiquidGlassTheme.textSecondary(context),
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign up',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

