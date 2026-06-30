import 'package:carpark_puzzle/bloc/game_bloc.dart';
import 'package:carpark_puzzle/widgets/fail_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final reason in [
    FailReason.deadlock,
    FailReason.emergencyTimeout,
    FailReason.noLives,
  ]) {
    testWidgets('FailOverlay renders $reason on a compact screen',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FailOverlay(
                  reason: reason,
                  lives: reason == FailReason.noLives ? 0 : 2,
                  onRetry: () {},
                  canRewardUndo: true,
                  onRewardLife: () {},
                  onRewardUndo: () {},
                  onMenu: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FailOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
