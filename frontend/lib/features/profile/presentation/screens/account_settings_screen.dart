import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_group.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;
    final joined =
        profile?.createdAt?.toLocal().toString().split(' ').first ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile and account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SettingsGroup(
            title: 'Profile',
            children: [
              ListTile(
                leading: const Icon(Icons.devices_outlined),
                title: const Text('Devices'),
                subtitle: const Text('Review where your account is signed in'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile/settings/account/sessions'),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit profile'),
                subtitle: const Text(
                  'Name, username, photo, bio, birthday, and visibility',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push('/profile/edit');
                  ref.read(profileControllerProvider.notifier).refresh();
                },
              ),
            ],
          ),
          SettingsGroup(
            title: 'Security',
            children: [
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Change password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePassword(context, ref),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Account information',
            children: [
              ListTile(
                title: const Text('User ID'),
                subtitle: SelectableText(profile?.id ?? '—'),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                title: const Text('Username'),
                subtitle: Text('@${profile?.username ?? '—'}'),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(title: const Text('Joined'), subtitle: Text(joined)),
            ],
          ),
          const SizedBox(height: 24),
          SettingsGroup(
            title: 'Danger zone',
            children: [
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text(
                  'Permanently delete your account and content',
                ),
                onTap: () => _deleteAccount(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _changePassword(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your current password'
                    : null,
              ),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) => value == null || value.length < 10
                    ? 'Use at least 10 characters'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save == true && context.mounted) {
      try {
        await ref
            .read(authDataSourceProvider)
            .changePassword(oldController.text, newController.text);
        if (context.mounted) UiHelpers.showSuccess(context, 'Password changed');
      } catch (_) {
        if (context.mounted)
          UiHelpers.showError(
            context,
            'Could not change password. Check your current password and try again.',
          );
      }
    }
    oldController.dispose();
    newController.dispose();
  }

  static Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and Bubble content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(settingsControllerProvider.notifier).deleteAccount();
      await SecureStorage.clearAll();
      if (context.mounted) context.go('/login');
    } catch (_) {
      if (context.mounted)
        UiHelpers.showError(
          context,
          'Could not delete your account. Try again.',
        );
    }
  }
}
