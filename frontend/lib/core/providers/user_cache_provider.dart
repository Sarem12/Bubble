import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/domain/entities/user_profile.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';

// Re-export UserProfile as UserData for seamless backward compatibility
typedef UserData = UserProfile;

final userCacheProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  if (userId.isEmpty) {
    return const UserProfile(id: '', username: 'Unknown');
  }
  final myProfile = ref.watch(profileControllerProvider).value;
  if (myProfile != null && (myProfile.id == userId || userId == 'me')) {
    return myProfile;
  }
  try {
    final repo = ref.read(profileRepositoryProvider);
    return await repo.getUserProfile(userId);
  } catch (e) {
    return UserProfile(id: userId, username: 'Unknown');
  }
});
