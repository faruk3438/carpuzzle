// dart run tool/validate_levels.dart
//
// Tüm level JSON dosyalarını yükler:
// 1. Araç grid sınırları kontrolü
// 2. Araç çakışma kontrolü
// 3. Araç duvar üstünde mi kontrolü
// 4. BFS solver ile çözülebilirlik
// 5. parMoves + hintSolution önerisi
//
// Çıktı her level için: OK / HATA listesi + düzeltilmiş JSON
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

// ── Mini model kopyaları (lib'den bağımsız) ──────────────

enum Dir { up, down, left, right }

(int, int) delta(Dir d) => switch (d) {
      Dir.up    => (-1,  0),
      Dir.down  => ( 1,  0),
      Dir.left  => ( 0, -1),
      Dir.right => ( 0,  1),
    };

bool isHoriz(Dir d) => d == Dir.left || d == Dir.right;

Dir dirFromStr(String s) => switch (s) {
      'up'    => Dir.up,
      'down'  => Dir.down,
      'left'  => Dir.left,
      'right' => Dir.right,
      _       => Dir.right,
    };

class Car {
  final String id;
  final int row, col;
  final Dir dir;
  final int size;
  bool exited;

  Car(this.id, this.row, this.col, this.dir, this.size, {this.exited = false});

  List<(int, int)> get cells {
    final (dr, dc) = delta(dir);
    return List.generate(size, (i) => (row - dr * i, col - dc * i));
  }

  Car moved(int r, int c) => Car(id, r, c, dir, size);
  Car exit() => Car(id, row, col, dir, size, exited: true);

  @override
  String toString() => '$id@($row,$col)${dir.name}×$size';
}

class Exit {
  final int row, col;
  final Dir dir;
  Exit(this.row, this.col, this.dir);
}

class Level {
  final String id;
  final int rows, cols;
  final Set<(int, int)> walls;
  final List<Exit> exits;
  final List<Car> cars;
  final int parMoves;
  final List<String> hint;

  Level(this.id, this.rows, this.cols, this.walls, this.exits, this.cars,
      this.parMoves, this.hint);
}

// ── Validasyon ────────────────────────────────────────────

List<String> validateLevel(Level lv) {
  final errors = <String>[];

  // 1. Araç grid içinde mi?
  for (final car in lv.cars) {
    for (final (r, c) in car.cells) {
      if (r < 0 || r >= lv.rows || c < 0 || c >= lv.cols) {
        errors.add('${car.id} grid dışında: ($r,$c) — grid ${lv.rows}×${lv.cols}');
      }
    }
  }

  // 2. Araç duvar üstünde mi?
  for (final car in lv.cars) {
    for (final (r, c) in car.cells) {
      if (lv.walls.contains((r, c))) {
        errors.add('${car.id} duvar üstünde: ($r,$c)');
      }
    }
  }

  // 3. Araçlar çakışıyor mu?
  final occupied = <String, String>{};
  for (final car in lv.cars) {
    for (final cell in car.cells) {
      final key = '${cell.$1},${cell.$2}';
      if (occupied.containsKey(key)) {
        errors.add('${car.id} ve ${occupied[key]} çakışıyor: $key');
      }
      occupied[key] = car.id;
    }
  }

  return errors;
}

// ── BFS Solver ────────────────────────────────────────────

bool _hasExit(Level lv, Car car) {
  final (dr, dc) = delta(car.dir);
  final (borderR, borderC) = (car.row + dr, car.col + dc);
  for (final ex in lv.exits) {
    if (ex.dir != car.dir) continue;
    if (isHoriz(car.dir) && ex.row == car.row) return true;
    if (!isHoriz(car.dir) && ex.col == car.col) return true;
  }
  return false;
}

class BfsResult {
  final bool ok;
  final List<String> path;
  BfsResult(this.ok, this.path);
}

BfsResult bfsSolve(Level lv, {int maxDepth = 60}) {
  String key(List<Car> cars) => cars
      .map((c) => '${c.id}:${c.row},${c.col},${c.exited ? 1 : 0}')
      .join('|');

  bool isWon(List<Car> cars) => cars.every((c) => c.exited);

  List<Car> move(List<Car> cars, Car car) {
    if (car.exited) return cars;
    final (dr, dc) = delta(car.dir);
    final blocked = <String>{};
    for (final c in cars) {
      if (c.exited || c.id == car.id) continue;
      for (final (r, cc) in c.cells) {
        blocked.add('$r,$cc');
      }
    }

    int steps = 0;
    while (true) {
      final nextCells = car.cells
          .map((cell) => (cell.$1 + dr * (steps + 1), cell.$2 + dc * (steps + 1)))
          .toList();

      bool hitWall = false, hitBorder = false;
      for (final (nr, nc) in nextCells) {
        if (nr < 0 || nr >= lv.rows || nc < 0 || nc >= lv.cols) {
          hitBorder = true;
          break;
        }
        if (lv.walls.contains((nr, nc)) || blocked.contains('$nr,$nc')) {
          hitWall = true;
          break;
        }
      }

      if (hitWall) break;
      if (hitBorder) {
        // Exit kontrolü
        bool exitFound = false;
        for (final ex in lv.exits) {
          if (ex.dir != car.dir) continue;
          if (isHoriz(car.dir) && ex.row == car.row) { exitFound = true; break; }
          if (!isHoriz(car.dir) && ex.col == car.col) { exitFound = true; break; }
        }
        if (exitFound) {
          steps++;
          final newCar = Car(car.id, car.row + dr * steps,
              car.col + dc * steps, car.dir, car.size, exited: true);
          return cars.map((c) => c.id == car.id ? newCar : c).toList();
        }
        break;
      }
      steps++;
    }

    if (steps == 0) return cars;
    final newCar = Car(car.id, car.row + dr * steps,
        car.col + dc * steps, car.dir, car.size);
    return cars.map((c) => c.id == car.id ? newCar : c).toList();
  }

  final visited = <String>{};
  final queue = <(List<Car>, List<String>)>[];

  final init = lv.cars;
  visited.add(key(init));
  queue.add((init, []));

  int head = 0;
  while (head < queue.length) {
    final (cars, path) = queue[head++];
    if (path.length >= maxDepth) continue;

    for (final car in cars.where((c) => !c.exited)) {
      final newCars = move(cars, car);
      if (identical(newCars, cars)) continue;
      final newPath = [...path, car.id];
      if (isWon(newCars)) return BfsResult(true, newPath);
      final k = key(newCars);
      if (visited.contains(k)) continue;
      visited.add(k);
      queue.add((newCars, newPath));
    }
  }
  return BfsResult(false, []);
}

// ── JSON Yükleyici ────────────────────────────────────────

Level levelFromJson(Map<String, dynamic> j) {
  final grid = j['grid'] as Map<String, dynamic>;
  final walls = (grid['walls'] as List? ?? [])
      .map((w) => (w['r'] as int, w['c'] as int))
      .toSet();
  final exits = (grid['exits'] as List? ?? []).map((e) {
    return Exit(e['r'] as int, e['c'] as int, dirFromStr(e['dir'] as String));
  }).toList();
  final cars = (j['cars'] as List).map((c) {
    return Car(c['id'] as String, c['r'] as int, c['c'] as int,
        dirFromStr(c['dir'] as String), (c['size'] as int?) ?? 1);
  }).toList();

  return Level(
    j['id'] as String,
    grid['rows'] as int,
    grid['cols'] as int,
    walls,
    exits,
    cars,
    (j['par_moves'] as int?) ?? 999,
    List<String>.from(j['hint_solution'] as List? ?? []),
  );
}

// ── Main ──────────────────────────────────────────────────

void main() {
  final files = [
    'assets/levels/chapter_1.json',
    'assets/levels/chapter_2.json',
    'assets/levels/chapter_3.json',
  ];

  int totalOk = 0, totalFail = 0, totalFix = 0;

  for (final path in files) {
    print('\n═══ $path ═══');
    final content = File(path).readAsStringSync();
    final list = jsonDecode(content) as List;

    for (final raw in list) {
      final j = raw as Map<String, dynamic>;
      final lv = levelFromJson(j);

      final errors = validateLevel(lv);
      final bfs = bfsSolve(lv);

      final hasIssues = errors.isNotEmpty || !bfs.ok ||
          bfs.path.length != lv.parMoves;

      if (!hasIssues) {
        print('  ✅ ${lv.id} — parMoves=${lv.parMoves} OK');
        totalOk++;
        continue;
      }

      totalFail++;
      print('  ❌ ${lv.id}');

      for (final e in errors) print('     🔴 $e');

      if (!bfs.ok) {
        print('     🔴 BFS: ÇÖZÜLEMİYOR');
      } else {
        if (bfs.path.length != lv.parMoves) {
          print('     ⚠️  parMoves=${lv.parMoves} ama optimal=${bfs.path.length}');
          totalFix++;
        }
        final pathStr = bfs.path.join(' → ');
        print('     💡 Optimal çözüm (${bfs.path.length} hamle): $pathStr');

        // hint_solution karşılaştır
        if (lv.hint.join(',') != bfs.path.join(',')) {
          print('     ⚠️  hint_solution yanlış: [${lv.hint.join(", ")}]');
          print('     ✏️  Doğrusu: [${bfs.path.map((s) => '"$s"').join(", ")}]');
        }
      }
    }
  }

  print('\n════════════════════════════════');
  print('SONUÇ: $totalOk OK  |  $totalFail HATA  |  $totalFix parMoves uyuşmazlığı');
}
