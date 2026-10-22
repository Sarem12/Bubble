import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/emoji/emoji.dart';
import '../widgets/settings_group.dart';
import '../controllers/settings_controller.dart';

class FeedSettingsScreen extends ConsumerWidget {
  const FeedSettingsScreen({super.key});

  static const _defaultQuickReactions = ['❤️', '😂', '🔥', '👍', '😮'];
  static const _doubleTapChoices = [
    '❤️',
    '😂',
    '🔥',
    '👍',
    '😮',
    '👏',
    '😢',
    'none',
    ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    final notifier = ref.read(settingsControllerProvider.notifier);
    final topReactions = settings?.topReactions.isNotEmpty == true
        ? settings!.topReactions
        : _defaultQuickReactions;
    final doubleTap = settings?.doubleTapReaction ?? '❤️';
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personalization')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SettingsGroup(
            title: 'Appearance',
              children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                subtitle: Text(_themeLabel(themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final value = await showSettingsChoice<ThemeMode>(
                    context: context,
                    title: 'Theme',
                    selected: themeMode,
                    options: const [
                      (
                        ThemeMode.system,
                        'System default',
                        'Follow your device setting',
                      ),
                      (ThemeMode.light, 'Light', ''),
                      (ThemeMode.dark, 'Dark', ''),
                    ],
                  );
                  if (value != null) notifier.setThemeMode(value);
                },
                ),
              ],
            ),
          SettingsGroup(
            title: 'Reactions',
              children: [
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Double-tap reaction'),
                subtitle: Text(doubleTap == 'none' ? 'Disabled' : doubleTap),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final value = await showSettingsChoice<String>(
                    context: context,
                    title: 'Double-tap reaction',
                    selected: doubleTap,
                    options: [
                      for (final emoji in _doubleTapChoices)
                        (emoji, emoji == 'none' ? 'Off' : emoji, ''),
                      ('custom', 'Choose another emoji', ''),
              ],
                  );
                  if (value == null) return;
                  if (value == 'custom') {
                    BubbleEmojiPicker.showModalString(
                      context,
                      initialCategory: EmojiCategory.system,
                      onEmojiSelected: notifier.setDoubleTapReaction,
                    );
                  } else {
                    notifier.setDoubleTapReaction(value);
                  }
              },
                      ),
              const Divider(height: 1, indent: 56),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                      'Quick reactions',
                      style: Theme.of(context).textTheme.titleSmall,
                            ),
                    const SizedBox(height: 4),
                          Text(
                      'Choose up to five reactions shown in reaction menus.',
                      style: Theme.of(context).textTheme.bodySmall,
                            ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final emoji in topReactions)
                          InputChip(
                            label: Text(emoji),
                            onDeleted: topReactions.length <= 1
                                ? null
                                : () => _saveReactions(
                                    context,
                                    notifier,
                                    topReactions
                                        .where((item) => item != emoji)
                                        .toList(),
                          ),
                      ),
                        if (topReactions.length < 5)
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            onPressed: () => BubbleEmojiPicker.showModalString(
                              context,
                              initialCategory: EmojiCategory.system,
                              onEmojiSelected: (emoji) {
                                if (!topReactions.contains(emoji)) {
                                  _saveReactions(context, notifier, [
                                    ...topReactions,
                                    emoji,
                                  ]);
                                }
                              },
                    ),
                        ),
                        ActionChip(
                          label: const Text('Reset'),
                          onPressed: () => _saveReactions(
                            context,
                            notifier,
                            _defaultQuickReactions,
                      ),
                    ),
                  ],
                ),
        ],
      ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  static Future<void> _saveReactions(
    BuildContext context,
    SettingsController notifier,
    List<String> values,
  ) async {
    try {
      await notifier.updateSetting('top_reactions', values);
    } catch (_) {
      if (context.mounted)
        UiHelpers.showError(context, 'Could not save reactions. Try again.');
  }
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System default',
  };
}
