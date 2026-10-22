import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';

class AuthRemoteDataSource {
  Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await ApiClient.dio.get('/auth/me/sessions');
    return List<Map<String, dynamic>>.from(response.data['sessions']);
  }

  Future<void> revokeSession(String id) async {
    await ApiClient.dio.delete('/auth/me/sessions/$id');
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await ApiClient.dio.put(
      '/auth/me/password',
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  Future<void> checkHealth() async {
    await ApiClient.dio.get(
      '/health',
      options: Options(
        validateStatus: (status) => true,
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );
  }

  Future<String> login(
    String provider,
    String identifier,
    String password,
  ) async {
    final deviceId = await SecureStorage.getDeviceId();
    final deviceName = await SecureStorage.getDeviceName();

    final response = await ApiClient.dio.post(
      '/auth/login',
      data: {
        "provider": provider,
        "identifier": identifier,
        "password": password,
        "device_id": deviceId,
        "device_name": deviceName,
      },
    );
    return response.data['session_token'];
  }

  Future<String> verifySession(String sessionToken) async {
    final deviceId = await SecureStorage.getDeviceId();
    final deviceName = await SecureStorage.getDeviceName();

    final response = await ApiClient.dio.post(
      '/auth/verify-session',
      data: {
        "session_token": sessionToken,
        "device_id": deviceId,
        "device_name": deviceName,
      },
    );
    return response.data['access_token'];
  }

  Future<void> sendOtp(String email) async {
    await ApiClient.dio.post(
      '/auth/send-otp',
      data: {"provider": "email", "identifier": email, "purpose": "register"},
    );
  }

  Future<String> verifyOtp(String email, String code) async {
    final response = await ApiClient.dio.post(
      '/auth/verify-otp',
      data: {"identifier": email, "code": code},
    );
    return response.data['verification_token'] ?? response.data['token'];
  }

  Future<String> register({
    required String username,
    required String firstName,
    required String lastName,
    required String bio,
    required String birthday,
    required String password,
    required String verificationToken,
  }) async {
    final deviceId = await SecureStorage.getDeviceId();
    final deviceName = await SecureStorage.getDeviceName();

    final response = await ApiClient.dio.post(
      '/auth/register',
      data: {
        "username": username,
        "first_name": firstName,
        "last_name": lastName,
        "bio": bio,
        "birthday": birthday,
        "password": password,
        "device_id": deviceId,
        "device_name": deviceName,
      },
      options: Options(headers: {'X-Verification-Token': verificationToken}),
    );
    return response.data['session_token'];
  }
}
