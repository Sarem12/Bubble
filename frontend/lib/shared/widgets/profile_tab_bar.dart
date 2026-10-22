import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/utils/ui_helpers.dart';
import 'liquid_glass.dart';

/// A softly blurred glass track with a translucent Bubble-blue selection.
/// Shared across profiles, inbox, and other tabbed screens for consistent UI treatment.
class ProfileTabBar extends StatelessWidget {
  final TabController? controller;
  final List<Widget> tabs;
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final ValueChanged<int>? onTap;

  const ProfileTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.height = 40,
    this.padding = const EdgeInsets.all(2),
    this.borderRadius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.055)
                : const Color(0xFFEAECEF),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : const Color(0xFFD8DCE2),
            ),
          ),
          padding: padding,
          child: TabBar(
            controller: controller,
            onTap: (index) {
              SafeHaptics.selectionClick();
              onTap?.call(index);
            },
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: isDark
                  ? LiquidGlassTheme.createNonLinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        LiquidGlassTheme.bubbleMagenta.withValues(alpha: 0.20),
                        LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.34),
                        LiquidGlassTheme.bubbleGreen.withValues(alpha: 0.16),
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFF8FAFC),
                      ],
                    ),
              borderRadius: BorderRadius.circular((borderRadius - 4).clamp(0.0, borderRadius)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.34)
                    : const Color(0xFFCBD5E1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.08),
                  blurRadius: isDark ? 5 : 4,
                  offset: const Offset(0, 1.5),
                ),
                if (isDark)
                  BoxShadow(
                    color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            labelColor: isDark ? Colors.white : const Color(0xFF0F172A),
            unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: tabs,
          ),
        ),
      ),
    );
  }
}

