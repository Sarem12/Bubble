import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedBirthday;
  String _accountType = 'PUBLIC';
  String? _profilePictureUrl;
  bool _isSaving = false;
  bool _isUploadingPicture = false;
  bool _hasInitialized = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initializeFromProfile(dynamic profile) {
    if (_hasInitialized) return;
    _hasInitialized = true;

    _firstNameController.text = (profile['first_name'] ?? '').toString();
    _lastNameController.text = (profile['last_name'] ?? '').toString();
    _usernameController.text = (profile['username'] ?? '').toString();
    _bioController.text = (profile['bio'] ?? '').toString();
    _accountType = (profile['type'] ?? 'PUBLIC').toString();
    _profilePictureUrl = profile['profile_picture_url']?.toString();

    final birthdayStr = profile['birthday']?.toString();
    if (birthdayStr != null && birthdayStr.isNotEmpty) {
      try {
        _selectedBirthday = DateTime.parse(birthdayStr);
      } catch (_) {}
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPicture = true);

      final uploadedUrl = await ref
          .read(profileControllerProvider.notifier)
          .uploadProfilePicture(picked.path);

      if (mounted) {
        setState(() {
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            _profilePictureUrl = uploadedUrl;
          }
          _isUploadingPicture = false;
        });
        UiHelpers.showSuccess(context, "Profile picture uploaded!");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPicture = false);
        UiHelpers.showError(context, "Failed to upload picture: $e");
      }
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showBubbleModalBottomSheet(
      context: context,
      builder: (ctx) {
        return LiquidGlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.camera,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.image,
                      color: Colors.purpleAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profilePictureUrl != null &&
                    _profilePictureUrl!.isNotEmpty)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.trash,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _profilePictureUrl = '');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate =
        _selectedBirthday ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedBirthday = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text
        .trim()
        .replaceAll('@', '')
        .toLowerCase();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final bio = _bioController.text.trim();

    if (username.length < 3) {
      UiHelpers.showError(context, "Username must be at least 3 characters.");
      return;
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      UiHelpers.showError(
        context,
        "Username can only contain lowercase letters, numbers, and underscores.",
      );
      return;
    }

    final birthdayFormatted = _selectedBirthday != null
        ? DateFormat('yyyy-MM-dd').format(_selectedBirthday!)
        : '2000-01-01';

    setState(() => _isSaving = true);

    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
            username: username,
            firstName: firstName,
            lastName: lastName,
            bio: bio,
            birthday: birthdayFormatted,
            accountType: _accountType,
            profilePictureUrl: _profilePictureUrl ?? '',
          );

      if (mounted) {
        setState(() => _isSaving = false);
        UiHelpers.showSuccess(context, "Profile updated successfully!");
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        UiHelpers.showError(context, "Failed to update profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(profileControllerProvider);
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        title: const Text('Edit Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: LiquidGlassButton(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              label: 'Save',
              isLoading: _isSaving,
              onPressed: (_isSaving || _isUploadingPicture)
                  ? null
                  : _saveProfile,
            ),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: $err'),
              const SizedBox(height: 12),
              LiquidGlassButton(
                label: 'Retry',
                onPressed: () =>
                    ref.read(profileControllerProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (profile) {
          _initializeFromProfile(profile);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, topPadding + 14, 18, 40),
              child: Column(
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        UserAvatar(
                          radius: 52,
                          imageUrl: _profilePictureUrl ?? '',
                          heroTag: 'my_profile_avatar',
                        ),
                        if (_isUploadingPicture)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _isUploadingPicture
                                ? null
                                : _showImageSourceSheet,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                gradient:
                                    LiquidGlassTheme.primaryLiquidGradient(
                                      context: context,
                                    ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                PhosphorIconsFill.camera,
                                size: 16,
                                color: LiquidGlassTheme.primaryTextColor(
                                  context,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  LiquidGlassPill(
                    label: 'Change Photo',
                    icon: Icon(
                      PhosphorIconsRegular.image,
                      size: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onTap: _isUploadingPicture ? null : _showImageSourceSheet,
                  ),
                  const SizedBox(height: 24),

                  // Form inputs grouped in LiquidGlassContainers
                  LiquidGlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // First Name
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(
                              PhosphorIconsRegular.identificationBadge,
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'First name is required'
                              : null,
                        ),
                        const Divider(height: 1),
                        // Last Name
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icon(
                              PhosphorIconsRegular.identificationBadge,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(height: 1),
                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(PhosphorIconsRegular.at),
                            hintText: 'e.g. johndoe',
                            border: InputBorder.none,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Username is required';
                            if (v.trim().length < 3)
                              return 'At least 3 characters';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  LiquidGlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // Bio
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          maxLength: 160,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(PhosphorIconsRegular.pencilLine),
                            ),
                            hintText: 'Tell everyone a bit about yourself...',
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(height: 1),
                        DropdownButtonFormField<String>(
                          value: _accountType,
                          decoration: const InputDecoration(
                            labelText: 'Account privacy',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: InputBorder.none,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'PUBLIC',
                              child: Text('Public'),
                            ),
                            DropdownMenuItem(
                              value: 'PRIVATE',
                              child: Text('Private'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null)
                              setState(() => _accountType = value);
                          },
                        ),
                        const Divider(height: 1),
                        // Birthday
                        InkWell(
                          onTap: _pickBirthday,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  PhosphorIconsRegular.cake,
                                  color: Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Birthday',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedBirthday == null
                                            ? 'Select your birthday'
                                            : DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(_selectedBirthday!),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: _selectedBirthday == null
                                              ? Colors.grey
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  PhosphorIconsRegular.calendar,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: LiquidGlassButton(
                      height: 50,
                      label: 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: (_isSaving || _isUploadingPicture)
                          ? null
                          : _saveProfile,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
