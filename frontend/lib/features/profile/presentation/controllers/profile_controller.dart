import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';

export '../../data/repositories/profile_repository_impl.dart'
    show profileDataSourceProvider, profileRepositoryProvider;

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(() {
  return ProfileController();
});

class ProfileController extends AsyncNotifier<UserProfile> {
  late ProfileRepository _repository;

  @override
  FutureOr<UserProfile> build() async {
    _repository = ref.read(profileRepositoryProvider);
    return await _repository.getMyProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final profile = await _repository.getMyProfile();
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<UserProfile> updateProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String bio,
    required String birthday,
    required String accountType,
    String? profilePictureUrl,
  }) async {
    final updated = await _repository.updateProfile(
      username: username,
      firstName: firstName,
      lastName: lastName,
      bio: bio,
      birthday: birthday,
      accountType: accountType,
      profilePictureUrl: profilePictureUrl,
    );
    state = AsyncData(updated);
    return updated;
  }

  Future<String?> uploadProfilePicture(String filePath) async {
    final pfpUrl = await _repository.uploadProfilePicture(filePath);
    return pfpUrl.isNotEmpty ? pfpUrl : null;
  }
}
