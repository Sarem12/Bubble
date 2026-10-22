import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubble/core/utils/overflow_checker.dart';
import 'package:bubble/shared/widgets/liquid_glass.dart';
import 'package:bubble/core/transitions/bubble_page_transitions.dart';

void main() {
  setUp(() {
    OverflowChecker.clearReports();
    OverflowChecker.installGlobalOverflowChecker();
  });

  tearDown(() {
    OverflowChecker.clearReports();
  });

  group('Overflow Checking Function & Component Tests', () {
    testWidgets('LiquidGlassPill does not overflow on extremely narrow constraints', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120, // narrow container
                child: Row(
                  children: const [
                    Expanded(
                      child: LiquidGlassPill(
                        label: 'Very Long Status Text That Would Normally Cause An Overflow',
                        icon: Icon(Icons.star, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(OverflowChecker.hasOverflowed, isFalse);
    });

    testWidgets('Metadata Row with 36-character UUID does not overflow on 320px screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      const uuid = 'c8f1082a-7182-411a-a1fb-f123456789ab';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('User ID', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Flexible(
                          child: Text(
                            uuid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.copy, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(OverflowChecker.hasOverflowed, isFalse);
    });

    testWidgets('Action buttons in photo detail viewer do not overflow on 320px screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit, size: 22),
                          SizedBox(height: 4),
                          Text('Edit', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.share, size: 22),
                          SizedBox(height: 4),
                          Text('Share', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      LiquidGlassButton(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        label: 'Post',
                        icon: const Icon(Icons.send, size: 16, color: Colors.white),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.delete, size: 22),
                          SizedBox(height: 4),
                          Text('Delete', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(OverflowChecker.hasOverflowed, isFalse);
    });

    testWidgets('Selected photos header Row does not overflow with long title on 320px screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      '99 Photos Selected For Upload',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Reorder',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Edit Selection',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(OverflowChecker.hasOverflowed, isFalse);
    });

    testWidgets('Transient height morph transition does not overflow during animation frames', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));

      final heightNotifier = ValueNotifier<double>(380.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<double>(
              valueListenable: heightNotifier,
              builder: (context, height, _) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: height,
                  child: OverflowChecker.safeTransientBox(
                    naturalHeight: 380.0,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 50,
                          child: Center(child: Text('Header Section')),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: 20,
                            itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(OverflowChecker.hasOverflowed, isFalse);

      // Trigger transition from 380 down to 60
      heightNotifier.value = 60.0;
      await tester.pump();

      // Step through intermediate animation frames (transient states)
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        // Verify no transient overflow occurs during ANY frame of the height transition
        expect(OverflowChecker.hasOverflowed, isFalse,
            reason: 'Transient overflow detected during frame $i of height morph!');
      }

      await tester.pumpAndSettle();
      expect(OverflowChecker.hasOverflowed, isFalse);
    });

    testWidgets('BubblePageTransitions do not cause transient overflow during route push/pop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  navKey.currentState!.push(
                    BubbleMorphModalRoute(
                      page: Scaffold(
                        appBar: AppBar(title: const Text('Modal Studio')),
                        body: const Center(child: Text('Studio Content')),
                      ),
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to open modal with BubbleMorphModalRoute
      await tester.tap(find.text('Open Modal'));
      await tester.pump();

      // Step through transition frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 35));
        expect(OverflowChecker.hasOverflowed, isFalse,
            reason: 'Transient overflow detected during route transition frame $i!');
      }

      await tester.pumpAndSettle();
      expect(find.text('Studio Content'), findsOneWidget);

      // Pop route and step through reverse transition
      navKey.currentState!.pop();
      await tester.pump();

      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(OverflowChecker.hasOverflowed, isFalse,
            reason: 'Transient overflow detected during route pop frame $i!');
      }

      await tester.pumpAndSettle();
      expect(find.text('Open Modal'), findsOneWidget);
    });
  });
}
