import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../search/domain/entities/bubble.dart';
import '../../data/datasources/friend_remote_datasource.dart';
import '../controllers/profile_controller.dart';
import '../widgets/settings_group.dart';

class FriendSettingsListScreen extends ConsumerWidget {
  const FriendSettingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Friend settings')),
      body: friends.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => SettingsLoadError(
          message: 'Could not load friends.',
          onRetry: () => ref.invalidate(friendsListProvider),
        ),
        data: (items) => items.isEmpty
            ? const Center(
                child: Text('Add friends to manage friend-specific settings.'),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final first = (item['friend_first_name'] ?? '').toString();
                  final last = (item['friend_last_name'] ?? '').toString();
                  final displayName = '$first $last'.trim();
                  final name = displayName.isEmpty
                      ? '@${item['friend_username'] ?? 'friend'}'
                      : displayName;
                  final id = (item['friend_id'] ?? item['target_user_id'] ?? '')
                      .toString();
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(name),
                    subtitle: Text('@${item['friend_username'] ?? ''}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: id.isEmpty
                        ? null
                        : () => context.push('/profile/settings/friends/$id'),
                  );
                },
              ),
      ),
    );
  }
}

class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked accounts')),
      body: blocked.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => SettingsLoadError(
          message: 'Could not load blocked accounts.',
          onRetry: () => ref.invalidate(blockedUsersProvider),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('You have no blocked accounts.'))
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final user = items[index];
                  final first = (user['first_name'] ?? '').toString();
                  final last = (user['last_name'] ?? '').toString();
                  final fullName = '$first $last'.trim();
                  final id = (user['id'] ?? '').toString();
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(
                      fullName.isEmpty
                          ? '@${user['username'] ?? 'user'}'
                          : fullName,
                    ),
                    subtitle: Text('@${user['username'] ?? ''}'),
                    trailing: TextButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(friendRemoteDataSourceProvider)
                              .unblock(id);
                          ref.invalidate(blockedUsersProvider);
                        } catch (_) {
                          if (context.mounted)
                            UiHelpers.showError(
                              context,
                              'Could not unblock this account.',
                            );
                        }
                      },
                      child: const Text('Unblock'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class FriendSettingsScreen extends ConsumerWidget {
  final String friendId;
  const FriendSettingsScreen({super.key, required this.friendId});

  static const _triState = [
    ('AUTOMATIC', 'Automatic', 'Follow Bubble’s default behavior'),
    ('ON', 'On', 'Always allow'),
    ('OFF', 'Off', 'Turn this off for this friend'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Friend settings')),
      body: friends.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => SettingsLoadError(
          message: 'Could not load this friend.',
          onRetry: () => ref.invalidate(friendsListProvider),
        ),
        data: (items) {
          Map<String, dynamic>? friend;
          for (final item in items) {
            if ((item['friend_id'] ?? item['target_user_id']).toString() ==
                friendId) {
              friend = item;
              break;
            }
          }
          if (friend == null)
            return const Center(child: Text('Friend not found.'));
          final fullName =
              '${friend['friend_first_name'] ?? ''} ${friend['friend_last_name'] ?? ''}'
                  .trim();
          final name = fullName.isEmpty
              ? '@${friend['friend_username'] ?? 'friend'}'
              : fullName;
          final exceptions = _stringList(friend['exception_bubbles']);
          final inviteExceptions = _stringList(
            friend['invite_exception_bubbles'],
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              SettingsGroup(
                title: 'Friend',
                children: [
                  SwitchListTile(
                    title: const Text('Best Friend'),
                    subtitle: const Text(
                      'Include this person in your Best Friends audience',
                    ),
                    value: friend['is_bestfriend'] == true,
                    onChanged: (value) =>
                        _update(context, ref, {'is_bestfriend': value}),
                  ),
                  const Divider(height: 1, indent: 16),
                  SwitchListTile(
                    title: const Text('Hide their posts from your feed'),
                    value: friend['ignore_in_feed'] == true,
                    onChanged: (value) =>
                        _update(context, ref, {'ignore_in_feed': value}),
                  ),
                ],
              ),
              SettingsGroup(
                title: 'Notifications from this friend',
                children: [
                  _choice(
                    context,
                    ref,
                    'Post notifications',
                    'notification_state',
                    (friend['notification_state'] ?? 'AUTOMATIC').toString(),
                  ),
                  const Divider(height: 1, indent: 16),
                  _exceptionRow(
                    context,
                    ref,
                    'Apply to Bubbles',
                    exceptions,
                    'exception_bubbles',
                  ),
                ],
              ),
              SettingsGroup(
                title: 'Bubble invitations from this friend',
                children: [
                  _choice(
                    context,
                    ref,
                    'Invitation preference',
                    'invite_state',
                    (friend['invite_state'] ?? 'AUTOMATIC').toString(),
                  ),
                  const Divider(height: 1, indent: 16),
                  _exceptionRow(
                    context,
                    ref,
                    'Apply to Bubbles',
                    inviteExceptions,
                    'invite_exception_bubbles',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _choice(
    BuildContext context,
    WidgetRef ref,
    String title,
    String key,
    String value,
  ) => ListTile(
    title: Text(title),
    subtitle: Text(
      _triState
          .firstWhere(
            (option) => option.$1 == value,
            orElse: () => _triState.first,
          )
          .$2,
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      final selected = await showSettingsChoice<String>(
        context: context,
        title: title,
        selected: value,
        options: _triState,
      );
      if (selected != null) _update(context, ref, {key: selected});
    },
  );

  Widget _exceptionRow(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<String> selected,
    String key,
  ) => ListTile(
    title: Text(title),
    subtitle: Text(
      selected.isEmpty ? 'All Bubbles' : '${selected.length} selected',
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      final profile = ref.read(profileControllerProvider).value;
      if (profile == null) return;
      try {
        final bubbles = await ref
            .read(profileRepositoryProvider)
            .getUserBubbles(profile.id);
        if (!context.mounted) return;
        final updated = await _chooseBubbles(context, bubbles, selected);
        if (updated != null) await _update(context, ref, {key: updated});
      } catch (_) {
        if (context.mounted)
          UiHelpers.showError(context, 'Could not load your Bubbles.');
      }
    },
  );

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> payload,
  ) async {
    try {
      await ref
          .read(friendRemoteDataSourceProvider)
          .updateSettings(friendId, payload);
      ref.invalidate(friendsListProvider);
    } catch (_) {
      if (context.mounted)
        UiHelpers.showError(context, 'Could not save this friend setting.');
    }
  }

  static Future<List<String>?> _chooseBubbles(
    BuildContext context,
    List<Bubble> bubbles,
    List<String> current,
  ) {
    final selected = current.toSet();
    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Choose Bubbles'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final bubble in bubbles)
                  CheckboxListTile(
                    title: Text(
                      bubble.name.isEmpty ? 'Unnamed Bubble' : bubble.name,
                    ),
                    value: selected.contains(bubble.id),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        selected.add(bubble.id);
                      } else {
                        selected.remove(bubble.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected.toList()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _stringList(dynamic value) =>
      value is List ? value.map((item) => item.toString()).toList() : const [];
}
