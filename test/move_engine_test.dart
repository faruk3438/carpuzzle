import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carpark_puzzle/models/models.dart';
import 'package:carpark_puzzle/models/move_engine.dart';
import 'package:carpark_puzzle/engine/bfs_solver.dart';

// ── Yardımcı fabrikalar ────────────────────────────────────────

LevelModel _level({
  int rows = 4,
  int cols = 4,
  List<(int, int)> walls = const [],
  List<ExitCell> exits = const [],
  List<OneWayCell> oneWays = const [],
  List<TeleportCell> portals = const [],
  List<CarModel> cars = const [],
  int parMoves = 1,
}) =>
    LevelModel(
      id: 'test',
      chapter: 1,
      level: 1,
      name: 'Test',
      difficulty: DifficultyLevel.easy,
      rows: rows,
      cols: cols,
      walls: walls.toSet(),
      exits: exits,
      oneWays: oneWays,
      portals: portals,
      cars: cars,
      parMoves: parMoves,
      hintSolution: [],
    );

CarModel _car({
  String id = 'c1',
  int row = 0,
  int col = 0,
  Direction dir = Direction.right,
  int size = 1,
  CarType type = CarType.standard,
  bool exited = false,
  int emergencyMovesLeft = 0,
}) =>
    CarModel(
      id: id,
      row: row,
      col: col,
      direction: dir,
      size: size,
      type: type,
      color: Colors.blue,
      isExited: exited,
      emergencyMovesLeft: emergencyMovesLeft,
    );

ExitCell _exit(int r, int c, Direction dir) {
  final type = switch (dir) {
    Direction.up => CellType.exitUp,
    Direction.down => CellType.exitDown,
    Direction.left => CellType.exitLeft,
    Direction.right => CellType.exitRight,
  };
  return ExitCell(row: r, col: c, type: type);
}

// ══════════════════════════════════════════════════════
// MoveEngine Testleri
// ══════════════════════════════════════════════════════

void main() {
  group('MoveEngine — temel hareket', () {
    test('Boş satırda sağa bakan araç çıkışa ulaşır', () {
      final car = _car(row: 1, col: 0, dir: Direction.right);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [_exit(1, 3, Direction.right)],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.moved, isTrue);
      expect(result.exited, isTrue);
      // Araç col=0'dan col=3'e kadar 3 adım ilerler, sonra grid dışı = çıkış (toplam 4 adım)
      expect(result.steps, 4);
    });

    test('Araç duvara çarparsa hareket etmez', () {
      final car = _car(row: 1, col: 0, dir: Direction.right);
      final level = _level(
        rows: 4,
        cols: 4,
        walls: [(1, 1)],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.moved, isFalse);
      expect(result.steps, 0);
    });

    test('Araç diğer araca çarparsa durur', () {
      final c1 = _car(id: 'c1', row: 1, col: 0, dir: Direction.right);
      final c2 = _car(id: 'c2', row: 1, col: 2, dir: Direction.right);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [_exit(1, 3, Direction.right)],
        cars: [c1, c2],
      );

      final result =
          MoveEngine.calculate(car: c1, cars: [c1, c2], level: level);

      expect(result.moved, isTrue);
      expect(result.exited, isFalse);
      expect(result.crashed, isTrue);
      expect(result.car.col, 1); // c2'nin önünde dur
    });

    test('Sabit exit hücresi olmasa da kenardan çıkabilir', () {
      final car = _car(row: 1, col: 0, dir: Direction.right);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.exited, isTrue);
    });

    test('Size=2 araç doğru hücreleri kaplar', () {
      final car = _car(row: 2, col: 2, dir: Direction.right, size: 2);
      // HEAD=(2,2), TAIL=(2,1)
      expect(car.occupiedCells, containsAll([(2, 2), (2, 1)]));
    });

    test('Size=2 araç tamamen çıkabilir', () {
      final car = _car(row: 1, col: 2, dir: Direction.right, size: 2);
      final level = _level(
        rows: 4,
        cols: 5,
        exits: [_exit(1, 4, Direction.right)],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.exited, isTrue);
    });

    test('Yukarı bakan araç çıkışa ulaşır', () {
      final car = _car(row: 3, col: 1, dir: Direction.up);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [_exit(0, 1, Direction.up)],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.exited, isTrue);
    });

    test('Grid kenarı doğal çıkıştır', () {
      final car = _car(row: 0, col: 1, dir: Direction.up);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.exited, isTrue);
      expect(result.moved, isTrue);
    });

    test('Deadlock: hiçbir araç hareket edemiyorsa hasAnyMove false', () {
      final c1 = _car(id: 'c1', row: 1, col: 1, dir: Direction.right);
      final c2 = _car(id: 'c2', row: 1, col: 2, dir: Direction.right);
      // c1 sağa gidemez (c2 var), c2 sağa gidemez (duvar)
      final level = _level(
        rows: 4,
        cols: 4,
        walls: [(1, 3)],
        exits: [],
        cars: [c1, c2],
      );

      final canMove = MoveEngine.hasAnyMove(cars: [c1, c2], level: level);
      expect(canMove, isFalse);
    });
  });

  group('MoveEngine — One-way hücreler', () {
    test('One-way hücreye izinli yönde geçilebilir', () {
      final car = _car(row: 1, col: 0, dir: Direction.right);
      final level = _level(
        rows: 4,
        cols: 5,
        oneWays: [OneWayCell(row: 1, col: 2, type: CellType.oneWayRight)],
        exits: [_exit(1, 4, Direction.right)],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.exited, isTrue);
    });

    test('One-way hücreye yasak yönde geçilemez', () {
      final car = _car(row: 1, col: 4, dir: Direction.left);
      final level = _level(
        rows: 4,
        cols: 5,
        oneWays: [
          OneWayCell(row: 1, col: 2, type: CellType.oneWayRight) // sağa izin
        ],
        exits: [],
        cars: [car],
      );

      // Araç sola gitmek istiyor, ama (1,2) sadece sağa izin veriyor
      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.moved, isTrue);
      expect(result.car.col, 3); // (1,2)'de durur
    });
  });

  group('MoveEngine — Spinner', () {
    test('Spinner bloke olunca döner', () {
      final car =
          _car(row: 1, col: 1, dir: Direction.right, type: CarType.spinner);
      final level = _level(
        rows: 4,
        cols: 4,
        walls: [(1, 2)],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.rotated, isTrue);
      expect(result.moved, isFalse);
      expect(result.car.direction, Direction.down); // CW: right → down
    });

    test('Spinner hareket edebiliyorsa döndürmez', () {
      final car =
          _car(row: 1, col: 0, dir: Direction.right, type: CarType.spinner);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [_exit(1, 3, Direction.right)],
        cars: [car],
      );

      final result = MoveEngine.calculate(car: car, cars: [car], level: level);

      expect(result.rotated, isFalse);
      expect(result.moved, isTrue);
    });
  });

  group('MoveEngine — Direction.rotatedCW', () {
    test('Tüm yönler saat yönünde döner', () {
      expect(Direction.up.rotatedCW, Direction.right);
      expect(Direction.right.rotatedCW, Direction.down);
      expect(Direction.down.rotatedCW, Direction.left);
      expect(Direction.left.rotatedCW, Direction.up);
    });
  });

  // ══════════════════════════════════════════════════════
  // BFS Solver Testleri
  // ══════════════════════════════════════════════════════

  group('BfsSolver', () {
    test('Tek araç — tek hamle çözüm', () {
      final car = _car(row: 1, col: 0, dir: Direction.right);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [_exit(1, 3, Direction.right)],
        cars: [car],
      );

      final result = BfsSolver.solve(level);

      expect(result.solvable, isTrue);
      expect(result.optimalMoves, 1);
      expect(result.solution, ['c1']);
    });

    test('İki araç — sıralı çıkış', () {
      final c1 = _car(id: 'c1', row: 1, col: 0, dir: Direction.right);
      final c2 = _car(id: 'c2', row: 1, col: 2, dir: Direction.right);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [_exit(1, 3, Direction.right)],
        cars: [c1, c2],
        parMoves: 2,
      );

      final result = BfsSolver.solve(level);

      expect(result.solvable, isTrue);
      expect(result.optimalMoves, 2);
      // c2 önce çıkmalı, sonra c1
      expect(result.solution.first, 'c2');
    });

    test('Çözümsüz level → unsolvable döner', () {
      final car = _car(row: 1, col: 1, dir: Direction.right);
      final level = _level(
        rows: 4,
        cols: 4,
        walls: [(1, 2)],
        exits: [], // çıkış yok
        cars: [car],
      );

      final result = BfsSolver.solve(level, maxDepth: 10);

      expect(result.solvable, isFalse);
    });

    test('Üç araç sıralı bloke — BFS doğru çözer', () {
      // ch1_l3 benzeri: c3→c2→c1 sıralaması
      final c1 = _car(id: 'c1', row: 3, col: 1, dir: Direction.up);
      final c2 = _car(id: 'c2', row: 2, col: 1, dir: Direction.up);
      final c3 = _car(id: 'c3', row: 1, col: 1, dir: Direction.up);
      final level = _level(
        rows: 4,
        cols: 4,
        exits: [_exit(0, 1, Direction.up)],
        cars: [c1, c2, c3],
        parMoves: 3,
      );

      final result = BfsSolver.solve(level);

      expect(result.solvable, isTrue);
      expect(result.optimalMoves, 3);
    });

    test('Size=2 araç çıkışa ulaşır', () {
      final car =
          _car(id: 'suv', row: 1, col: 2, dir: Direction.right, size: 2);
      final level = _level(
        rows: 5,
        cols: 5,
        exits: [_exit(1, 4, Direction.right)],
        cars: [car],
        parMoves: 1,
      );

      final result = BfsSolver.solve(level);

      expect(result.solvable, isTrue);
      expect(result.solution, ['suv']);
    });

    test('Chapter 2 blokaj zinciri optimal sırayla çözülür', () {
      final cars = [
        _car(id: 'c1', row: 2, col: 0, dir: Direction.right),
        _car(id: 'c2', row: 2, col: 2, dir: Direction.up),
        _car(id: 'c3', row: 0, col: 2, dir: Direction.right),
        _car(id: 'c4', row: 4, col: 3, dir: Direction.down),
        _car(id: 'c5', row: 5, col: 3, dir: Direction.left),
        _car(id: 'c6', row: 0, col: 4, dir: Direction.down),
        _car(id: 'c7', row: 4, col: 4, dir: Direction.left),
      ];
      final level = _level(
        rows: 6,
        cols: 6,
        cars: cars,
        parMoves: 7,
      );

      final result = BfsSolver.solve(level);

      expect(result.solvable, isTrue);
      expect(result.optimalMoves, 7);
      expect(result.solution, ['c5', 'c4', 'c7', 'c6', 'c3', 'c2', 'c1']);
    });

    test('Level 3 eight-car lock solves in optimal order', () {
      final cars = [
        _car(id: 'c1', row: 2, col: 0, dir: Direction.right),
        _car(id: 'c2', row: 2, col: 2, dir: Direction.up),
        _car(id: 'c3', row: 0, col: 2, dir: Direction.right),
        _car(id: 'c4', row: 0, col: 4, dir: Direction.down),
        _car(id: 'c5', row: 3, col: 4, dir: Direction.left),
        _car(id: 'c6', row: 3, col: 1, dir: Direction.down),
        _car(id: 'c7', row: 5, col: 1, dir: Direction.right),
        _car(id: 'c8', row: 5, col: 4, dir: Direction.down),
      ];
      final level = _level(
        rows: 6,
        cols: 6,
        cars: cars,
        parMoves: 8,
      );

      final result = BfsSolver.solve(level);

      expect(result.solvable, isTrue);
      expect(result.optimalMoves, 8);
      expect(result.solution, [
        'c8',
        'c7',
        'c6',
        'c5',
        'c4',
        'c3',
        'c2',
        'c1',
      ]);
    });

    test('Chapter 1 JSON levels are solvable and hints are playable', () {
      final raw = File('assets/levels/chapter_1.json').readAsStringSync();
      final levels = (jsonDecode(raw) as List<dynamic>)
          .map((data) => LevelModel.fromJson(data as Map<String, dynamic>))
          .toList();

      expect(
          levels.map((level) => level.level), List.generate(35, (i) => i + 1));

      for (final level in levels) {
        final solved = BfsSolver.solve(level, maxDepth: 40);
        expect(solved.solvable, isTrue, reason: level.id);
        expect(solved.optimalMoves, level.parMoves, reason: level.id);
        expect(level.hintSolution.length, level.parMoves, reason: level.id);

        var cars = List<CarModel>.from(level.cars);
        for (final carId in level.hintSolution) {
          final active = cars.where((car) => !car.isExited).toList();
          final car = active.firstWhere((car) => car.id == carId);
          final result = MoveEngine.calculate(
            car: car,
            cars: active,
            level: level,
          );

          expect(result.moved || result.rotated, isTrue,
              reason: '${level.id} $carId');
          expect(result.crashed, isFalse, reason: '${level.id} $carId');
          cars = cars.map((car) => car.id == carId ? result.car : car).toList();
        }

        expect(cars.every((car) => car.isExited), isTrue, reason: level.id);
      }
    });
  });

  group('LevelModel', () {
    test('isWall doğru çalışır', () {
      final level = _level(walls: [(1, 2), (3, 3)]);
      expect(level.isWall(1, 2), isTrue);
      expect(level.isWall(1, 3), isFalse);
    });

    test('exitAt doğru döner', () {
      final exit = _exit(2, 3, Direction.right);
      final level = _level(exits: [exit]);
      expect(level.exitAt(2, 3), isNotNull);
      expect(level.exitAt(1, 3), isNull);
    });

    test('oneWayAt doğru döner', () {
      final ow = OneWayCell(row: 1, col: 2, type: CellType.oneWayUp);
      final level = _level(oneWays: [ow]);
      expect(level.oneWayAt(1, 2), isNotNull);
      expect(level.oneWayAt(1, 3), isNull);
    });
  });

  group('CarModel', () {
    test('Size=3 araç doğru hücreleri kaplar — yukarı', () {
      final car = _car(row: 3, col: 2, dir: Direction.up, size: 3);
      // HEAD=(3,2), body: (4,2), tail: (5,2)
      final cells = car.occupiedCells;
      expect(cells, containsAll([(3, 2), (4, 2), (5, 2)]));
      expect(cells.length, 3);
    });

    test('tailCell size=1 → headCell ile aynı', () {
      final car = _car(row: 2, col: 2, dir: Direction.right, size: 1);
      expect(car.tailCell, car.headCell);
    });

    test('copyWith sadece verilen alanları değiştirir', () {
      final car = _car(row: 1, col: 1, dir: Direction.up, size: 2);
      final updated = car.copyWith(row: 5);
      expect(updated.row, 5);
      expect(updated.col, 1);
      expect(updated.size, 2);
      expect(updated.direction, Direction.up);
    });
  });
}
