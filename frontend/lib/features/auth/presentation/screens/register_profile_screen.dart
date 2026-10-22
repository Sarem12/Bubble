import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class RegisterProfileScreen extends ConsumerStatefulWidget {
  const RegisterProfileScreen({super.key});

  @override
  ConsumerState<RegisterProfileScreen> createState() => _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends ConsumerState<RegisterProfileScreen> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  DateTime? _selectedBirthday;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedBirthday = picked);
    }
  }

  void _handleRegister() async {
    final username = _usernameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text;

    // FRONTEND VALIDATION
    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || password.isEmpty) {
      UiHelpers.showError(context, "All fields are required.");
      return;
    }
    
    if (_selectedBirthday == null) {
      UiHelpers.showError(context, "Please select your birthday.");
      return;
    }

    if (password.length < 3) {
      UiHelpers.showError(context, "Password must be at least 3 characters long.");
      return;
    }

    final cleanUsername = username.replaceAll('@', '').toLowerCase();
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(cleanUsername)) {
      UiHelpers.showError(context, "Username can only contain lowercase letters, numbers, and underscores.");
      return;
    }

    SafeHaptics.lightImpact();
    setState(() => _isLoading = true);

    // Format strictly as YYYY-MM-DD for backend time.Parse("2006-01-02")
    final birthdayFormatted = DateFormat('yyyy-MM-dd').format(_selectedBirthday!);

    final errorMsg = await ref.read(authControllerProvider.notifier).register(
      username: cleanUsername,
      firstName: firstName,
      lastName: lastName,
      password: password,
      birthday: birthdayFormatted,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMsg == null) {
        UiHelpers.showSuccess(context, "Account created successfully!");
        context.go('/home');
      } else {
        UiHelpers.showError(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const LiquidGlassAppBar(title: Text('Create Profile')),
      body: Stack(
        children: [
          // Ambient glowing orbs
          Positioned(
            top: -40,
            right: -30,
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

          // Content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 40),
            child: Column(
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
                      PhosphorIconsFill.userPlus,
                      color: LiquidGlassTheme.primaryTextColor(context),
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Almost Done!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete your profile details to join your first bubbles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: LiquidGlassTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),

                // Names Group
                LiquidGlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                          ),
                          prefixIcon: const Icon(PhosphorIconsRegular.identificationBadge, size: 20),
                          border: InputBorder.none,
                        ),
                      ),
                      Divider(
                        height: 12,
                        thickness: 0.8,
                        color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
                      ),
                      TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                          ),
                          prefixIcon: const Icon(PhosphorIconsRegular.identificationBadge, size: 20),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Account Credentials Group
                LiquidGlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'e.g. johndoe',
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                          ),
                          prefixIcon: const Icon(PhosphorIconsRegular.at, size: 20),
                          border: InputBorder.none,
                        ),
                      ),
                      Divider(
                        height: 12,
                        thickness: 0.8,
                        color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
                      ),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Min 3 characters',
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
                      Divider(
                        height: 12,
                        thickness: 0.8,
                        color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
                      ),
                      // Birthday Picker Field
                      InkWell(
                        onTap: _pickBirthday,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.cake, color: Colors.grey, size: 22),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Birthday',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedBirthday == null
                                          ? 'Select your birthday'
                                          : DateFormat('yyyy-MM-dd').format(_selectedBirthday!),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedBirthday == null ? Colors.grey : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(PhosphorIconsRegular.calendar, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: LiquidGlassButton(
                    height: 52,
                    label: 'Create Account',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleRegister,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

