import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/safe_haptics.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../controllers/auth_controller.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_isLoading) return;
    _isLoading = true;

    setState(() {
      _hasError = false;
    });

    try {
      final sessionToken = await SecureStorage.getSessionToken();
      if (sessionToken == null) {
        // Not logged in: test server reachability, then navigate to login
        try {
          await ref.read(authDataSourceProvider).checkHealth();
        } catch (_) {
          throw Exception("Failed to connect to server");
        }
        if (mounted) context.go('/login');
        return;
      }

      // Session token exists! Ensure we have a valid access token (auto-refreshes if needed)
      final accessToken = await ApiClient.getValidAccessToken();
      if (accessToken == null) {
        final remainingSession = await SecureStorage.getSessionToken();
        if (remainingSession == null) {
          if (mounted) context.go('/login');
          return;
        }
        throw Exception("Failed to connect to server");
      }

      // Verify user profile with the valid access token via repository
      await ref.read(profileRepositoryProvider).getMyProfile();
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403 ||
          e.response?.statusCode == 404) {
        await SecureStorage.clearAuth();
        if (mounted) context.go('/login');
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        _isLoading = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _hasError
              ? _buildErrorState(context, isDark)
              : _buildLoadingState(context),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      key: const ValueKey('loading'),
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    // Non-linear smoothstep gradient lightly blending bubble green, blue, and pink
    final retryGradient = LiquidGlassTheme.createNonLinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark
          ? const [
              Color(0xFF4ADE80), // Soft luminous spring green
              Color(0xFF60A5FA), // Soft luminous bubble blue
              Color(0xFFF472B6), // Soft luminous bubble pink
            ]
          : const [
              Color(0xFF059669), // Crisp spring green
              Color(0xFF1781E6), // Signature bubble blue
              Color(0xFFDB2777), // Crisp bubble pink
            ],
    );

    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIconsRegular.wifiSlash,
          size: 32,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
        const SizedBox(height: 12),
        Text(
          'Failed to connect',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          onPressed: () {
            SafeHaptics.lightImpact();
            _initializeApp();
          },
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => retryGradient.createShader(bounds),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
