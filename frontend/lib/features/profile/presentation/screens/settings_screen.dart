import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_group.dart';

export 'account_settings_screen.dart';
export 'appearance_settings_screen.dart';
export 'feed_settings_screen.dart';
export 'notification_settings_screen.dart';
export 'privacy_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
          if (profile != null)
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              child: ListTile(
                leading: UserAvatar(
                  radius: 24,
                  imageUrl: profile['profile_picture_url']?.toString() ?? '',
                ),
                title: Text(
                  '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                          .trim()
                          .isEmpty
                      ? '@${profile['username'] ?? 'user'}'
                      : '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                            .trim(),
                ),
                subtitle: Text('@${profile['username'] ?? ''}'),
                trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/profile/edit');
                        ref.read(profileControllerProvider.notifier).refresh();
                      },
                              ),
                              ),
          SettingsGroup(
            title: 'Your account',
                                children: [
              SettingsRow(
                icon: Icons.person_outline,
                title: 'Profile and account',
                subtitle: 'Profile details, security, and account deletion',
                onTap: () => context.push('/profile/settings/account'),
                      ),
              const Divider(height: 1, indent: 56),
              SettingsRow(
                icon: Icons.lock_outline,
                title: 'Privacy',
                subtitle: 'Messaging permissions and audience controls',
                onTap: () => context.push('/profile/settings/privacy'),
                    ),
                  ],
                ),
          SettingsGroup(
            title: 'Preferences',
                  children: [
              SettingsRow(
                icon: Icons.notifications_outlined,
                      title: 'Notifications',
                subtitle: 'Choose which alerts you receive',
                      onTap: () => context.push('/profile/settings/notifications'),
                    ),
              const Divider(height: 1, indent: 56),
              SettingsRow(
                icon: Icons.tune,
                title: 'Personalization',
                subtitle: 'Theme and reaction preferences',
                trailing: Text(_themeLabel(themeMode)),
                onTap: () => context.push('/profile/settings/personalization'),
                    ),
                  ],
                ),
          SettingsGroup(
            title: 'App',
                  children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Clear image cache'),
                subtitle: const Text('Free up temporary image memory'),
                      onTap: () {
                        PaintingBinding.instance.imageCache.clear();
                        PaintingBinding.instance.imageCache.clearLiveImages();
                  UiHelpers.showSuccess(context, 'Image cache cleared');
                      },
                    ),
              const Divider(height: 1, indent: 56),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About Bubble'),
                subtitle: Text('Version 1.0.0'),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () => _confirmLogout(context),
                        ),
                      ],
                    ),
    );
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };

  static Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to use this account.',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
            ),
          ],
        ),
    );
    if (confirm == true) {
                          await SecureStorage.clearAll();
      if (context.mounted) context.go('/login');
                          }
  }
}
