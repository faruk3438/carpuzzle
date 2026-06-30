import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════
// ENUMS
// ══════════════════════════════════════════════════════

enum Direction { up, down, left, right }

enum CarType { standard, suv, vip, emergency, truck, tir, spinner }

/// Hücre tipleri.
/// oneWay*: sadece ok yönünde geçiş izni.
/// teleportA/B: eşleşmiş iki portal.
enum CellType {
  empty,
  wall,
  exitUp,
  exitDown,
  exitLeft,
  exitRight,
  oneWayUp,
  oneWayDown,
  oneWayLeft,
  oneWayRight,
  teleportA,
  teleportB,
}

enum DifficultyLevel { easy, medium, hard, expert }

// ══════════════════════════════════════════════════════
// DIRECTION EXTENSION
// ══════════════════════════════════════════════════════

extension DirectionExt on Direction {
  (int, int) get delta => switch (this) {
        Direction.up => (-1, 0),
        Direction.down => (1, 0),
        Direction.left => (0, -1),
        Direction.right => (0, 1),
      };

  bool get isHorizontal => this == Direction.left || this == Direction.right;
  bool get isVertical => this == Direction.up || this == Direction.down;

  double get arrowAngle => switch (this) {
        Direction.up => -1.5708,
        Direction.down => 1.5708,
        Direction.left => 3.1416,
        Direction.right => 0.0,
      };

  Direction get rotatedCW => switch (this) {
        Direction.up => Direction.right,
        Direction.right => Direction.down,
        Direction.down => Direction.left,
        Direction.left => Direction.up,
      };

  static Direction fromString(String s) => Direction.values
      .firstWhere((d) => d.name == s, orElse: () => Direction.right);
}

extension CellTypeExt on CellType {
  bool get isExit => switch (this) {
        CellType.exitUp => true,
        CellType.exitDown => true,
        CellType.exitLeft => true,
        CellType.exitRight => true,
        _ => false,
      };

  bool get isOneWay => switch (this) {
        CellType.oneWayUp => true,
        CellType.oneWayDown => true,
        CellType.oneWayLeft => true,
        CellType.oneWayRight => true,
        _ => false,
      };

  bool get isTeleport =>
      this == CellType.teleportA || this == CellType.teleportB;

  Direction? get exitDirection => switch (this) {
        CellType.exitUp => Direction.up,
        CellType.exitDown => Direction.down,
        CellType.exitLeft => Direction.left,
        CellType.exitRight => Direction.right,
        _ => null,
      };

  /// One-way hücresinin izin verdiği geçiş yönü
  Direction? get oneWayDirection => switch (this) {
        CellType.oneWayUp => Direction.up,
        CellType.oneWayDown => Direction.down,
        CellType.oneWayLeft => Direction.left,
        CellType.oneWayRight => Direction.right,
        _ => null,
      };

  static CellType fromDir(String dir) => switch (dir) {
        'up' => CellType.exitUp,
        'down' => CellType.exitDown,
        'left' => CellType.exitLeft,
        'right' => CellType.exitRight,
        _ => CellType.exitRight,
      };

  static CellType oneWayFromDir(String dir) => switch (dir) {
        'up' => CellType.oneWayUp,
        'down' => CellType.oneWayDown,
        'left' => CellType.oneWayLeft,
        'right' => CellType.oneWayRight,
        _ => CellType.oneWayRight,
      };
}

// ══════════════════════════════════════════════════════
// EXIT CELL MODEL
// ══════════════════════════════════════════════════════

class ExitCell {
  final int row;
  final int col;
  final CellType type;

  const ExitCell({required this.row, required this.col, required this.type});

  Direction get direction => type.exitDirection!;

  factory ExitCell.fromJson(Map<String, dynamic> j) => ExitCell(
        row: j['r'] as int,
        col: j['c'] as int,
        type: CellTypeExt.fromDir(j['dir'] as String),
      );
}

// ══════════════════════════════════════════════════════
// ONE-WAY CELL MODEL
// ══════════════════════════════════════════════════════

class OneWayCell {
  final int row;
  final int col;
  final CellType type; // oneWayUp/Down/Left/Right

  const OneWayCell({required this.row, required this.col, required this.type});

  Direction get allowedDirection => type.oneWayDirection!;

  factory OneWayCell.fromJson(Map<String, dynamic> j) => OneWayCell(
        row: j['r'] as int,
        col: j['c'] as int,
        type: CellTypeExt.oneWayFromDir(j['dir'] as String),
      );
}

// ══════════════════════════════════════════════════════
// TELEPORT CELL MODEL
// ══════════════════════════════════════════════════════

class TeleportCell {
  final int row;
  final int col;
  final bool isA; // A portalı mı, B portalı mı

  const TeleportCell({required this.row, required this.col, required this.isA});

  CellType get cellType => isA ? CellType.teleportA : CellType.teleportB;

  factory TeleportCell.fromJson(Map<String, dynamic> j) => TeleportCell(
        row: j['r'] as int,
        col: j['c'] as int,
        isA: (j['portal'] as String? ?? 'A') == 'A',
      );
}

// ══════════════════════════════════════════════════════
// CAR MODEL — Araç koordinatı her zaman HEAD hücresidir.
//
// HEAD = aracın baktığı yön (yani hareket yönü).
// BODY, head'den ters yönde uzar.
//
// Örnek: dir=RIGHT, size=2, head=(2,3)
//   Kaplanan hücreler: (2,3) ve (2,2)   [sağa bakıyor, kuyruk solda]
//
// Örnek: dir=UP, size=3, head=(1,2)
//   Kaplanan hücreler: (1,2), (2,2), (3,2)  [yukarı bakıyor, kuyruk aşağıda]
// ══════════════════════════════════════════════════════

class CarModel {
  final String id;
  final int row; // HEAD hücresi
  final int col; // HEAD hücresi
  final Direction direction;
  final int size; // 1, 2 veya 3
  final CarType type;
  final Color color;
  final bool isExited;

  /// Acil araç için: kaç hamle içinde çıkması gerekiyor (0 = sınır yok)
  final int emergencyMovesLeft;

  const CarModel({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.size = 1,
    this.type = CarType.standard,
    required this.color,
    this.isExited = false,
    this.emergencyMovesLeft = 0,
  });

  List<(int, int)> get occupiedCells {
    final (dr, dc) = direction.delta;
    return List.generate(size, (i) => (row - dr * i, col - dc * i));
  }

  (int, int) get headCell => (row, col);

  (int, int) get tailCell {
    final (dr, dc) = direction.delta;
    return (row - dr * (size - 1), col - dc * (size - 1));
  }

  bool occupies(int r, int c) => occupiedCells.contains((r, c));

  bool get isEmergency => type == CarType.emergency;
  bool get isVip => type == CarType.vip;
  bool get isSpinner => type == CarType.spinner;

  CarModel copyWith({
    int? row,
    int? col,
    bool? isExited,
    Direction? direction,
    int? emergencyMovesLeft,
  }) =>
      CarModel(
        id: id,
        row: row ?? this.row,
        col: col ?? this.col,
        direction: direction ?? this.direction,
        size: size,
        type: type,
        color: color,
        isExited: isExited ?? this.isExited,
        emergencyMovesLeft: emergencyMovesLeft ?? this.emergencyMovesLeft,
      );

  factory CarModel.fromJson(Map<String, dynamic> j, int colorIdx) {
    final carType = CarType.values.firstWhere(
      (t) => t.name == (j['type'] as String? ?? 'standard'),
      orElse: () => CarType.standard,
    );
    return CarModel(
      id: j['id'] as String,
      row: j['r'] as int,
      col: j['c'] as int,
      direction: DirectionExt.fromString(j['dir'] as String),
      size: (j['size'] as int?) ?? 1,
      type: carType,
      color: carType == CarType.vip
          ? AppTheme.vipColor
          : carType == CarType.emergency
              ? AppTheme.emergencyColor
              : (carType == CarType.truck || carType == CarType.tir)
                  ? AppTheme.truckColor
                  : AppTheme.carColors[colorIdx % AppTheme.carColors.length],
      emergencyMovesLeft: (j['emergency_moves'] as int?) ?? 0,
    );
  }

  @override
  String toString() =>
      'Car($id dir:${direction.name} head:($row,$col) size:$size exited:$isExited)';
}

// ══════════════════════════════════════════════════════
// LEVEL MODEL
// ══════════════════════════════════════════════════════

class LevelModel {
  final String id;
  final int chapter;
  final int level;
  final String name;
  final DifficultyLevel difficulty;
  final int rows;
  final int cols;
  final Set<(int, int)> walls;
  final List<ExitCell> exits;
  final List<OneWayCell> oneWays; // tek yönlü geçiş hücreleri
  final List<TeleportCell> portals; // teleport portal çiftleri (max 2)
  final List<CarModel> cars;
  final int parMoves;
  final int parTime;
  final List<String> hintSolution;
  final int unlockRequires;

  /// Bu levelde VIP araç varsa, önce VIP çıkmalı
  final bool vipRequired;

  const LevelModel({
    required this.id,
    required this.chapter,
    required this.level,
    required this.name,
    required this.difficulty,
    required this.rows,
    required this.cols,
    required this.walls,
    required this.exits,
    this.oneWays = const [],
    this.portals = const [],
    required this.cars,
    required this.parMoves,
    this.parTime = 0,
    required this.hintSolution,
    this.unlockRequires = 1,
    this.vipRequired = false,
  });

  bool isWall(int r, int c) => walls.contains((r, c));

  ExitCell? exitAt(int r, int c) {
    for (final e in exits) {
      if (e.row == r && e.col == c) return e;
    }
    return null;
  }

  OneWayCell? oneWayAt(int r, int c) {
    for (final ow in oneWays) {
      if (ow.row == r && ow.col == c) return ow;
    }
    return null;
  }

  /// Teleport portalının karşı tarafını bul
  TeleportCell? pairedPortal(TeleportCell portal) {
    for (final p in portals) {
      if (p.isA != portal.isA) return p;
    }
    return null;
  }

  TeleportCell? teleportAt(int r, int c) {
    for (final p in portals) {
      if (p.row == r && p.col == c) return p;
    }
    return null;
  }

  /// Dinamik bir grid cell tipi haritası oluştur (painter için)
  Map<(int, int), CellType> buildCellTypeMap() {
    final map = <(int, int), CellType>{};
    for (final w in walls) {
      map[w] = CellType.wall;
    }
    for (final e in exits) {
      map[(e.row, e.col)] = e.type;
    }
    for (final ow in oneWays) {
      map[(ow.row, ow.col)] = ow.type;
    }
    for (final p in portals) {
      map[(p.row, p.col)] = p.cellType;
    }
    return map;
  }

  factory LevelModel.fromJson(Map<String, dynamic> j) {
    final grid = j['grid'] as Map<String, dynamic>;

    final walls = (grid['walls'] as List? ?? [])
        .map((w) => (w['r'] as int, w['c'] as int))
        .toSet();

    final exits = (grid['exits'] as List? ?? [])
        .map((e) => ExitCell.fromJson(e as Map<String, dynamic>))
        .toList();

    final oneWays = (grid['one_ways'] as List? ?? [])
        .map((e) => OneWayCell.fromJson(e as Map<String, dynamic>))
        .toList();

    final portals = (grid['portals'] as List? ?? [])
        .map((e) => TeleportCell.fromJson(e as Map<String, dynamic>))
        .toList();

    final cars = (j['cars'] as List)
        .asMap()
        .entries
        .map((e) => CarModel.fromJson(e.value as Map<String, dynamic>, e.key))
        .toList();

    return LevelModel(
      id: j['id'] as String,
      chapter: j['chapter'] as int,
      level: j['level'] as int,
      name: j['name'] as String,
      difficulty: DifficultyLevel.values.firstWhere(
        (d) => d.name == (j['difficulty'] as String? ?? 'easy'),
        orElse: () => DifficultyLevel.easy,
      ),
      rows: grid['rows'] as int,
      cols: grid['cols'] as int,
      walls: walls,
      exits: exits,
      oneWays: oneWays,
      portals: portals,
      cars: cars,
      parMoves: j['par_moves'] as int,
      parTime: (j['par_time'] as int?) ?? 0,
      hintSolution: List<String>.from(j['hint_solution'] as List? ?? []),
      unlockRequires: (j['unlock_requires'] as int?) ?? 1,
      vipRequired: (j['vip_required'] as bool?) ?? false,
    );
  }
}

// ══════════════════════════════════════════════════════
// MOVE RESULT — Hareket motoru çıktısı
// ══════════════════════════════════════════════════════

class MoveResult {
  final CarModel car;
  final bool moved;
  final bool exited;
  final int steps;
  final bool crashed;

  /// Spinner döndü mü (hareket etmedi ama yön değişti)
  final bool rotated;

  /// Teleport geçişi oldu mu
  final bool teleported;

  const MoveResult({
    required this.car,
    required this.moved,
    required this.exited,
    required this.steps,
    this.crashed = false,
    this.rotated = false,
    this.teleported = false,
  });
}

// ══════════════════════════════════════════════════════
// GAME RESULT
// ══════════════════════════════════════════════════════

class GameResult {
  final int stars;
  final int moveCount;
  final int score;
  final int comboCount;
  final bool isPerfect;

  const GameResult({
    required this.stars,
    required this.moveCount,
    required this.score,
    required this.comboCount,
    required this.isPerfect,
  });

  static int starsFor(int moves, int par) {
    if (moves <= par) return 3;
    if (moves <= (par * 1.5).ceil()) return 2;
    return 1;
  }

  static int calcScore({
    required int moves,
    required int par,
    required int combos,
    required int hintsUsed,
    required int elapsedSec,
    required int parTime,
  }) {
    const base = 1000;
    final stars = starsFor(moves, par);
    final starBonus = stars == 3
        ? 500
        : stars == 2
            ? 200
            : 0;
    final comboBonus = combos * 100;
    final timeBonus =
        parTime > 0 ? ((parTime - elapsedSec).clamp(0, parTime) * 10) : 0;
    final penalty = hintsUsed * 150;
    return (base + starBonus + comboBonus + timeBonus - penalty).clamp(0, 9999);
  }
}
