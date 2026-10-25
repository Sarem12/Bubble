import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/datasources/auth_remote_datasource.dart';

final authDataSourceProvider = Provider((ref) => AuthRemoteDataSource());

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  late AuthRemoteDataSource _dataSource;

  String? registrationEmail;
  String? verificationToken;
  String? passwordResetIdentifier;
  String? passwordResetVerificationToken;

  @override
  FutureOr<void> build() {
    _dataSource = ref.read(authDataSourceProvider);
  }

  String _detectProvider(String identifier) {
    identifier = identifier.trim();
    if (identifier.startsWith('@')) {
      return 'username';
    } else if (identifier.contains('@')) {
      return 'email';
    }

    if (RegExp(r'^[\+\d\s\-\(\)]+$').hasMatch(identifier)) {
      return 'phone';
    }
    return 'username';
  }

  String _normalizeIdentifier(String identifier, String provider) {
    if (provider == 'phone') {
      return identifier.replaceAll(RegExp(r'[^\d+]'), '');
    } else if (provider == 'username' && identifier.startsWith('@')) {
      return identifier.substring(1).toLowerCase();
    }
    return identifier.toLowerCase();
  }

  Future<String?> login(String identifier, String password) async {
    state = const AsyncLoading();
    final provider = _detectProvider(identifier);

    final cleanIdentifier = _normalizeIdentifier(identifier, provider);

    try {
      final sessionToken = await _dataSource.login(
        provider,
        cleanIdentifier,
        password,
      );
      await SecureStorage.saveSessionToken(sessionToken);

      final accessToken = await _dataSource.verifySession(sessionToken);
      await SecureStorage.saveAccessToken(accessToken);

      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return ErrorHandler.getMessage(e);
    }
  }

  Future<String?> sendOtp(String identifier) async {
    state = const AsyncLoading();
    try {
      await _dataSource.sendOtp(identifier.trim().toLowerCase());
      registrationEmail = identifier.trim().toLowerCase();
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return ErrorHandler.getMessage(e);
    }
  }

  Future<String?> sendPasswordResetOtp(String identifier) async {
    state = const AsyncLoading();
    final trimmed = identifier.trim();
    final provider = _detectProvider(trimmed);
    if (provider == 'username') {
      state = const AsyncData(null);
      return 'Use the email address or phone number linked to your account.';
    }
    final normalized = _normalizeIdentifier(trimmed, provider);
    try {
      await _dataSource.sendOtp(
        normalized,
        provider: provider,
        purpose: 'reset_password',
      );
      passwordResetIdentifier = normalized;
      passwordResetVerificationToken = null;
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return ErrorHandler.getMessage(e);
    }
  }

  Future<String?> verifyPasswordResetOtp(String code) async {
    final identifier = passwordResetIdentifier;
    if (identifier == null) return 'Enter your email or phone number first.';
    state = const AsyncLoading();
    try {
      passwordResetVerificationToken = await _dataSource.verifyOtp(
        identifier,
        code,
      );
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return ErrorHandler.getMessage(e);
    }
  }

  Future<String?> resetPassword(String newPassword) async {
    final token = passwordResetVerificationToken;
    if (token == null) return 'Verify the code sent to you first.';
    state = const AsyncLoading();
    try {
      await _dataSource.resetPassword(
        verificationToken: token,
        newPassword: newPassword,
      );
      passwordResetIdentifier = null;
      passwordResetVerificationToken = null;
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return ErrorHandler.getMessage(e);
    }
  }

  Future<String?> verifyOtp(String code) async {
    if (registrationEmail == null) return "No email stored for verification.";
    state = const AsyncLoading();
    try {
      final token = await _dataSource.verifyOtp(registrationEmail!, code);
      verificationToken = token;
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return ErrorHandler.getMessage(e);
    }
  }

  Future<String?> register({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String birthday,
  }) async {
    if (verificationToken == null)
      return "Missing verification token. Please verify your email again.";
    state = const AsyncLoading();

    final cleanUsername = username.replaceAll('@', '').trim().toLowerCase();

    try {
      // 1. Register and obtain session_token
      final sessionToken = await _dataSource.register(
        username: cleanUsername,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        bio: "",
        birthday: birthday,
        password: password,
        verificationToken: verificationToken!,
      );
      await SecureStorage.saveSessionToken(sessionToken);

      final accessToken = await _dataSource.verifySession(sessionToken);
      await SecureStorage.saveAccessToken(accessToken);

      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return ErrorHandler.getMessage(e);
    }
  }
}
