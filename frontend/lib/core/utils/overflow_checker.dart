import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Data class holding details about a detected overflow.
class OverflowReport {
  final String message;
  final double pixels;
  final String direction;
  final String? failedWidget;
  final bool isTransient;
  final DateTime timestamp;

  OverflowReport({
    required this.message,
    required this.pixels,
    required this.direction,
    this.failedWidget,
    this.isTransient = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    final trans = isTransient ? ' [TRANSIENT ANIMATION/TRANSITION]' : '';
    return 'OverflowReport$trans: $pixels px in $direction direction ($failedWidget)';
  }
}

/// Global Overflow Checking Function & Monitoring System.
/// Detects, analyzes, and prevents RenderFlex overflows and transient animation overflows.
class OverflowChecker {
  static final List<OverflowReport> _reports = [];
  static bool _installed = false;
  static FlutterExceptionHandler? _originalOnError;

  /// All recorded overflow reports in this session
  static List<OverflowReport> get reports => List.unmodifiable(_reports);

  /// Whether any overflow has been detected
  static bool get hasOverflowed => _reports.isNotEmpty;

  /// Clear recorded overflow reports (useful in tests)
  static void clearReports() {
    _reports.clear();
  }

  /// Installs the global overflow checking function into Flutter's error pipeline.
  /// Intercepts all RenderFlex overflow errors, analyzes whether they are transient
  /// (e.g. during an ongoing route transition or animation ticker) or static,
  /// and logs actionable diagnostics.
  static void installGlobalOverflowChecker({
    void Function(OverflowReport report)? onOverflow,
  }) {
    if (_installed) return;
    _installed = true;
    _originalOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      final isOverflow = msg.contains('A RenderFlex overflowed') ||
          msg.contains('overflowed by') ||
          msg.contains('RenderFlex children have non-zero flex');

      if (isOverflow) {
        // Parse pixels and direction from error message
        double pixels = 0.0;
        String direction = 'unknown';

        final pixelMatch = RegExp(r'overflowed by ([\d\.]+) pixels').firstMatch(msg);
        if (pixelMatch != null) {
          pixels = double.tryParse(pixelMatch.group(1) ?? '0') ?? 0.0;
        }

        if (msg.contains('on the right')) {
          direction = 'right (horizontal)';
        } else if (msg.contains('on the bottom')) {
          direction = 'bottom (vertical)';
        } else if (msg.contains('on the left')) {
          direction = 'left (horizontal)';
        } else if (msg.contains('on the top')) {
          direction = 'top (vertical)';
        }

        // Determine if transient (during animation or transition)
        final isTransient = details.stack != null &&
            (details.stack.toString().contains('AnimationController') ||
                details.stack.toString().contains('CurvedAnimation') ||
                details.stack.toString().contains('AnimatedContainer') ||
                details.stack.toString().contains('Transition') ||
                details.stack.toString().contains('TickerFuture'));

        final report = OverflowReport(
          message: msg,
          pixels: pixels,
          direction: direction,
          failedWidget: details.context?.toString(),
          isTransient: isTransient,
        );

        _reports.add(report);

        if (kDebugMode) {
          debugPrint('⚠️ [OVERFLOW DETECTED] ${report.toString()}');
        }

        onOverflow?.call(report);
      }

      // Delegate to original handler so developer tools still see errors
      _originalOnError?.call(details);
    };
  }

  /// Wraps a widget in an overflow-safe box for transient transitions and height animations.
  /// When parent bounds animate to smaller sizes, this prevents child RenderFlex widgets
  /// from overflowing by providing unconstrained layout height and clipping cleanly.
  static Widget safeTransientBox({
    required Widget child,
    required double naturalHeight,
    Alignment alignment = Alignment.topCenter,
  }) {
    return ClipRect(
      child: OverflowBox(
        alignment: alignment,
        minHeight: 0,
        maxHeight: naturalHeight,
        child: SizedBox(
          height: naturalHeight,
          child: child,
        ),
      ),
    );
  }
}

