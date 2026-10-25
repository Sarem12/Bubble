import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  int _step = 0;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<String?> Function() action,
    VoidCallback onSuccess,
    String successMessage,
  ) async {
    SafeHaptics.lightImpact();
    setState(() => _isLoading = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      UiHelpers.showError(context, error);
      return;
    }
    UiHelpers.showSuccess(context, successMessage);
    onSuccess();
  }

  Future<void> _sendCode() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      UiHelpers.showError(context, 'Enter your email or phone number.');
      return;
    }
    await _run(
      () => ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetOtp(identifier),
      () => setState(() => _step = 1),
      'Reset code sent.',
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().length != 6) {
      UiHelpers.showError(context, 'Enter the 6-digit code.');
      return;
    }
    await _run(
      () => ref
          .read(authControllerProvider.notifier)
          .verifyPasswordResetOtp(_codeController.text.trim()),
      () => setState(() => _step = 2),
      'Code verified.',
    );
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    if (password.length < 10) {
      UiHelpers.showError(
        context,
        'Use a password with at least 10 characters.',
      );
      return;
    }
    await _run(
      () => ref.read(authControllerProvider.notifier).resetPassword(password),
      () => context.go('/login'),
      'Password updated. Sign in with your new password.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = switch (_step) {
      0 => 'Reset your password',
      1 => 'Check your messages',
      _ => 'Choose a new password',
    };
    final subtitle = switch (_step) {
      0 => 'Enter the email or phone number on your account.',
      1 => 'Enter the 6-digit code we sent to you.',
      _ => 'Your new password must be at least 10 characters.',
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const LiquidGlassAppBar(title: Text('Password reset')),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -45,
            child: _Glow(color: const Color(0xFFC913B9), isDark: isDark),
          ),
          Positioned(
            bottom: -75,
            left: -50,
            child: _Glow(color: const Color(0xFF1781E6), isDark: isDark),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LiquidGlassTheme.primaryLiquidGradient(
                            context: context,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _step == 2
                              ? PhosphorIconsRegular.lockKey
                              : PhosphorIconsRegular.envelopeSimple,
                          color: LiquidGlassTheme.primaryTextColor(context),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LiquidGlassTheme.textSecondary(context),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      LiquidGlassContainer(
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            if (_step == 0)
                              TextField(
                                controller: _identifierController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _sendCode(),
                                decoration: const InputDecoration(
                                  labelText: 'Email or phone number',
                                  prefixIcon: Icon(
                                    PhosphorIconsRegular.userCircle,
                                    size: 20,
                                  ),
                                ),
                              ),
                            if (_step == 1)
                              TextField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                maxLength: 6,
                                onSubmitted: (_) => _verifyCode(),
                                decoration: const InputDecoration(
                                  labelText: '6-digit verification code',
                                  counterText: '',
                                  prefixIcon: Icon(
                                    PhosphorIconsRegular.shieldCheck,
                                    size: 20,
                                  ),
                                ),
                              ),
                            if (_step == 2)
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _resetPassword(),
                                decoration: const InputDecoration(
                                  labelText: 'New password',
                                  prefixIcon: Icon(
                                    PhosphorIconsRegular.lockKey,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: LiquidGlassButton(
                          height: 52,
                          label: _step == 0
                              ? 'Send reset code'
                              : _step == 1
                              ? 'Verify code'
                              : 'Update password',
                          isLoading: _isLoading,
                          onPressed: _isLoading
                              ? null
                              : _step == 0
                              ? _sendCode
                              : _step == 1
                              ? _verifyCode
                              : _resetPassword,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Back to sign in'),
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

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.isDark});

  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    width: 270,
    height: 270,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: isDark ? 0.2 : 0.16),
    ),
  );
}
