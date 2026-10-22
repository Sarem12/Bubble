import 'package:flutter/material.dart';
import 'bubble_emoji.dart';
import 'system_emojis_painter.dart';

/// Central registry for Bubble System Emojis.
/// Allows registration of custom emojis, both static and animated,
/// and provides extensibility for future system emojis or remote packs.
class SystemEmojiRegistry {
  static final Map<String, BubbleEmoji> _registry = {};
  static bool _initialized = false;

  /// Ensure default system emojis are registered
  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    // 1. Original Bubble Orb
    register(
      BubbleEmoji(
        code: ':bubble:',
        name: 'Bubble Orb',
        category: EmojiCategory.system,
        keywords: ['bubble', 'logo', 'orb', 'sphere', 'aqua', 'glow', 'blue'],
        isAnimated: true,
        animationType: EmojiAnimationType.float,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubbleOrbWidget(size: size, animate: animate),
      ),
    );

    // 2. Bubble Party / Fiesta
    register(
      BubbleEmoji(
        code: ':bubble_party:',
        name: 'Bubble Fiesta',
        category: EmojiCategory.system,
        keywords: ['party', 'celebrate', 'confetti', 'fiesta', 'fun', 'happy', 'rainbow'],
        isAnimated: true,
        animationType: EmojiAnimationType.pulse,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubblePartyWidget(size: size, animate: animate),
      ),
    );

    // 3. Bubble Fire
    register(
      BubbleEmoji(
        code: ':bubble_fire:',
        name: 'Bubble Flame',
        category: EmojiCategory.system,
        keywords: ['fire', 'flame', 'lit', 'hot', 'burn', 'warm'],
        isAnimated: true,
        animationType: EmojiAnimationType.flicker,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubbleFireWidget(size: size, animate: animate),
      ),
    );

    // 4. Bubble Love
    register(
      BubbleEmoji(
        code: ':bubble_love:',
        name: 'Bubble Heart',
        category: EmojiCategory.system,
        keywords: ['love', 'heart', 'romance', 'like', 'sweet', 'cute', 'pink'],
        isAnimated: true,
        animationType: EmojiAnimationType.heartbeat,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubbleLoveWidget(size: size, animate: animate),
      ),
    );

    // 5. Bubble Stellar / Star
    register(
      BubbleEmoji(
        code: ':bubble_star:',
        name: 'Bubble Celestial',
        category: EmojiCategory.system,
        keywords: ['star', 'stellar', 'cosmic', 'space', 'gold', 'sparkle'],
        isAnimated: true,
        animationType: EmojiAnimationType.spin,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubbleStarWidget(size: size, animate: animate),
      ),
    );

    // 6. Bubble Cool
    register(
      BubbleEmoji(
        code: ':bubble_cool:',
        name: 'Bubble Cool',
        category: EmojiCategory.system,
        keywords: ['cool', 'sunglasses', 'shades', 'slick', 'awesome', 'smirk'],
        isAnimated: true,
        animationType: EmojiAnimationType.wobble,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubbleCoolWidget(size: size, animate: animate),
      ),
    );

    // 7. Bubble Gem / Diamond
    register(
      BubbleEmoji(
        code: ':bubble_gem:',
        name: 'Bubble Diamond',
        category: EmojiCategory.system,
        keywords: ['gem', 'diamond', 'crystal', 'shine', 'prism', 'valuable', 'jewel'],
        isAnimated: true,
        animationType: EmojiAnimationType.sparkle,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubbleGemWidget(size: size, animate: animate),
      ),
    );

    // 8. Bubble Rocket
    register(
      BubbleEmoji(
        code: ':bubble_rocket:',
        name: 'Bubble Rocket',
        category: EmojiCategory.system,
        keywords: ['rocket', 'launch', 'blast', 'space', 'ship', 'moon', 'speed'],
        isAnimated: true,
        animationType: EmojiAnimationType.bounce,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubbleRocketWidget(size: size, animate: animate),
      ),
    );

    // 9. Bubble 100
    register(
      BubbleEmoji(
        code: ':bubble_100:',
        name: 'Bubble 100',
        category: EmojiCategory.system,
        keywords: ['100', 'score', 'perfect', 'hundred', 'keepit100', 'fire'],
        isAnimated: true,
        animationType: EmojiAnimationType.pulse,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            Bubble100Widget(size: size, animate: animate),
      ),
    );

    // 10. Bubble Verified
    register(
      BubbleEmoji(
        code: ':bubble_verified:',
        name: 'Bubble Verified',
        category: EmojiCategory.system,
        keywords: ['verified', 'check', 'badge', 'official', 'shield', 'cyan'],
        isAnimated: true,
        animationType: EmojiAnimationType.glow,
        isSystem: true,
        customBuilder: (context, size, animate) =>
            BubbleVerifiedWidget(size: size, animate: animate),
      ),
    );
  }

  /// Register a new system emoji at runtime
  static void register(BubbleEmoji emoji) {
    _registry[emoji.code] = emoji;
  }

  /// Register multiple system emojis
  static void registerAll(List<BubbleEmoji> emojis) {
    for (final e in emojis) {
      register(e);
    }
  }

  /// Check whether a code corresponds to a registered system emoji
  static bool isSystemEmoji(String code) {
    _ensureInitialized();
    final clean = code.trim();
    if (_registry.containsKey(clean)) return true;
    if (_registry.containsKey(':$clean:')) return true;
    if (clean.startsWith(':') && clean.endsWith(':')) {
      final uncolon = clean.substring(1, clean.length - 1);
      if (_registry.containsKey(uncolon)) return true;
    }
    return false;
  }

  /// Get a system emoji by its code
  static BubbleEmoji? get(String code) {
    _ensureInitialized();
    final clean = code.trim();
    if (_registry.containsKey(clean)) return _registry[clean];
    if (_registry.containsKey(':$clean:')) return _registry[':$clean:'];
    if (clean.startsWith(':') && clean.endsWith(':')) {
      final uncolon = clean.substring(1, clean.length - 1);
      if (_registry.containsKey(uncolon)) return _registry[uncolon];
    }
    return null;
  }

  /// Retrieve all registered system emojis
  static List<BubbleEmoji> get allSystemEmojis {
    _ensureInitialized();
    return List.unmodifiable(_registry.values);
  }

  /// Dynamically register a remote image emoji (e.g. from an API pack or server)
  static void registerRemoteEmoji({
    required String code,
    required String name,
    required String networkUrl,
    List<String> keywords = const [],
    bool isAnimated = false,
  }) {
    register(
      BubbleEmoji(
        code: code,
        name: name,
        category: EmojiCategory.system,
        keywords: keywords,
        isAnimated: isAnimated,
        networkUrl: networkUrl,
        isSystem: true,
        customBuilder: (context, size, animate) => Image.network(
          networkUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(Icons.broken_image, size: size),
        ),
      ),
    );
  }

  /// Dynamically register a local asset emoji
  static void registerAssetEmoji({
    required String code,
    required String name,
    required String assetPath,
    List<String> keywords = const [],
    bool isAnimated = false,
  }) {
    register(
      BubbleEmoji(
        code: code,
        name: name,
        category: EmojiCategory.system,
        keywords: keywords,
        isAnimated: isAnimated,
        assetPath: assetPath,
        isSystem: true,
        customBuilder: (context, size, animate) => Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Search system emojis by keywords or name
  static List<BubbleEmoji> search(String query) {
    _ensureInitialized();
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return allSystemEmojis;

    return _registry.values.where((emoji) {
      if (emoji.name.toLowerCase().contains(cleanQuery)) return true;
      if (emoji.code.toLowerCase().contains(cleanQuery)) return true;
      return emoji.keywords.any((k) => k.toLowerCase().contains(cleanQuery));
    }).toList();
  }

  /// Formats or resolves an emoji shortcode/system code into a displayable Unicode string
  static String toDisplayChar(String? code) {
    if (code == null || code.isEmpty) return '❤️';
    final clean = code.trim();

    switch (clean) {
      case 'heart': return '❤️';
      case 'laugh': return '😂';
      case 'fire': return '🔥';
      case 'thumbs_up': return '👍';
      case ':bubble:': return '🫧';
      case ':bubble_love:': return '💖';
      case ':bubble_fire:': return '🔥';
      case ':bubble_party:': return '🎉';
      case ':bubble_star:': return '⭐';
      case ':bubble_cool:': return '😎';
      case ':bubble_gem:': return '💎';
      case ':bubble_rocket:': return '🚀';
      case ':bubble_100:': return '💯';
      case ':bubble_verified:': return '✔️';
      default: return clean;
    }
  }
}

