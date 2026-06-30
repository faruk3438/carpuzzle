import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/models.dart';
import '../services/sound_service.dart';
import 'grid_painter.dart';

// ══════════════════════════════════════════════════════
// GAME GRID
//
// Hareket animasyonu: araç ESKI konumdan YENİ konuma kayar.
//   animOffset = -target*(1-t) → başlangıçta negatif,
//   sona doğru sıfıra yaklaşır → araç eski yerden çekilir.
//
// Çarpma animasyonu: araç küçük bump yapıp geri döner.
//   crashOffset = target * sin(t*π) → 0 → peak → 0
//   crashIntensity aynı formülle kırmızı flash için.
//
// Performans notu: setState KULLANILMAZ animasyon tick'lerinde.
// AnimatedBuilder yalnızca ilgili katmanı yeniden çizer.
// ══════════════════════════════════════════════════════

class GameGrid extends StatefulWidget {
  final bool showGridCoordinates;

  const GameGrid({
    super.key,
    this.showGridCoordinates = false,
  });

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> with TickerProviderStateMixin {
  static const int _carImageDecodeWidth = 256;
  static const Map<String, String> _carImageAssets = {
    'car_red': 'assets/images/car_red.png',
    'car_blue': 'assets/images/car_blue.png',
    'car_yellow': 'assets/images/car_yellow.png',
    'car_green': 'assets/images/car_green.png',
    'car_orange': 'assets/images/car_orange.png',
    'suv_blue': 'assets/images/suv_blue.png',
    'suv_red': 'assets/images/suv_red.png',
    'suv_green': 'assets/images/suv_green.png',
    'truck': 'assets/images/truck.png',
    'tir': 'assets/images/tir.png',
    'vip': 'assets/images/vip.png',
    'ambulans': 'assets/images/ambulans.png',
  };

  static Future<Map<String, ui.Image>>? _sharedCarImages;

  Map<String, ui.Image> _carImages = const {};

  // ── Hareket animasyonu ─────────────────────────────────
  late final AnimationController _moveCtrl;
  String? _animCarId;
  Offset _animTarget = Offset.zero;

  // ── Çarpma animasyonu ─────────────────────────────────
  late final AnimationController _crashCtrl;
  String? _crashCarId;
  Offset _crashTarget = Offset.zero;
  CrashType _crashType = CrashType.none;

  // ── Ekran titremesi ────────────────────────────────────
  late final AnimationController _shakeCtrl;

  double _pendingCellSize = 1.0;

  @override
  void initState() {
    super.initState();

    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _crashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _loadCarImages();
  }

  @override
  void dispose() {
    _moveCtrl.dispose();
    _crashCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCarImages() async {
    try {
      final images = await (_sharedCarImages ??= _decodeCarImages());
      if (!mounted) return;
      setState(() => _carImages = images);
    } catch (_) {
      _sharedCarImages = null;
    }
  }

  static Future<Map<String, ui.Image>> _decodeCarImages() async {
    final loaded = await Future.wait(
      _carImageAssets.entries.map((entry) async {
        final data = await rootBundle.load(entry.value);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: _carImageDecodeWidth,
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return MapEntry(entry.key, frame.image);
      }),
    );
    return Map.unmodifiable(Map.fromEntries(loaded));
  }

  // ── Animasyon tetikleyicileri ──────────────────────────

  void _triggerMoveAnim(MoveResult result, double cs) {
    _moveCtrl.stop();
    final (dr, dc) = result.car.direction.delta;
    _animCarId = result.car.id;
    _animTarget = Offset(dc * result.steps * cs, dr * result.steps * cs);

    _moveCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _animCarId = null);
    });

    if (result.exited) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) SoundService.instance.playCarExit();
      });
    } else {
      SoundService.instance.playCarMove();
    }
  }

  void _triggerCrashAnim(CrashEvent crash, GameState state, double cs) {
    _crashCtrl.stop();

    final car = state.cars.firstWhere(
      (c) => c.id == crash.carId,
      orElse: () => state.cars.first,
    );
    final (dr, dc) = car.direction.delta;

    _crashCarId = crash.carId;
    _crashType = crash.type;
    _crashTarget = Offset(dc * 9.0, dr * 9.0);

    _crashCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _crashCarId = null);
    });

    if (crash.type == CrashType.blocked) {
      SoundService.instance.playCarCrash();
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 90), () {
        if (mounted) HapticFeedback.mediumImpact();
      });
    } else {
      SoundService.instance.playCarCrash(heavy: false);
      HapticFeedback.lightImpact();
    }
  }

  // ── Tap tespiti ───────────────────────────────────────

  void _onTap(Offset local, Size size, GameState state) {
    if (state.level == null || state.status != GameStatus.playing) return;
    final level = state.level!;
    final layout = GridPainter.boardLayout(size, level);
    final cs = layout.cellSize;
    final ox = layout.offsetX;
    final oy = layout.offsetY;

    final col = ((local.dx - ox) / cs).floor();
    final row = (((local.dy - oy) / layout.verticalScale) / cs).floor();
    if (row < 0 || row >= level.rows || col < 0 || col >= level.cols) return;

    CarModel? tapped;
    for (final car in state.activeCars) {
      if (car.occupies(row, col)) {
        tapped = car;
        break;
      }
    }
    if (tapped == null) return;

    SoundService.instance.playTap();
    context.read<GameBloc>().add(CarTapped(tapped.id));
    _pendingCellSize = cs;
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GameBloc, GameState>(
          listenWhen: (p, c) =>
              c.lastMoveResult != null && c.lastMoveResult != p.lastMoveResult,
          listener: (ctx, state) {
            _triggerMoveAnim(state.lastMoveResult!, _pendingCellSize);
          },
        ),
        BlocListener<GameBloc, GameState>(
          listenWhen: (p, c) =>
              c.lastCrash != null && c.lastCrash != p.lastCrash,
          listener: (ctx, state) {
            _triggerCrashAnim(state.lastCrash!, state, _pendingCellSize);
          },
        ),
      ],
      child: BlocBuilder<GameBloc, GameState>(
        buildWhen: (p, c) =>
            p.cars != c.cars ||
            p.hintCarId != c.hintCarId ||
            p.lastMoveResult != c.lastMoveResult ||
            p.lastCrash != c.lastCrash,
        builder: (context, state) {
          if (state.level == null) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (ctx, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              // Titreme katmanı: sadece _shakeCtrl değişince rebuild olur.
              return SizedBox.expand(
                child: AnimatedBuilder(
                  animation: _shakeCtrl,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _onTap(d.localPosition, size, state),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Zemin katmanı: level değişmediği sürece repaint yok.
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              key: const Key('game_grid_board_layer'),
                              size: size,
                              painter: GridPainter(
                                level: state.level!,
                                cars: const [],
                                showGridCoordinates: widget.showGridCoordinates,
                                paintCars: false,
                              ),
                            ),
                          ),
                        ),
                        // Araç katmanı: her animasyon frame'inde sadece bu katman çizilir.
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation:
                                  Listenable.merge([_moveCtrl, _crashCtrl]),
                              builder: (context, _) {
                                final v = _moveCtrl.value;
                                final animOffset = _animCarId != null
                                    ? Offset(
                                        _animTarget.dx * (v - 1.0),
                                        _animTarget.dy * (v - 1.0),
                                      )
                                    : Offset.zero;

                                final bump =
                                    math.sin(_crashCtrl.value * math.pi);
                                final crashOffset = _crashCarId != null
                                    ? Offset(_crashTarget.dx * bump,
                                        _crashTarget.dy * bump)
                                    : Offset.zero;
                                final crashIntensity =
                                    _crashCarId != null ? bump : 0.0;

                                return CustomPaint(
                                  key: const Key('game_grid_car_layer'),
                                  size: size,
                                  painter: GridPainter(
                                    level: state.level!,
                                    cars: state.cars,
                                    hintCarId: state.hintCarId,
                                    animCarId: _animCarId,
                                    animOffset: animOffset,
                                    crashCarId: _crashCarId,
                                    crashOffset: crashOffset,
                                    crashIntensity: crashIntensity,
                                    crashType: _crashType,
                                    carImages: _carImages,
                                    paintBoard: false,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  builder: (context, child) {
                    final t = _shakeCtrl.value;
                    final shakeX = math.sin(t * math.pi * 7) * 5.5 * (1 - t);
                    return Transform.translate(
                      offset: Offset(shakeX, 0),
                      child: child,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
