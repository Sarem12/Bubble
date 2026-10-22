import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Cross-platform safe wrapper for [HapticFeedback].
/// On non-supported platforms (Linux desktop, Windows, macOS, Web),
/// calls to [HapticFeedback] can hang the platform channel or block the UI isolate,
/// causing the application to stop responding after touches.
/// [SafeHaptics] guards all calls and safely suppresses errors.
class SafeHaptics {
  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static void lightImpact() {
    if (!isSupported) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void mediumImpact() {
    if (!isSupported) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static void heavyImpact() {
    if (!isSupported) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static void selectionClick() {
    if (!isSupported) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static void vibrate() {
    if (!isSupported) return;
    try {
      HapticFeedback.vibrate();
    } catch (_) {}
  }
}

