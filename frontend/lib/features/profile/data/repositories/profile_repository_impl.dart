import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/entities/friendship.dart';
import '../../../search/domain/entities/bubble.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../datasources/friend_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _profileDataSource;
  final FriendRemoteDataSource _friendDataSource;

  ProfileRepositoryImpl(this._profileDataSource, this._friendDataSource);

  @override
  Future<UserProfile> getMyProfile() async {
    final raw = await _profileDataSource.getMyProfile();
    return UserProfile.fromJson(raw);
  }

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    final raw = await _profileDataSource.getUserProfile(userId);
    return UserProfile.fromJson(raw);
  }

  @override
  Future<UserSettings> getUserSettings() async {
    final raw = await _profileDataSource.getUserSettings();
    return UserSettings.fromJson(raw);
  }

  @override
  Future<void> updatePrivacySetting(Map<String, dynamic> payload) {
    return _profileDataSource.updatePrivacySetting(payload);
  }

  @override
  Future<UserProfile> updateProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String bio,
    required String birthday,
    required String accountType,
    String? profilePictureUrl,
  }) async {
    final raw = await _profileDataSource.updateProfile(
      username: username,
      firstName: firstName,
      lastName: lastName,
      bio: bio,
      birthday: birthday,
      accountType: accountType,
      profilePictureUrl: profilePictureUrl,
    );
    return UserProfile.fromJson(raw);
  }

  @override
  Future<String> uploadProfilePicture(String filePath) async {
    final raw = await _profileDataSource.uploadProfilePicture(filePath);
    return (raw['profile_picture_url'] ?? raw['url'] ?? '').toString();
  }

  @override
  Future<void> deleteAccount() {
    return _profileDataSource.deleteAccount();
  }

  @override
  Future<List<FriendUser>> getFriends() async {
    final rawList = await _friendDataSource.getFriends();
    return rawList.map((e) => FriendUser.fromJson(e)).toList();
  }

  @override
  Future<List<Bubble>> getUserBubbles(String userId) async {
    final rawList = await _profileDataSource.getUserBubbles(userId);
    return rawList
        .whereType<Map>()
        .map((e) => Bubble.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> sendFriendRequest(String userId) {
    return _friendDataSource.sendFriendRequest(userId);
  }

  @override
  Future<void> acceptFriendRequest(String userId) {
    return _friendDataSource.acceptFriendRequest(userId);
  }

  @override
  Future<void> declineFriendRequest(String userId) {
    return _friendDataSource.declineFriendRequest(userId);
  }

  @override
  Future<void> removeFriend(String userId) {
    return _friendDataSource.removeFriend(userId);
  }

  @override
  Future<void> blockUser(String userId) {
    return _profileDataSource.blockUser(userId);
  }
}

final profileDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final profileDs = ref.watch(profileDataSourceProvider);
  final friendDs = ref.watch(friendRemoteDataSourceProvider);
  return ProfileRepositoryImpl(profileDs, friendDs);
});
