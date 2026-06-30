import 'models.dart';

// ══════════════════════════════════════════════════════
// MOVE ENGINE v2
//
// Hareket kuralları:
//   1. Araç HEAD yönünde ilerler.
//   2. Her adımda HEAD + tüm body hücreleri kontrol edilir.
//   3. Engel: duvar veya başka araç.
//   4. Çıkış: araç kendi yönünde grid dışına taşarsa board'dan çıkar.
//   5. One-way: hücre sadece belirtilen yönde geçilebilir.
//      Ters yönden geçmeye çalışan araç bloke olur.
//   6. Teleport: araç bir portala girince karşı portala çıkar.
//      Çıkış pozisyonunda başka araç varsa teleport blokeli.
//   7. Spinner: tap atınca hareket edemiyorsa 90° CW döner.
//   8. Hareket atomiktir: ya tam gider ya 0 adım.
// ══════════════════════════════════════════════════════

class MoveEngine {
  const MoveEngine._();

  /// Bir araç için hareket hesapla.
  static MoveResult calculate({
    required CarModel car,
    required List<CarModel> cars,
    required LevelModel level,
  }) {
    if (car.isExited) {
      return MoveResult(
        car: car,
        moved: false,
        exited: false,
        steps: 0,
        crashed: true,
      );
    }

    final (dr, dc) = car.direction.delta;
    final blocked = _buildBlockedSet(cars, excludeId: car.id);

    int steps = 0;

    while (true) {
      final nextCells = car.occupiedCells
          .map((cell) =>
              (cell.$1 + dr * (steps + 1), cell.$2 + dc * (steps + 1)))
          .toList();

      bool hitWall = false;
      bool hitBorder = false;

      for (final (nr, nc) in nextCells) {
        if (nr < 0 || nr >= level.rows || nc < 0 || nc >= level.cols) {
          hitBorder = true;
          break;
        }
        if (level.isWall(nr, nc)) {
          hitWall = true;
          break;
        }
        if (blocked.contains('$nr,$nc')) {
          hitWall = true;
          break;
        }
        // One-way kontrol: bu hücreye araç yönünde girilebilir mi?
        final ow = level.oneWayAt(nr, nc);
        if (ow != null && ow.allowedDirection != car.direction) {
          hitWall = true;
          break;
        }
      }

      if (hitWall) break;

      if (hitBorder) {
        steps++;
        return MoveResult(
          car: car.copyWith(
            row: car.row + dr * steps,
            col: car.col + dc * steps,
            isExited: true,
          ),
          moved: true,
          exited: true,
          steps: steps,
        );
      }

      // Teleport kontrolü: HEAD'in bir sonraki pozisyonu portal mı?
      final nextHeadR = car.row + dr * (steps + 1);
      final nextHeadC = car.col + dc * (steps + 1);
      final portal = level.teleportAt(nextHeadR, nextHeadC);

      if (portal != null) {
        final paired = level.pairedPortal(portal);
        if (paired != null) {
          // Karşı portaldan çıkış pozisyonu
          final exitR = paired.row + dr;
          final exitC = paired.col + dc;

          // Çıkış pozisyonu grid içinde ve boş mu?
          bool canTeleport = true;
          if (exitR < 0 ||
              exitR >= level.rows ||
              exitC < 0 ||
              exitC >= level.cols) {
            canTeleport = false;
          } else if (level.isWall(exitR, exitC)) {
            canTeleport = false;
          } else if (blocked.contains('$exitR,$exitC')) {
            canTeleport = false;
          }

          if (canTeleport) {
            steps++;
            final teleportedCar = car.copyWith(
              row: exitR,
              col: exitC,
            );
            return MoveResult(
              car: teleportedCar,
              moved: true,
              exited: false,
              steps: steps,
              teleported: true,
            );
          }
        }
      }

      steps++;
    }

    // Spinner tamamen cikamiyorsa ilerleyip can kaybettirmek yerine doner.
    if (car.isSpinner) {
      final rotated = car.copyWith(direction: car.direction.rotatedCW);
      return MoveResult(
        car: rotated,
        moved: false,
        exited: false,
        steps: 0,
        rotated: true,
      );
    }

    if (steps == 0) {
      return MoveResult(
        car: car,
        moved: false,
        exited: false,
        steps: 0,
        crashed: true,
      );
    }

    return MoveResult(
      car: car.copyWith(
        row: car.row + dr * steps,
        col: car.col + dc * steps,
      ),
      moved: true,
      exited: false,
      steps: steps,
      crashed: true,
    );
  }

  /// Herhangi bir araç hareket edebilir mi? (deadlock kontrolü)
  static bool hasAnyMove({
    required List<CarModel> cars,
    required LevelModel level,
  }) {
    final active = cars.where((c) => !c.isExited).toList();
    for (final car in active) {
      final result = calculate(car: car, cars: active, level: level);
      if (result.moved || result.rotated) return true;
    }
    return false;
  }

  // ── Yardımcılar ───────────────────────────────────────

  static Set<String> _buildBlockedSet(List<CarModel> cars,
      {required String excludeId}) {
    final set = <String>{};
    for (final car in cars) {
      if (car.isExited || car.id == excludeId) continue;
      for (final (r, c) in car.occupiedCells) {
        set.add('$r,$c');
      }
    }
    return set;
  }
}
