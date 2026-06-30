import 'package:carpark_puzzle/data/level_repository.dart';
import 'package:carpark_puzzle/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LevelRepository.instance.preloadAll();
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    testWidgets('game screen renders without overflow at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final level = LevelRepository.instance.allLevels.first;
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(levelId: level.id)),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameScreen), findsOneWidget);
      final boardSize = tester.getSize(
        find.byKey(const Key('game_grid_board_layer')),
      );
      final carLayerSize = tester.getSize(
        find.byKey(const Key('game_grid_car_layer')),
      );
      expect(boardSize.width, greaterThan(300));
      expect(boardSize.height, greaterThan(400));
      expect(carLayerSize, boardSize);
      final counterSize = tester.getSize(
        find.byKey(const Key('move_counter_capsule')),
      );
      expect(counterSize.width, greaterThanOrEqualTo(128));
      expect(counterSize.height, greaterThanOrEqualTo(58));
      expect(tester.takeException(), isNull);
    });
  }
}
