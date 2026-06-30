import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/models.dart';
import '../models/move_engine.dart';

// ══════════════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════════════

abstract class GameEvent {}

class GameLoaded extends GameEvent {
  final LevelModel level;
  GameLoaded(this.level);
}

class CarTapped extends GameEvent {
  final String carId;
  CarTapped(this.carId);
}

class UndoRequested extends GameEvent {}

class RestartRequested extends GameEvent {}

class HintRequested extends GameEvent {}

class RewardLifeGranted extends GameEvent {}

class RewardHintGranted extends GameEvent {}

class RewardUndoGranted extends GameEvent {}

class ComboPopupDismissed extends GameEvent {}

// ══════════════════════════════════════════════════════
// FAIL SEBEPLERI
// ══════════════════════════════════════════════════════

enum FailReason { none, deadlock, emergencyTimeout, noLives }

// ══════════════════════════════════════════════════════
// ÇARPMA SONUCU — Go Arrows: hareket edemez = çarpma
// ══════════════════════════════════════════════════════
enum CrashType { none, blocked, vipBlocked }

const int startingLives = 3;

class CrashEvent {
  final String carId;
  final CrashType type;
  const CrashEvent({required this.carId, required this.type});
}

// ══════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════

enum GameStatus { idle, playing, won, failed }

class GameState {
  final LevelModel? level;
  final List<CarModel> cars;
  final GameStatus status;
  final FailReason failReason;
  final int moveCount;
  final int lives;
  final int totalComboCount;
  final int consecutiveExits;
  final bool showCombo;
  final List<List<CarModel>> history;
  final int hintsUsed;
  final String? hintCarId;
  final GameResult? result;
  final MoveResult? lastMoveResult;

  /// Go Arrows: son çarpma bilgisi (animasyon için)
  final CrashEvent? lastCrash;

  const GameState({
    this.level,
    this.cars = const [],
    this.status = GameStatus.idle,
    this.failReason = FailReason.none,
    this.moveCount = 0,
    this.lives = 3,
    this.totalComboCount = 0,
    this.consecutiveExits = 0,
    this.showCombo = false,
    this.history = const [],
    this.hintsUsed = 0,
    this.hintCarId,
    this.result,
    this.lastMoveResult,
    this.lastCrash,
  });

  List<CarModel> get activeCars => cars.where((c) => !c.isExited).toList();
  bool get allExited => cars.every((c) => c.isExited);

  /// Levelde VIP araç var mı?
  bool get hasVip => cars.any((c) => c.isVip && !c.isExited);

  /// Hâlâ aktif emergency araç var mı?
  bool get hasActiveEmergency => cars.any((c) => c.isEmergency && !c.isExited);

  /// Emergency araçların kalan hamle sayısı (en küçüğü)
  int get minEmergencyMovesLeft => cars
      .where((c) => c.isEmergency && !c.isExited && c.emergencyMovesLeft > 0)
      .map((c) => c.emergencyMovesLeft)
      .fold(9999, (a, b) => a < b ? a : b);

  GameState copyWith({
    LevelModel? level,
    List<CarModel>? cars,
    GameStatus? status,
    FailReason? failReason,
    int? moveCount,
    int? lives,
    int? totalComboCount,
    int? consecutiveExits,
    bool? showCombo,
    List<List<CarModel>>? history,
    int? hintsUsed,
    String? hintCarId,
    bool clearHint = false,
    GameResult? result,
    MoveResult? lastMoveResult,
    bool clearMove = false,
    CrashEvent? lastCrash,
    bool clearCrash = false,
  }) =>
      GameState(
        level: level ?? this.level,
        cars: cars ?? this.cars,
        status: status ?? this.status,
        failReason: failReason ?? this.failReason,
        moveCount: moveCount ?? this.moveCount,
        lives: lives ?? this.lives,
        totalComboCount: totalComboCount ?? this.totalComboCount,
        consecutiveExits: consecutiveExits ?? this.consecutiveExits,
        showCombo: showCombo ?? this.showCombo,
        history: history ?? this.history,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        hintCarId: clearHint ? null : (hintCarId ?? this.hintCarId),
        result: result ?? this.result,
        lastMoveResult:
            clearMove ? null : (lastMoveResult ?? this.lastMoveResult),
        lastCrash: clearCrash ? null : (lastCrash ?? this.lastCrash),
      );
}

// ══════════════════════════════════════════════════════
// BLOC
// ══════════════════════════════════════════════════════

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(const GameState()) {
    on<GameLoaded>(_onLoaded);
    on<CarTapped>(_onCarTapped);
    on<UndoRequested>(_onUndo);
    on<RestartRequested>(_onRestart);
    on<HintRequested>(_onHint);
    on<RewardLifeGranted>(_onRewardLifeGranted);
    on<RewardHintGranted>(_onRewardHintGranted);
    on<RewardUndoGranted>(_onRewardUndoGranted);
    on<ComboPopupDismissed>(_onComboDismissed);
  }

  // ── GameLoaded ────────────────────────────────────────

  void _onLoaded(GameLoaded event, Emitter<GameState> emit) {
    emit(GameState(
      level: event.level,
      cars: List.from(event.level.cars),
      status: GameStatus.playing,
      lives: startingLives,
    ));
  }

  // ── CarTapped ─────────────────────────────────────────

  void _onCarTapped(CarTapped event, Emitter<GameState> emit) {
    final s = state;
    if (s.status != GameStatus.playing || s.level == null) return;

    final carIdx = s.cars.indexWhere((c) => c.id == event.carId);
    if (carIdx == -1) return;
    final car = s.cars[carIdx];
    if (car.isExited) return;

    final result = MoveEngine.calculate(
      car: car,
      cars: s.activeCars,
      level: s.level!,
    );

    // Spinner döndü ama hareket etmedi → state güncelle, hamle sayma
    if (result.rotated && !result.moved) {
      final newCars =
          s.cars.map((c) => c.id == car.id ? result.car : c).toList();
      emit(s.copyWith(
        cars: newCars,
        lastMoveResult: result,
        clearHint: true,
        clearCrash: true,
      ));
      return;
    }

    // ── Go Arrows Çarpma Mekaniği ─────────────────────────
    // Araç hiç hareket edemiyorsa → çarpma animasyonu
    if (result.crashed) {
      final newLives = (s.lives - 1).clamp(0, startingLives);
      final crash = CrashEvent(carId: car.id, type: CrashType.blocked);
      final newCars = result.moved
          ? s.cars.map((c) => c.id == car.id ? result.car : c).toList()
          : s.cars;
      var newHistory = s.history;
      if (result.moved) {
        newHistory = [...s.history, List<CarModel>.from(s.cars)];
        if (newHistory.length > 20) newHistory = newHistory.sublist(1);
      }

      emit(s.copyWith(
        cars: newCars,
        status: newLives == 0 ? GameStatus.failed : GameStatus.playing,
        failReason: newLives == 0 ? FailReason.noLives : FailReason.none,
        moveCount: result.moved ? s.moveCount + 1 : s.moveCount,
        lives: newLives,
        consecutiveExits: 0,
        showCombo: false,
        history: newHistory,
        lastMoveResult: result.moved ? result : null,
        lastCrash: crash,
        clearHint: true,
        clearMove: !result.moved,
      ));
      return;
    }

    // ── VIP Öncelik Kuralı ────────────────────────────────
    // Eğer level.vipRequired = true VE hâlâ aktif VIP varsa,
    // yalnızca VIP araçların çıkmasına izin ver.
    if (result.exited && s.level!.vipRequired) {
      final activeVip = s.activeCars.any((c) => c.isVip);
      if (activeVip && !car.isVip) {
        // VIP çıkmadan normal araç çıkamaz → uyarı (can kaybı YOK, sadece feedback)
        emit(s.copyWith(
          lastCrash: CrashEvent(carId: car.id, type: CrashType.vipBlocked),
          clearMove: true,
        ));
        return;
      }
    }

    // ── History ────────────────────────────────────────────
    var newHistory = [...s.history, List<CarModel>.from(s.cars)];
    if (newHistory.length > 20) newHistory = newHistory.sublist(1);

    // ── Araçları güncelle ─────────────────────────────────
    var newCars = s.cars.map((c) => c.id == car.id ? result.car : c).toList();

    // ── Emergency Countdown ──────────────────────────────
    // Her hamleden sonra tüm emergency araçların countdown'ı 1 azal
    newCars = _tickEmergencyCountdowns(newCars);

    // ── Combo ─────────────────────────────────────────────
    int consecutiveExits = result.exited ? s.consecutiveExits + 1 : 0;
    int totalComboCount = s.totalComboCount;
    bool showCombo = false;

    if (consecutiveExits >= 2) {
      totalComboCount++;
      showCombo = true;
    }

    final newMoves = s.moveCount + 1;

    // ── Emergency Timeout Kontrolü ───────────────────────
    final timedOut = newCars.any(
      (c) => c.isEmergency && !c.isExited && c.emergencyMovesLeft == 0,
    );
    if (timedOut) {
      emit(s.copyWith(
        cars: newCars,
        status: GameStatus.failed,
        failReason: FailReason.emergencyTimeout,
        moveCount: newMoves,
        history: newHistory,
        lastMoveResult: result,
        clearHint: true,
      ));
      return;
    }

    // ── Kazanç Kontrolü ───────────────────────────────────
    final allExited = newCars.every((c) => c.isExited);
    GameStatus newStatus = GameStatus.playing;
    GameResult? gameResult;

    if (allExited) {
      newStatus = GameStatus.won;
      final par = s.level!.parMoves;
      final stars = GameResult.starsFor(newMoves, par);
      gameResult = GameResult(
        stars: stars,
        moveCount: newMoves,
        score: GameResult.calcScore(
          moves: newMoves,
          par: par,
          combos: totalComboCount,
          hintsUsed: s.hintsUsed,
          elapsedSec: 0,
          parTime: s.level!.parTime,
        ),
        comboCount: totalComboCount,
        isPerfect: newMoves <= par,
      );
    } else {
      // Deadlock kontrolü
      final deadlock = !MoveEngine.hasAnyMove(cars: newCars, level: s.level!);
      if (deadlock) {
        emit(s.copyWith(
          cars: newCars,
          status: GameStatus.failed,
          failReason: FailReason.deadlock,
          moveCount: newMoves,
          totalComboCount: totalComboCount,
          consecutiveExits: consecutiveExits,
          showCombo: showCombo,
          history: newHistory,
          lastMoveResult: result,
          clearHint: true,
        ));
        return;
      }
    }

    emit(s.copyWith(
      cars: newCars,
      status: newStatus,
      moveCount: newMoves,
      totalComboCount: totalComboCount,
      consecutiveExits: consecutiveExits,
      showCombo: showCombo,
      history: newHistory,
      lastMoveResult: result,
      result: gameResult,
      clearHint: true,
    ));
  }

  // ── Undo ─────────────────────────────────────────────

  void _onUndo(UndoRequested event, Emitter<GameState> emit) {
    _undo(emit);
  }

  void _undo(Emitter<GameState> emit) {
    final s = state;
    if (s.history.isEmpty) return;
    final prev = s.history.last;
    emit(s.copyWith(
      cars: prev,
      history: s.history.sublist(0, s.history.length - 1),
      moveCount: (s.moveCount - 1).clamp(0, 9999),
      status: GameStatus.playing,
      failReason: FailReason.none,
      consecutiveExits: 0,
      showCombo: false,
      clearHint: true,
      clearMove: true,
    ));
  }

  // ── Restart ──────────────────────────────────────────

  void _onRestart(RestartRequested event, Emitter<GameState> emit) {
    final level = state.level;
    if (level == null) return;
    emit(GameState(
      level: level,
      cars: List.from(level.cars),
      status: GameStatus.playing,
      lives: startingLives,
    ));
  }

  // ── Hint ─────────────────────────────────────────────

  void _onHint(HintRequested event, Emitter<GameState> emit) {
    _showHint(emit);
  }

  void _onRewardHintGranted(
    RewardHintGranted event,
    Emitter<GameState> emit,
  ) {
    _showHint(emit);
  }

  void _showHint(Emitter<GameState> emit) {
    final s = state;
    final solution = s.level?.hintSolution ?? [];
    if (solution.isEmpty) return;
    final idx = s.moveCount.clamp(0, solution.length - 1);
    emit(s.copyWith(hintCarId: solution[idx], hintsUsed: s.hintsUsed + 1));
  }

  void _onRewardUndoGranted(
    RewardUndoGranted event,
    Emitter<GameState> emit,
  ) {
    _undo(emit);
  }

  void _onRewardLifeGranted(
    RewardLifeGranted event,
    Emitter<GameState> emit,
  ) {
    final s = state;
    if (s.lives >= startingLives) return;
    emit(s.copyWith(
      lives: (s.lives + 1).clamp(0, startingLives),
      status:
          s.failReason == FailReason.noLives ? GameStatus.playing : s.status,
      failReason:
          s.failReason == FailReason.noLives ? FailReason.none : s.failReason,
      clearCrash: true,
    ));
  }

  // ── Combo Dismiss ────────────────────────────────────

  void _onComboDismissed(ComboPopupDismissed event, Emitter<GameState> emit) {
    emit(state.copyWith(showCombo: false));
  }

  // ── Yardımcılar ──────────────────────────────────────

  List<CarModel> _tickEmergencyCountdowns(List<CarModel> cars) {
    return cars.map((c) {
      if (c.isEmergency && !c.isExited && c.emergencyMovesLeft > 0) {
        return c.copyWith(emergencyMovesLeft: c.emergencyMovesLeft - 1);
      }
      return c;
    }).toList();
  }
}
