import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../search/data/repositories/search_repository_impl.dart';
import '../../../search/domain/entities/bubble.dart';
import '../controllers/profile_controller.dart';
import '../widgets/settings_group.dart';

final _myBubblesProvider = FutureProvider.family<List<Bubble>, String>((
  ref,
  userId,
) {
  return ref.read(profileRepositoryProvider).getUserBubbles(userId);
});

class BubbleNotificationSettingsScreen extends ConsumerWidget {
  const BubbleNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;
    final profileId = profile?.id;
    final bubbles = profileId == null
        ? null
        : ref.watch(_myBubblesProvider(profileId));
    return Scaffold(
      appBar: AppBar(title: const Text('Bubble notifications')),
      body: bubbles == null
          ? const Center(child: CircularProgressIndicator())
          : bubbles.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => SettingsLoadError(
                message: 'Could not load your Bubbles.',
                onRetry: () => ref.invalidate(_myBubblesProvider(profileId!)),
              ),
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text('Join a Bubble to manage its notifications.'),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        Text(
                          'Choose which Bubbles can send you activity alerts.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SettingsGroup(
                          title: 'Your Bubbles',
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) const Divider(height: 1, indent: 16),
                              SwitchListTile(
                                title: Text(
                                  items[i].name.isEmpty
                                      ? 'Personal Bubble'
                                      : '#${items[i].name}',
                                ),
                                subtitle: Text(items[i].type.toLowerCase()),
                                value: items[i].notificationsEnabled ?? true,
                                onChanged: (enabled) async {
                                  try {
                                    await ref
                                        .read(searchRepositoryProvider)
                                        .updateBubbleNotifications(
                                          items[i].id,
                                          enabled,
                                        );
                                    ref.invalidate(
                                      _myBubblesProvider(profileId!),
                                    );
                                  } catch (_) {
                                    if (context.mounted)
                                      UiHelpers.showError(
                                        context,
                                        'Could not save this setting.',
                                      );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
            ),
    );
  }
}
