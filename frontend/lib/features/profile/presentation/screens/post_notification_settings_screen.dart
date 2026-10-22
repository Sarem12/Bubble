import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../home/data/repositories/post_repository_impl.dart';
import '../widgets/settings_group.dart';

final _myPostNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) {
    return ref.read(postRemoteDataSourceProvider).getMyNotificationSettings();
  },
);

class PostNotificationSettingsScreen extends ConsumerWidget {
  const PostNotificationSettingsScreen({super.key});
  static const _options = [
    ('AUTOMATIC', 'Automatic', 'Use the default behavior'),
    ('ON', 'On', 'Always send these alerts'),
    ('OFF', 'Off', 'Turn these alerts off'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(_myPostNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Post notifications')),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => SettingsLoadError(
          message: 'Could not load your posts.',
          onRetry: () => ref.invalidate(_myPostNotificationsProvider),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Your posts will appear here.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final post = items[index];
                  final content = (post['content'] ?? '').toString().trim();
                  final title = content.isEmpty
                      ? 'Photo or video post'
                      : content;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    child: ExpansionTile(
                      title: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('Notifications for this post'),
                      children: [
                        _settingRow(
                          context,
                          ref,
                          post,
                          'Reactions',
                          'reactions_notification',
                        ),
                        _settingRow(
                          context,
                          ref,
                          post,
                          'Comments',
                          'comments_notification',
                        ),
                        _settingRow(
                          context,
                          ref,
                          post,
                          'Replies',
                          'replies_notification',
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _settingRow(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> post,
    String title,
    String key,
  ) {
    final value = (post[key] ?? 'AUTOMATIC').toString();
    final label = _options
        .firstWhere(
          (option) => option.$1 == value,
          orElse: () => _options.first,
        )
        .$2;
    return ListTile(
      title: Text(title),
      subtitle: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final selected = await showSettingsChoice<String>(
          context: context,
          title: '$title notifications',
          selected: value,
          options: _options,
        );
        final id = (post['post_id'] ?? '').toString();
        if (selected == null || id.isEmpty) return;
        try {
          await ref
              .read(postRemoteDataSourceProvider)
              .updateNotificationSettings(id, {key: selected});
          ref.invalidate(_myPostNotificationsProvider);
        } catch (_) {
          if (context.mounted)
            UiHelpers.showError(context, 'Could not save this post setting.');
        }
      },
    );
  }
}
