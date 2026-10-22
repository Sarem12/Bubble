import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class RegisterEmailScreen extends ConsumerStatefulWidget {
  const RegisterEmailScreen({super.key});

  @override
  ConsumerState<RegisterEmailScreen> createState() => _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends ConsumerState<RegisterEmailScreen> {
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      UiHelpers.showError(context, "Please enter your email.");
      return;
    }

    SafeHaptics.lightImpact();
    setState(() => _isLoading = true);

    final errorMsg = await ref.read(authControllerProvider.notifier).sendOtp(identifier);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMsg == null) {
        UiHelpers.showSuccess(context, "Verification code sent!");
        context.push('/register/otp');
      } else {
        UiHelpers.showError(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const LiquidGlassAppBar(title: Text('Sign Up')),
      body: Stack(
        children: [
          // Ambient glowing orbs
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.20 : 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.18 : 0.22),
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

          // Center Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LiquidGlassTheme.primaryLiquidGradient(context: context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIconsFill.envelopeSimple,
                          color: LiquidGlassTheme.primaryTextColor(context),
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Enter your Email',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We will send a 6-digit verification code to confirm your email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: LiquidGlassTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 28),

                    LiquidGlassContainer(
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: TextField(
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                          ),
                          prefixIcon: const Icon(PhosphorIconsRegular.envelopeSimple, size: 20),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: LiquidGlassButton(
                        height: 52,
                        label: 'Send Code',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleSendOtp,
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

