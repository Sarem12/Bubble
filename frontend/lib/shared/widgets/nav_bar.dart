import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/utils/safe_haptics.dart';
import '../../../features/profile/presentation/controllers/profile_controller.dart';
import 'user_avatar.dart';
import 'liquid_glass.dart';

/// Liquid Glass floating navigation bar with an expanded selected tab width,
/// animated label, and transparent floating glass body.
class AppNavBar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const AppNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide navigation bar when keyboard is open to avoid pushing it up
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Only watch profile_picture_url specifically to avoid redundant nav bar rebuilds
    final pfpUrl = ref.watch(
      profileControllerProvider.select(
        (s) => s.asData?.value['profile_picture_url'] as String?,
      ),
    );

    const double barHeight = 60.0;
    const double barRadius = 30.0;

    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 10 : 16),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(barRadius),
              boxShadow: LiquidGlassTheme.dockSurfaceShadows(
                isDark: isDark,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(barRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: LiquidGlassTheme.dockSurfaceGradient(
                      isDark: isDark,
                    ),
                    borderRadius: BorderRadius.circular(barRadius),
                    border: Border.all(
                      color: LiquidGlassTheme.dockSurfaceBorder(
                        isDark: isDark,
                      ),
                      width: 1.1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LiquidGlassTheme.dockSurfaceSheen(
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                      LayoutBuilder(
                    builder: (context, constraints) {
                      const int selectedFlex = 19;
                      const int unselectedFlex = 10;
                      const int totalFlex = selectedFlex + (unselectedFlex * 4); // 59

                      final totalWidth = constraints.maxWidth;
                      final itemWidth = (totalWidth * selectedFlex) / totalFlex;
                      final itemLeft = (totalWidth * (selectedIndex * unselectedFlex)) / totalFlex;

                      return Stack(
                        children: [
                          // 1. Sliding selection indicator - takes all height with higher selected width
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            left: itemLeft + 2.0,
                            top: 2.5,
                            bottom: 2.5,
                            width: itemWidth - 4.0,
                            child: LiquidBubblePill(
                              radius: (barRadius - 2.5).clamp(0.0, double.infinity),
                              isDark: isDark,
                            ),
                          ),

                          // 2. Row of navigation items with expanded selected width
                          Row(
                            children: [
                              _buildNavItem(
                                context: context,
                                index: 0,
                                label: 'Home',
                                isSelected: selectedIndex == 0,
                                isDark: isDark,
                                icon: _buildHomeIcon(isSelected: selectedIndex == 0, isDark: isDark),
                              ),
                              _buildNavItem(
                                context: context,
                                index: 1,
                                label: 'Explore',
                                isSelected: selectedIndex == 1,
                                isDark: isDark,
                                icon: _buildExploreIcon(isSelected: selectedIndex == 1, isDark: isDark),
                              ),
                              _buildNavItem(
                                context: context,
                                index: 2,
                                label: 'Gallery',
                                isSelected: selectedIndex == 2,
                                isDark: isDark,
                                icon: _buildGalleryIcon(isSelected: selectedIndex == 2, isDark: isDark),
                              ),
                              _buildNavItem(
                                context: context,
                                index: 3,
                                label: 'Inbox',
                                isSelected: selectedIndex == 3,
                                isDark: isDark,
                                icon: _buildInboxIcon(isSelected: selectedIndex == 3, isDark: isDark),
                              ),
                              _buildNavItem(
                                context: context,
                                index: 4,
                                label: 'Profile',
                                isSelected: selectedIndex == 4,
                                isDark: isDark,
                                icon: _buildProfileIcon(
                                  isSelected: selectedIndex == 4,
                                  pfpUrl: pfpUrl,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required bool isSelected,
    required bool isDark,
    required Widget icon,
  }) {
    final Color selectedColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final Widget labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: selectedColor,
        height: 1.1,
      ),
    );

    final Widget navContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey('${index}_$isSelected'),
              child: icon,
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 5),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1.0),
                            child: labelText,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );

    return Expanded(
      flex: isSelected ? 19 : 10,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SafeHaptics.lightImpact();
          onItemTapped(index);
        },
        child: SizedBox(
          height: double.infinity,
          child: Center(
            child: navContent,
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData iconData, {required bool isSelected, required bool isDark}) {
    if (isSelected) {
      return Icon(
        iconData,
        size: 22,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      );
    }
    return Icon(
      iconData,
      size: 22,
      color: isDark ? Colors.white60 : const Color(0xFF64748B),
    );
  }

  // 1. Home: Lucide icon
  Widget _buildHomeIcon({required bool isSelected, required bool isDark}) {
    return _buildHomeIconImpl(LucideIcons.home, isSelected: isSelected, isDark: isDark);
  }

  Widget _buildHomeIconImpl(IconData iconData, {required bool isSelected, required bool isDark}) {
    return _buildIcon(iconData, isSelected: isSelected, isDark: isDark);
  }

  // 2. Explore: Lucide icon
  Widget _buildExploreIcon({required bool isSelected, required bool isDark}) {
    return _buildIcon(LucideIcons.compass, isSelected: isSelected, isDark: isDark);
  }

  // 3. Gallery: Lucide icon
  Widget _buildGalleryIcon({required bool isSelected, required bool isDark}) {
    return _buildIcon(LucideIcons.flower, isSelected: isSelected, isDark: isDark);
  }

  // 4. Inbox: Lucide icon
  Widget _buildInboxIcon({required bool isSelected, required bool isDark}) {
    return _buildIcon(LucideIcons.inbox, isSelected: isSelected, isDark: isDark);
  }

  // 5. Profile: Circular user profile picture inside circle
  Widget _buildProfileIcon({
    required bool isSelected,
    required String? pfpUrl,
    required bool isDark,
  }) {
    const double size = 23.0;

    Widget avatarImage = (pfpUrl != null && pfpUrl.trim().isNotEmpty)
        ? UserAvatar(
            imageUrl: pfpUrl,
            radius: size / 2,
          )
        : Container(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
            child: Icon(
              LucideIcons.user,
              size: 14,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          );

    if (isSelected) {
      return Container(
        width: size + 4,
        height: size + 4,
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LiquidGlassTheme.bubbleBlueGradient,
          boxShadow: [
            BoxShadow(
              color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(child: avatarImage),
      );
    }

    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: ClipOval(child: avatarImage),
    );
  }
}
