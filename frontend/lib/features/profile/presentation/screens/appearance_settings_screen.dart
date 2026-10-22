import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/safe_haptics.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../controllers/settings_controller.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const LiquidGlassAppBar(
        title: Text('Appearance'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 40),
        children: [
          // Atmosphere Showcase Card
          LiquidGlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(22.0),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LiquidGlassTheme.bubbleBlueGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.16 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    PhosphorIconsFill.paintBrushBroad,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Atmosphere & Glass Optics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LiquidGlassTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Personalize the translucency, reflections, and deep contrast styling across your Bubble experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: LiquidGlassTheme.textSecondary(context),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                LiquidGlassPill(
                  height: 28,
                  fontSize: 12,
                  isSelected: true,
                  label: 'Current: ${_getThemeModeLabel(currentThemeMode)}',
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Theme Modes'),

          LiquidGlassContainer(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Column(
              children: [
                _buildThemeCard(
                  context: context,
                  title: 'System Default',
                  subtitle: 'Match device light/dark appearance automatically',
                  icon: PhosphorIconsRegular.deviceMobile,
                  value: ThemeMode.system,
                  groupValue: currentThemeMode,
                  onChanged: (mode) {
                    SafeHaptics.lightImpact();
                    settingsNotifier.setThemeMode(mode);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                  color: LiquidGlassTheme.specularBorderColor(context, opacityMultiplier: 0.35),
                ),
                _buildThemeCard(
                  context: context,
                  title: 'Light Mode',
                  subtitle: 'Clean, radiant frosted glass with pearlescent reflections',
                  icon: PhosphorIconsRegular.sun,
                  value: ThemeMode.light,
                  groupValue: currentThemeMode,
                  onChanged: (mode) {
                    SafeHaptics.lightImpact();
                    settingsNotifier.setThemeMode(mode);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                  color: LiquidGlassTheme.specularBorderColor(context, opacityMultiplier: 0.35),
                ),
                _buildThemeCard(
                  context: context,
                  title: 'Dark Mode',
                  subtitle: 'Obsidian fluid glass with deep contrast & iridescent sheen',
                  icon: PhosphorIconsRegular.moon,
                  value: ThemeMode.dark,
                  groupValue: currentThemeMode,
                  onChanged: (mode) {
                    SafeHaptics.lightImpact();
                    settingsNotifier.setThemeMode(mode);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode> onChanged,
  }) {
    final isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        SafeHaptics.lightImpact();
        onChanged(value);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? LiquidGlassTheme.specularBorderColor(context, opacityMultiplier: 1.4)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.22 : 0.14)
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isSelected
                      ? LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.4)
                      : LiquidGlassTheme.specularBorderColor(context, opacityMultiplier: 0.5),
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? LiquidGlassTheme.bubbleBlue
                    : (isDark ? Colors.white70 : Colors.black87),
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                        title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 15,
                          color: LiquidGlassTheme.textPrimary(context),
                        ),
                      ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: LiquidGlassTheme.bubbleBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: LiquidGlassTheme.textSecondary(context),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
              color: isSelected
                  ? LiquidGlassTheme.bubbleBlue
                  : (isDark ? Colors.white30 : Colors.black26),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 6.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: LiquidGlassTheme.textSecondary(context),
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
