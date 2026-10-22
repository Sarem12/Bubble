import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../widgets/settings_group.dart';
import '../controllers/settings_controller.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _deliveryOptions = [
    ('AUTOMATIC', 'Automatic', 'Use Bubble’s default delivery behavior'),
    ('ON', 'On', 'Allow this type of alert'),
    ('OFF', 'Off', 'Turn this type of alert off'),
  ];
  static const _audiences = [
    ('EVERYONE', 'Everyone', ''),
    ('FRIENDS', 'Friends', ''),
    ('BUBBLE_MEMBERS', 'Bubble members', ''),
    ('FRIENDS_AND_BUBBLES', 'Friends and Bubble members', ''),
    ('BEST_FRIENDS', 'Best Friends', ''),
    ('BEST_FRIENDS_AND_BUBBLES', 'Best Friends and Bubble members', ''),
    ('NOBODY', 'Nobody', ''),
  ];
  static const _messageAudiences = [
    ('ALL_FRIENDS', 'All friends', ''),
    ('BEST_FRIENDS', 'Best Friends', ''),
    ('NOBODY', 'Nobody', ''),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    final settings = state.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                  'Choose when you’re notified and whose activity can alert you.',
                  style: Theme.of(context).textTheme.bodyMedium,
        ),
                SettingsGroup(
                  title: 'Delivery',
                  children: [
                    _choiceTile(
                      context,
                      notifier,
                      'All notifications',
                      'notification_state',
                      settings.notificationState,
                      _deliveryOptions,
                    ),
                    const Divider(height: 1, indent: 56),
                    _choiceTile(
                      context,
                      notifier,
                      'Invitations',
                      'invitation_state',
                      settings.invitationState,
                      _deliveryOptions,
                    ),
                  ],
                ),
                SettingsGroup(
                  title: 'Activity',
                  children: [
                    _choiceTile(
                      context,
                      notifier,
                      'Reactions',
                      'global_reaction_notifications',
                      settings.globalReactionNotifications,
                      _audiences,
                    ),
                    const Divider(height: 1, indent: 56),
                    _choiceTile(
                      context,
                      notifier,
                      'Comments',
                      'global_comment_notifications',
                      settings.globalCommentNotifications,
                      _audiences,
                    ),
                    const Divider(height: 1, indent: 56),
                    _choiceTile(
                      context,
                      notifier,
                      'Replies',
                      'global_reply_notifications',
                      settings.globalReplyNotifications,
                      _audiences,
                    ),
                  ],
                ),
                SettingsGroup(
                  title: 'Messages',
                  children: [
                    _choiceTile(
                      context,
                      notifier,
                      'Message alerts',
                      'message_notifications',
                      settings.messageNotifications,
                      _messageAudiences,
              ),
            ],
      ),
                SettingsGroup(
                  title: 'Bubbles and posts',
          children: [
                    ListTile(
                      title: const Text('Bubble notifications'),
                      subtitle: const Text(
                        'Choose which Bubbles can send alerts',
              ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        '/profile/settings/bubble-notifications',
                    ),
                  ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      title: const Text('Post notifications'),
                      subtitle: const Text(
                        'Set alerts separately for each post',
                    ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/profile/settings/post-notifications'),
                  ),
                ],
              ),
          ],
        ),
    );
  }

  Widget _choiceTile(
    BuildContext context,
    SettingsController notifier,
    String title,
    String key,
    String value,
    List<(String, String, String)> options,
  ) => ListTile(
    title: Text(title),
    subtitle: Text(_label(value, options)),
    trailing: const Icon(Icons.chevron_right),
      onTap: () async {
      final selected = await showSettingsChoice<String>(
          context: context,
          title: title,
        selected: value,
          options: options,
        );
      if (selected == null) return;
      try {
        await notifier.updateSetting(key, selected);
      } catch (_) {
        if (context.mounted)
          UiHelpers.showError(
            context,
            'Could not save this setting. Try again.',
          );
        }
      },
    );

  static String _label(String code, List<(String, String, String)> options) {
    for (final (value, label, _) in options) {
      if (value == code) return label;
        }
    return 'Automatic';
  }
}
