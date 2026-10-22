import 'package:flutter/material.dart';

/// Animation style for animated emojis
enum EmojiAnimationType {
  none,
  pulse,      // Gentle rhythmic breathing scale
  bounce,     // Spring up/down overshoot bounce
  wobble,     // Soft rotation tilt back and forth (like chuckle / laugh)
  heartbeat,  // Double-thump heartbeat cadence (perfect for love/heart)
  sparkle,    // Shimmering scale & opacity flash
  flicker,    // Dynamic flame jitter & warmth vibration
  float,      // Smooth drifting sinusoidal floating (great for bubbles)
  spin,       // Smooth continuous or periodic rotation
  glow,       // Radial glow pulse
}

/// Category taxonomy for emojis
enum EmojiCategory {
  recent,
  system,
  animated,
  smileys,
  gestures,
  hearts,
  reactions,
  food,
  activities,
  objects,
  symbols,
}

/// Category metadata containing display name and icon
class EmojiCategoryMeta {
  final EmojiCategory category;
  final String label;
  final IconData icon;

  const EmojiCategoryMeta({
    required this.category,
    required this.label,
    required this.icon,
  });

  static const List<EmojiCategoryMeta> all = [
    EmojiCategoryMeta(
      category: EmojiCategory.recent,
      label: 'Recent',
      icon: Icons.history_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.system,
      label: 'Bubble',
      icon: Icons.bubble_chart_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.animated,
      label: 'Animated',
      icon: Icons.auto_awesome_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.smileys,
      label: 'Smileys',
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.gestures,
      label: 'Gestures',
      icon: Icons.waving_hand_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.hearts,
      label: 'Hearts',
      icon: Icons.favorite_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.reactions,
      label: 'Reactions',
      icon: Icons.local_fire_department_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.food,
      label: 'Food',
      icon: Icons.lunch_dining_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.activities,
      label: 'Activities',
      icon: Icons.sports_soccer_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.objects,
      label: 'Objects',
      icon: Icons.lightbulb_rounded,
    ),
    EmojiCategoryMeta(
      category: EmojiCategory.symbols,
      label: 'Symbols',
      icon: Icons.stars_rounded,
    ),
  ];
}

/// Represents any emoji in Bubble (Unicode, Animated, or Custom System)
class BubbleEmoji {
  /// The raw code transmitted over network and saved in database.
  /// Standard Unicode: '❤️', '🔥', '😂'
  /// System custom emojis: ':bubble:', ':bubble_party:', ':bubble_fire:'
  final String code;

  /// Human readable display name, e.g. 'Sparkling Bubble', 'Heart'
  final String name;

  /// Primary category
  final EmojiCategory category;

  /// Keywords for real-time search
  final List<String> keywords;

  /// Whether this emoji is animated
  final bool isAnimated;

  /// Animation style applied when rendered
  final EmojiAnimationType animationType;

  /// True if this is an app-specific custom system emoji
  final bool isSystem;

  /// Optional custom builder for vector / canvas / custom animation rendering
  final Widget Function(BuildContext context, double size, bool animate)? customBuilder;

  /// Optional asset path for local asset based emojis
  final String? assetPath;

  /// Optional remote network image URL for future custom emoji packs
  final String? networkUrl;

  const BubbleEmoji({
    required this.code,
    required this.name,
    required this.category,
    this.keywords = const [],
    this.isAnimated = true,
    this.animationType = EmojiAnimationType.pulse,
    this.isSystem = false,
    this.customBuilder,
    this.assetPath,
    this.networkUrl,
  });

  BubbleEmoji copyWith({
    String? code,
    String? name,
    EmojiCategory? category,
    List<String>? keywords,
    bool? isAnimated,
    EmojiAnimationType? animationType,
    bool? isSystem,
    Widget Function(BuildContext context, double size, bool animate)? customBuilder,
    String? assetPath,
    String? networkUrl,
  }) {
    return BubbleEmoji(
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      isAnimated: isAnimated ?? this.isAnimated,
      animationType: animationType ?? this.animationType,
      isSystem: isSystem ?? this.isSystem,
      customBuilder: customBuilder ?? this.customBuilder,
      assetPath: assetPath ?? this.assetPath,
      networkUrl: networkUrl ?? this.networkUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BubbleEmoji && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'BubbleEmoji(code: $code, name: $name, isSystem: $isSystem, isAnimated: $isAnimated)';
}
