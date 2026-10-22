import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await ApiClient.dio.get('/users/me');
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<Map<String, dynamic>> getUserSettings() async {
    final response = await ApiClient.dio.get('/users/me/settings');
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<void> updatePrivacySetting(Map<String, dynamic> payload) async {
    await ApiClient.dio.patch('/users/me/settings', data: payload);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String bio,
    required String birthday,
    required String accountType,
    String? profilePictureUrl,
  }) async {
    final response = await ApiClient.dio.put(
      '/users/me',
      data: {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'bio': bio,
      'birthday': birthday,
        'type': accountType,
      'profile_picture_url': profilePictureUrl ?? '',
      },
    );
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<Map<String, dynamic>> uploadProfilePicture(String filePath) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });
    final response = await ApiClient.dio.post(
      '/users/me/profile-picture',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await ApiClient.dio.get('/users/$userId');
    return response.data is Map<String, dynamic>
        ? response.data
        : Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getUserBubbles(String userId) async {
    final response = await ApiClient.dio.get('/bubbles/user/$userId');
    if (response.data is List) return response.data as List;
    return [];
  }

  Future<void> blockUser(String userId) async {
    await ApiClient.dio.post('/friends/$userId/block');
  }

  Future<void> deleteAccount() async {
    await ApiClient.dio.delete('/users/me');
  }
}
