import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import '../storage/secure_storage.dart';
import '../../app/routes.dart';
import 'package:go_router/go_router.dart';

class ApiClient {
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) return customUrl;
    if (const bool.fromEnvironment('dart.vm.product')) {
      return 'https://api.bubble.app/api'; // Or throw exception
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://127.0.0.1:3000/api';
  }

  static String get serverOrigin {
    final uri = Uri.tryParse(baseUrl);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      final portSuffix = uri.hasPort ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$portSuffix';
    }
    return baseUrl.replaceAll('/api', '');
  }

  static final Dio dio = _createDio();
  static Future<String?>? _ongoingRefresh;

  /// Checks if a JWT token is expired (or close to expiring within [buffer]).
  static bool isTokenExpired(String? token, {Duration buffer = const Duration(seconds: 45)}) {
    if (token == null || token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payload = jsonDecode(decoded);
      final exp = payload['exp'];
      if (exp == null) return false;
      final expSeconds = exp is int ? exp : int.parse(exp.toString());
      final expDateTime = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
      return DateTime.now().isAfter(expDateTime.subtract(buffer));
    } catch (_) {
      return true;
    }
  }

  /// Retrieves a valid access token.
  /// If the current access token is null or expired, proactively refreshes it using the session token.
  static Future<String?> getValidAccessToken() async {
    final currentAccessToken = await SecureStorage.getAccessToken();
    if (currentAccessToken != null && !isTokenExpired(currentAccessToken)) {
      return currentAccessToken;
    }

    // Access token is missing or expired, attempt to refresh using session token
    final sessionToken = await SecureStorage.getSessionToken();
    if (sessionToken == null || isTokenExpired(sessionToken, buffer: Duration.zero)) {
      return null;
    }

    return await refreshAccessToken();
  }

  /// Deduplicated session token refresh so multiple concurrent requests don't trigger multiple refreshes.
  static Future<String?> refreshAccessToken() async {
    if (_ongoingRefresh != null) {
      return _ongoingRefresh!;
    }

    _ongoingRefresh = _doRefreshAccessToken();
    try {
      return await _ongoingRefresh;
    } finally {
      _ongoingRefresh = null;
    }
  }

  static Future<String?> _doRefreshAccessToken() async {
    final sessionToken = await SecureStorage.getSessionToken();
    if (sessionToken == null) return null;

    try {
      final deviceId = await SecureStorage.getDeviceId();
      final deviceName = await SecureStorage.getDeviceName();

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await refreshDio.post('/auth/verify-session', data: {
        'session_token': sessionToken,
        'device_id': deviceId,
        'device_name': deviceName,
      });

      final newAccessToken = response.data['access_token'] as String?;
      if (newAccessToken != null) {
        await SecureStorage.saveAccessToken(newAccessToken);
        return newAccessToken;
      }
    } on DioException catch (e) {
      // ONLY invalidate credentials if server explicitly reported session invalid/expired/revoked
      if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403 ||
          e.response?.statusCode == 404) {
        await SecureStorage.clearAuth();
        _navigateToLogin();
      }
      // If network error, timeout, or server 500: DO NOT clear auth!
    } catch (_) {
      // Ignore other transient failures
    }
    return null;
  }

  static Dio _createDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    client.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // If request already has Authorization header set, keep it
          if (options.headers.containsKey('Authorization')) {
            return handler.next(options);
          }

          // Unauthenticated endpoints do not require access tokens
          final path = options.path;
          if (path.startsWith('/auth/') && path != '/auth/me') {
            return handler.next(options);
          }
          if (path == '/health') {
            return handler.next(options);
          }

          // Proactively retrieve a valid access token (auto-refreshes if expired or missing)
          final accessToken = await getValidAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }

          return handler.next(options);
        },
        
        onError: (DioException error, handler) async {
          // If user profile is 404, user account was deleted
          if (error.response?.statusCode == 404 && error.requestOptions.path == '/users/me') {
            await SecureStorage.clearAuth();
            _navigateToLogin();
            return handler.next(error);
          }

          // If 401 Unauthorized from an authenticated endpoint, try refreshing once
          if (error.response?.statusCode == 401 && error.requestOptions.path != '/auth/verify-session') {
            final alreadyRetried = error.requestOptions.extra['token_refreshed'] == true;
            if (alreadyRetried) {
              await SecureStorage.clearAuth();
              _navigateToLogin();
              return handler.next(error);
            }

            final newAccessToken = await refreshAccessToken();
            if (newAccessToken != null) {
              final options = error.requestOptions;
              options.extra['token_refreshed'] = true;
              options.headers['Authorization'] = 'Bearer $newAccessToken';
              try {
                final retryResponse = await client.fetch(options);
                return handler.resolve(retryResponse);
              } catch (e) {
                if (e is DioException) {
                  return handler.next(e);
                }
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    return client;
  }

  static void _navigateToLogin() {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      context.go('/login');
    }
  }
}
