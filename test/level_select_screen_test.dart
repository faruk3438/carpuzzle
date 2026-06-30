import 'package:carpark_puzzle/data/level_repository.dart';
import 'package:carpark_puzzle/screens/level_select_screen.dart';
import 'package:carpark_puzzle/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
    await LevelRepository.instance.preloadAll();
  });

  setUp(() async {
    await ProgressService.instance.clearAll();
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    testWidgets('level select renders premium layout at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: LevelSelectScreen()),
      );
      await tester.pumpAndSettle();

      final firstLevel = LevelRepository.instance.allLevels.first;
      expect(find.text('Leveller'), findsOneWidget);
      expect(find.byKey(const Key('level_progress_panel')), findsOneWidget);
      expect(find.byKey(Key('level_card_${firstLevel.id}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('levels unlock sequentially', (tester) async {
    final levels = LevelRepository.instance.allLevels;

    InkWell cardButton(int index) => tester.widget<InkWell>(
          find.descendant(
            of: find.byKey(Key('level_card_${levels[index].id}')),
            matching: find.byType(InkWell),
          ),
        );

    await tester.pumpWidget(const MaterialApp(home: LevelSelectScreen()));
    await tester.pumpAndSettle();

    expect(cardButton(0).onTap, isNotNull);
    expect(cardButton(1).onTap, isNull);

    await ProgressService.instance.saveStars(levels.first.id, 1);
    await tester.pumpWidget(const MaterialApp(home: LevelSelectScreen()));
    await tester.pumpAndSettle();

    expect(cardButton(1).onTap, isNotNull);
    expect(cardButton(2).onTap, isNull);
  });
}
