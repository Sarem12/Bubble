import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/utils/safe_haptics.dart';
import '../providers/dynamic_dock_provider.dart';
import 'bubble_emoji.dart';
import 'system_emoji_registry.dart';
import 'emoji_data.dart';
import 'app_emoji.dart';
import '../widgets/liquid_glass.dart';

const String _kRecentEmojisKey = 'bubble_recent_emojis_v1';

/// A modern, extensible, animated Emoji Picker for the Bubble app.
/// Supports standard Unicode emojis, live animated emojis, and custom System emojis.
class BubbleEmojiPicker extends StatefulWidget {
  final ValueChanged<BubbleEmoji> onEmojiSelected;
  final double height;
  final bool showSearchBar;
  final bool showPreview;
  final EmojiCategory initialCategory;

  const BubbleEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.height = 380,
    this.showSearchBar = true,
    this.showPreview = true,
    this.initialCategory = EmojiCategory.system,
  });

  /// Shows the picker inside the Dynamic Liquid Dock
  static Future<BubbleEmoji?> showModal(
    BuildContext context, {
    required ValueChanged<BubbleEmoji> onEmojiSelected,
    EmojiCategory initialCategory = EmojiCategory.system,
    String? title,
  }) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(dynamicDockProvider.notifier).openEmojiPicker(
        onEmojiSelected: onEmojiSelected,
        initialCategory: initialCategory,
        title: title,
      );
      return null;
    } catch (_) {
      return showBubbleModalBottomSheet<BubbleEmoji>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _EmojiPickerBottomSheet(
          onEmojiSelected: (emoji) {
            onEmojiSelected(emoji);
            Navigator.of(ctx).pop(emoji);
          },
          initialCategory: initialCategory,
        ),
      );
    }
  }

  /// Convenience wrapper returning the raw emoji string (e.g. '❤️' or ':bubble:')
  static Future<String?> showModalString(
    BuildContext context, {
    required ValueChanged<String> onEmojiSelected,
    EmojiCategory initialCategory = EmojiCategory.system,
    String? title,
  }) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(dynamicDockProvider.notifier).openEmojiPicker(
        onEmojiSelected: (emoji) => onEmojiSelected(emoji.code),
        initialCategory: initialCategory,
        title: title,
      );
      return null;
    } catch (_) {
      return showBubbleModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _EmojiPickerBottomSheet(
          onEmojiSelected: (emoji) {
            onEmojiSelected(emoji.code);
            Navigator.of(ctx).pop(emoji.code);
          },
          initialCategory: initialCategory,
        ),
      );
    }
  }

  @override
  State<BubbleEmojiPicker> createState() => _BubbleEmojiPickerState();
}

class _BubbleEmojiPickerState extends State<BubbleEmojiPicker> {
  final TextEditingController _searchController = TextEditingController();
  late EmojiCategory _selectedCategory;
  List<BubbleEmoji> _recentEmojis = [];
  BubbleEmoji? _previewEmoji;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadRecents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kRecentEmojisKey);
      if (list != null && list.isNotEmpty) {
        final loaded = list
            .map((code) => EmojiData.findByCode(code))
            .whereType<BubbleEmoji>()
            .toList();
        if (mounted) setState(() => _recentEmojis = loaded);
      } else {
        // Defaults if no recents
        _recentEmojis = [
          SystemEmojiRegistry.get(':bubble:')!,
          SystemEmojiRegistry.get(':bubble_love:')!,
          SystemEmojiRegistry.get(':bubble_fire:')!,
          SystemEmojiRegistry.get(':bubble_party:')!,
          EmojiData.findByCode('❤️')!,
          EmojiData.findByCode('🔥')!,
          EmojiData.findByCode('😂')!,
          EmojiData.findByCode('👍')!,
          EmojiData.findByCode('✨')!,
          EmojiData.findByCode('🚀')!,
        ];
      }
    } catch (_) {
      // Fallback
    }
  }

  Future<void> _saveRecent(BubbleEmoji emoji) async {
    try {
      final updated = [
        emoji,
        ..._recentEmojis.where((e) => e.code != emoji.code),
      ].take(24).toList();

      setState(() => _recentEmojis = updated);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _kRecentEmojisKey,
        updated.map((e) => e.code).toList(),
      );
    } catch (_) {}
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _selectEmoji(BubbleEmoji emoji) {
    _saveRecent(emoji);
    widget.onEmojiSelected(emoji);
  }

  List<BubbleEmoji> _getDisplayEmojis() {
    if (_searchQuery.isNotEmpty) {
      return EmojiData.search(_searchQuery);
    }
    if (_selectedCategory == EmojiCategory.recent) {
      return _recentEmojis;
    }
    return EmojiData.getByCategory(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final emojis = _getDisplayEmojis();

    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          // 1. Search Bar
          if (widget.showSearchBar) _buildSearchBar(context, isDark),

          // 2. Animated Category Selector Bar
          if (_searchQuery.isEmpty) _buildCategoryBar(isDark),

          // 3. Optional Live Preview Bar
          if (widget.showPreview && _previewEmoji != null)
            _buildPreviewBar(isDark),

          // 4. Emoji Grid
          Expanded(
            child: emojis.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (context, index) {
                      final item = emojis[index];
                      return _EmojiGridCell(
                        emoji: item,
                        onTap: () {
                          SafeHaptics.lightImpact();
                          _selectEmoji(item);
                        },
                        onLongPress: () {
                          SafeHaptics.selectionClick();
                          setState(() => _previewEmoji = item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        height: 40,
        color: Colors.transparent,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search all emojis...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            prefixIcon: Icon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 18,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, size: 16),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: EmojiCategoryMeta.all.length,
        itemBuilder: (context, idx) {
          final meta = EmojiCategoryMeta.all[idx];
          final isSelected = _selectedCategory == meta.category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                SafeHaptics.selectionClick();
                setState(() {
                  _selectedCategory = meta.category;
                  _previewEmoji = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: LiquidGlassTheme.pillBackground(context, isSelected: isSelected),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: LiquidGlassTheme.pillBorderColor(context, isSelected: isSelected),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      meta.icon,
                      size: 18,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meta.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewBar(bool isDark) {
    final emoji = _previewEmoji!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: LiquidGlassContainer(
        borderRadius: BorderRadius.circular(14),
        blur: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            AppEmoji(
              emoji: emoji.code,
              size: 30,
              animate: true,
            ),
            const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      emoji.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (emoji.isSystem) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SYSTEM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (emoji.isAnimated) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ANIMATED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  emoji.code,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 30),
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _selectEmoji(emoji),
            child: const Text('Select', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No emojis found for "$_searchQuery"',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// An interactive emoji grid cell with spring scale-tap animation
class _EmojiGridCell extends StatefulWidget {
  final BubbleEmoji emoji;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EmojiGridCell({
    required this.emoji,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_EmojiGridCell> createState() => _EmojiGridCellState();
}

class _EmojiGridCellState extends State<_EmojiGridCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.84)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.84, end: 1.16)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.16, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: widget.emoji.isSystem
                ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: AppEmoji(
            emoji: widget.emoji.code,
            size: widget.emoji.isSystem ? 28 : 26,
            animate: true,
            enableTapAnimation: true,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet container with grab handle
class _EmojiPickerBottomSheet extends StatelessWidget {
  final ValueChanged<BubbleEmoji> onEmojiSelected;
  final EmojiCategory initialCategory;

  const _EmojiPickerBottomSheet({
    required this.onEmojiSelected,
    this.initialCategory = EmojiCategory.system,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(28),
          blur: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Emoji Picker Widget
              BubbleEmojiPicker(
                height: 420,
                onEmojiSelected: onEmojiSelected,
                initialCategory: initialCategory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
