import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class RegisterOtpScreen extends ConsumerStatefulWidget {
  const RegisterOtpScreen({super.key});

  @override
  ConsumerState<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends ConsumerState<RegisterOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      UiHelpers.showError(context, "Please enter a valid 6-digit code.");
      return;
    }

    SafeHaptics.lightImpact();
    setState(() => _isLoading = true);

    final errorMsg = await ref.read(authControllerProvider.notifier).verifyOtp(code);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMsg == null) {
        UiHelpers.showSuccess(context, "Code verified!");
        context.push('/register/profile');
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
      appBar: const LiquidGlassAppBar(title: Text('Verification')),
      body: Stack(
        children: [
          // Ambient glowing orbs
          Positioned(
            top: -50,
            left: -40,
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
                          PhosphorIconsFill.shieldCheck,
                          color: LiquidGlassTheme.primaryTextColor(context),
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Enter Verification Code',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please type the 6-digit code sent to your email address.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: LiquidGlassTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 28),

                    LiquidGlassContainer(
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: const InputDecoration(
                          hintText: '000000',
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: LiquidGlassButton(
                        height: 52,
                        label: 'Verify & Continue',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleVerify,
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

