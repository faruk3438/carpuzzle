import 'package:carpark_puzzle/screens/main_menu_screen.dart';
import 'package:carpark_puzzle/services/daily_challenge_service.dart';
import 'package:carpark_puzzle/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
    await DailyChallengeService.instance.init();
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    testWidgets('main menu image hotspots render at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('main_menu_play')), findsOneWidget);
      expect(find.byKey(const Key('main_menu_settings')), findsOneWidget);
      expect(find.byKey(const Key('main_menu_shop')), findsNothing);
      expect(find.byKey(const Key('main_menu_achievements')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('main menu buttons open their destinations', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('main_menu_play')));
    await tester.pumpAndSettle();
    expect(find.text('Leveller'), findsOneWidget);
    Navigator.of(tester.element(find.text('Leveller'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('main_menu_settings')));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Ses Efektleri'), findsOneWidget);
    expect(find.text('Bildirimler'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
