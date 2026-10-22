import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../widgets/settings_group.dart';
import '../controllers/settings_controller.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  static const _chatOptions = [
    (
      'ALL_FRIENDS',
      'All friends',
      'Any accepted friend can start a conversation',
    ),
    ('BEST_FRIENDS', 'Best Friends', 'Only people marked as Best Friends'),
    ('NOBODY', 'Nobody', 'Prevent new direct conversations'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    final notifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                  'Manage who can start a new direct conversation with you.',
                  style: Theme.of(context).textTheme.bodyMedium,
              ),
                SettingsGroup(
                  title: 'Messages',
            children: [
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: const Text('Allow new chats'),
                      subtitle: Text(
                        _chatOptions
                            .firstWhere(
                              (option) => option.$1 == settings.allowNewChats,
                              orElse: () => _chatOptions.first,
                            )
                            .$2,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final selected = await showSettingsChoice<String>(
                  context: context,
                          title: 'Allow new chats',
                          selected: settings.allowNewChats,
                          options: _chatOptions,
    );
                        if (selected == null) return;
                        try {
                          await notifier.updateSetting(
                            'allow_new_chats',
                            selected,
    );
                        } catch (_) {
                          if (context.mounted)
                            UiHelpers.showError(
                              context,
                              'Could not save this setting. Try again.',
        );
        }
      },
                ),
                  ],
              ),
                SettingsGroup(
                  title: 'Friends',
                children: [
                    ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('Friend-specific settings'),
                      subtitle: const Text(
                        'Best Friends, feed, notifications, and Bubble invitations',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/profile/settings/friends'),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('Blocked accounts'),
                      subtitle: const Text('Review or unblock people'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/profile/settings/blocked'),
                  ),
                ],
              ),
          ],
        ),
    );
  }
}
