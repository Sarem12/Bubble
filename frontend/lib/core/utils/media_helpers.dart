import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../network/api_client.dart';

class MediaHelpers {
  /// Resolves media URL to be accessible on local emulators/devices.
  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    var trimmed = url.trim();

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final origin = ApiClient.serverOrigin;
      if (!trimmed.startsWith('/')) {
        trimmed = '/$trimmed';
      }
      trimmed = '$origin$trimmed';
    }

    if (!kIsWeb && Platform.isAndroid) {
      if (trimmed.contains('localhost:3000')) {
        trimmed = trimmed.replaceAll('localhost:3000', '10.0.2.2:3000');
      }
      if (trimmed.contains('127.0.0.1:3000')) {
        trimmed = trimmed.replaceAll('127.0.0.1:3000', '10.0.2.2:3000');
      }
    }
    return trimmed;
  }
}
