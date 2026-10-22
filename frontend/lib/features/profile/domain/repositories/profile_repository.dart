import '../entities/user_profile.dart';
import '../entities/user_settings.dart';
import '../entities/friendship.dart';
import '../../../search/domain/entities/bubble.dart';

abstract class ProfileRepository {
  Future<UserProfile> getMyProfile();
  Future<UserProfile> getUserProfile(String userId);
  Future<UserSettings> getUserSettings();
  Future<void> updatePrivacySetting(Map<String, dynamic> payload);
  Future<UserProfile> updateProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String bio,
    required String birthday,
    required String accountType,
    String? profilePictureUrl,
  });
  Future<String> uploadProfilePicture(String filePath);
  Future<void> deleteAccount();

  Future<List<FriendUser>> getFriends();
  Future<List<Bubble>> getUserBubbles(String userId);
  Future<void> sendFriendRequest(String userId);
  Future<void> acceptFriendRequest(String userId);
  Future<void> declineFriendRequest(String userId);
  Future<void> removeFriend(String userId);
  Future<void> blockUser(String userId);
}
