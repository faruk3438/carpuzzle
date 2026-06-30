import 'package:carpark_puzzle/bloc/game_bloc.dart';
import 'package:carpark_puzzle/data/level_repository.dart';
import 'package:carpark_puzzle/models/move_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LevelRepository.instance.preloadAll();
  });

  test('rewarded hint is granted only through its game event', () async {
    final level = LevelRepository.instance.allLevels.firstWhere(
      (candidate) => candidate.hintSolution.isNotEmpty,
    );
    final bloc = GameBloc()..add(GameLoaded(level));
    await Future<void>.delayed(Duration.zero);

    bloc.add(RewardHintGranted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.hintsUsed, 1);
    expect(bloc.state.hintCarId, isNotNull);
    await bloc.close();
  });

  test('rewarded undo restores the previous move', () async {
    final level = LevelRepository.instance.allLevels.firstWhere(
      (candidate) => candidate.cars.any((car) {
        final result = MoveEngine.calculate(
          car: car,
          cars: candidate.cars,
          level: candidate,
        );
        return result.moved && !result.crashed;
      }),
    );
    final movableCar = level.cars.firstWhere((car) {
      final result = MoveEngine.calculate(
        car: car,
        cars: level.cars,
        level: level,
      );
      return result.moved && !result.crashed;
    });
    final bloc = GameBloc()..add(GameLoaded(level));
    await Future<void>.delayed(Duration.zero);

    bloc.add(CarTapped(movableCar.id));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.history, isNotEmpty);

    bloc.add(RewardUndoGranted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.history, isEmpty);
    expect(bloc.state.moveCount, 0);
    await bloc.close();
  });

  test('rewarded life resumes a no-lives failure', () async {
    final level = LevelRepository.instance.allLevels.firstWhere(
      (candidate) => candidate.cars.any((car) {
        final result = MoveEngine.calculate(
          car: car,
          cars: candidate.cars,
          level: candidate,
        );
        return result.crashed && !result.moved;
      }),
    );
    final blockedCar = level.cars.firstWhere((car) {
      final result = MoveEngine.calculate(
        car: car,
        cars: level.cars,
        level: level,
      );
      return result.crashed && !result.moved;
    });
    final bloc = GameBloc()..add(GameLoaded(level));
    await Future<void>.delayed(Duration.zero);

    for (var i = 0; i < startingLives; i++) {
      bloc.add(CarTapped(blockedCar.id));
      await Future<void>.delayed(Duration.zero);
    }
    expect(bloc.state.status, GameStatus.failed);
    expect(bloc.state.failReason, FailReason.noLives);

    bloc.add(RewardLifeGranted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, GameStatus.playing);
    expect(bloc.state.lives, 1);
    expect(bloc.state.failReason, FailReason.none);
    await bloc.close();
  });
}
