import '../models/models.dart';
import '../models/move_engine.dart';

// ══════════════════════════════════════════════════════
// BFS SOLVER
//
// Bir level için BFS ile en kısa çözüm yolunu bulur.
// Sonuç:
//   - solution: araç ID sırasıyla optimal hamle listesi
//   - solvable: çözülebilir mi?
//   - optimalMoves: en az kaç hamlede çözülür (parMoves için)
//
// State kodlaması: her araç için "id:r,c,exited" → pipe ile birleştirilir,
// ID'ye göre sıralanır → deterministik hash.
// ══════════════════════════════════════════════════════

class SolverResult {
  final bool solvable;
  final List<String> solution; // araç ID'leri sırasıyla
  final int optimalMoves;

  const SolverResult({
    required this.solvable,
    required this.solution,
    required this.optimalMoves,
  });

  static const unsolvable = SolverResult(
    solvable: false,
    solution: [],
    optimalMoves: -1,
  );
}

class BfsSolver {
  const BfsSolver._();

  /// Leveli çöz. maxDepth ile arama sınırını belirle (varsayılan 50).
  static SolverResult solve(LevelModel level, {int maxDepth = 50}) {
    final initialCars = level.cars;

    if (_isWon(initialCars)) {
      return const SolverResult(solvable: true, solution: [], optimalMoves: 0);
    }

    // BFS kuyruğu: (cars_state, path_so_far)
    final queue = <_BfsNode>[];
    final visited = <String>{};

    final startKey = _stateKey(initialCars);
    visited.add(startKey);
    queue.add(_BfsNode(cars: initialCars, path: const []));

    int head = 0;

    while (head < queue.length) {
      final node = queue[head++];

      if (node.path.length >= maxDepth) continue;

      final activeCars = node.cars.where((c) => !c.isExited).toList();
      final moves = <_CandidateMove>[];

      for (final car in activeCars) {
        // VIP kural kontrolü: VIP olmayan araç çıkmaya çalışıyorsa
        // ve hâlâ VIP varsa, bu hamleyi VIP için değil diğerleri için
        // çıkış olarak işleme — MoveEngine zaten çıkışı verecek,
        // ama GameBloc'ta kural var. Solver burada sadece fiziksel
        // hareketi simüle eder; VIP kural uygulama GameBloc'ta.
        final result = MoveEngine.calculate(
          car: car,
          cars: activeCars,
          level: level,
        );

        if ((!result.moved && !result.rotated) || result.crashed) continue;
        moves.add(_CandidateMove(car: car, result: result));
      }

      moves.sort((a, b) {
        if (a.result.exited != b.result.exited) {
          return a.result.exited ? -1 : 1;
        }
        return 0;
      });

      for (final move in moves) {
        final car = move.car;
        final result = move.result;

        final newCars =
            node.cars.map((c) => c.id == car.id ? result.car : c).toList();

        final key = _stateKey(newCars);
        if (visited.contains(key)) continue;
        visited.add(key);

        final newPath = [...node.path, car.id];

        if (_isWon(newCars)) {
          return SolverResult(
            solvable: true,
            solution: newPath,
            optimalMoves: newPath.length,
          );
        }

        // Deadlock kontrolü: hiçbir araç hareket edemiyorsa bu dal ölü
        if (!MoveEngine.hasAnyMove(cars: newCars, level: level)) continue;

        queue.add(_BfsNode(cars: newCars, path: newPath));
      }
    }

    return SolverResult.unsolvable;
  }

  /// Birden fazla leveli toplu doğrula.
  static Map<String, SolverResult> validateAll(
    List<LevelModel> levels, {
    int maxDepth = 50,
  }) {
    final results = <String, SolverResult>{};
    for (final level in levels) {
      results[level.id] = solve(level, maxDepth: maxDepth);
    }
    return results;
  }

  static bool _isWon(List<CarModel> cars) => cars.every((c) => c.isExited);

  static String _stateKey(List<CarModel> cars) {
    final sorted = [...cars]..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map((c) =>
            '${c.id}:${c.row},${c.col},${c.direction.name},${c.isExited ? 1 : 0}')
        .join('|');
  }
}

class _BfsNode {
  final List<CarModel> cars;
  final List<String> path;
  const _BfsNode({required this.cars, required this.path});
}

class _CandidateMove {
  final CarModel car;
  final MoveResult result;
  const _CandidateMove({required this.car, required this.result});
}
