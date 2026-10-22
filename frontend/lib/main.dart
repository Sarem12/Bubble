import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'app/app.dart';
import 'core/storage/secure_storage.dart';
import 'core/utils/overflow_checker.dart';
import 'features/profile/presentation/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OverflowChecker.installGlobalOverflowChecker();
  VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 300);
  await SecureStorage.init();
  final initialSettings = await SettingsController.loadLocalSettings();
  runApp(
    ProviderScope(
      overrides: [
        initialSettingsProvider.overrideWithValue(initialSettings),
      ],
      child: const BubbleApp(),
    ),
  );
}
