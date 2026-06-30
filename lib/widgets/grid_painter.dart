import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../bloc/game_bloc.dart' show CrashType;
import '../models/models.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════
// GRID PAINTER — Otopark zemini + top-down araçlar
// ══════════════════════════════════════════════════════

class GridPainter extends CustomPainter {
  static const double boardScale = 1.0;
  static const double boardVerticalScale = 1.24;
  static const double maxBoardVerticalScale = 1.58;
  static const Color _paper = Colors.white;
  static const Color _ink = Colors.black;
  static const Color _asphaltTop = Color(0xFF172B3D);
  static const Color _asphaltBottom = Color(0xFF0A1624);
  static const Color _parkingLine = Color(0xFF50D8FF);
  static const Color _parkingLineWarm = Color(0xFFFFD34D);

  // Sabit Paint nesneleri — her repaint'te yeniden oluşturulmaz.
  static final Paint _boardBorderPaint = Paint()
    ..color = const Color(0x6158DFFF)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  static final Paint _parkingOuterBorderPaint = Paint()
    ..color = const Color(0x4750D8FF)
    ..strokeWidth = 0.9
    ..style = PaintingStyle.stroke;

  static final Paint _wallXPaint = Paint()
    ..color = const Color(0xC2FFD34D)
    ..strokeWidth = 1.5;

  static final Paint _asphaltSpeckPaint = Paint()
    ..color = const Color(0x09FFFFFF);

  static final Paint _asphaltDarkPaint = Paint()
    ..color = const Color(0x1F000000);

  static final Paint _oneWayArrowPaint = Paint()
    ..color = const Color(0xFF75F3FF)
    ..strokeWidth = 2.2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _oneWayBgPaint = Paint()..color = const Color(0x1F17B9D6);

  static final Paint _oneWayBorderPaint = Paint()
    ..color = const Color(0x8A75F3FF)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  static final Paint _carImagePaint = Paint()
    ..filterQuality = FilterQuality.high;

  // Hint çerçevesi için blur olan kenarlık.
  static final Paint _hintStrokePaint = Paint()
    ..color = const Color(0xFFFFE45E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  static final RegExp _digitRegex = RegExp(r'\d+');

  static const List<String> _standardCarPattern = [
    'car_red',
    'car_blue',
    'car_yellow',
    'car_green',
    'car_orange',
    'car_red',
    'car_blue',
    'car_green',
    'car_orange',
    'car_yellow',
    'car_red',
    'car_blue',
  ];

  static const List<String> _suvPattern = [
    'suv_blue',
    'suv_red',
    'suv_green',
    'suv_blue',
    'suv_red',
    'suv_green',
  ];

  static const Map<String, Rect> _carImageVisibleBounds = {
    'ambulans': Rect.fromLTRB(0.266, 0.080, 0.730, 0.908),
    'car_blue': Rect.fromLTRB(0.275, 0.082, 0.727, 0.863),
    'car_green': Rect.fromLTRB(0.287, 0.117, 0.699, 0.828),
    'car_orange': Rect.fromLTRB(0.285, 0.096, 0.709, 0.824),
    'car_red': Rect.fromLTRB(0.244, 0.025, 0.758, 0.904),
    'car_yellow': Rect.fromLTRB(0.285, 0.092, 0.715, 0.832),
    'suv_blue': Rect.fromLTRB(0.301, 0.174, 0.688, 0.785),
    'suv_green': Rect.fromLTRB(0.289, 0.133, 0.715, 0.756),
    'suv_red': Rect.fromLTRB(0.289, 0.133, 0.717, 0.764),
    'tir': Rect.fromLTRB(0.365, 0.023, 0.635, 0.975),
    'truck': Rect.fromLTRB(0.316, 0.068, 0.664, 0.844),
    'vip': Rect.fromLTRB(0.291, 0.121, 0.715, 0.785),
  };

  final LevelModel level;
  final List<CarModel> cars;
  final String? hintCarId;
  final String? animCarId;
  final Offset animOffset;
  final String? crashCarId;
  final Offset crashOffset;
  final double crashIntensity; // 0-1, sin eğrisi ile driven
  final CrashType crashType;
  final Map<String, ui.Image> carImages;
  final bool showGridCoordinates;
  final bool paintBoard;
  final bool paintCars;

  const GridPainter({
    required this.level,
    required this.cars,
    this.hintCarId,
    this.animCarId,
    this.animOffset = Offset.zero,
    this.crashCarId,
    this.crashOffset = Offset.zero,
    this.crashIntensity = 0.0,
    this.crashType = CrashType.none,
    this.carImages = const {},
    this.showGridCoordinates = false,
    this.paintBoard = true,
    this.paintCars = true,
  });

  static ({
    double cellSize,
    double offsetX,
    double offsetY,
    double verticalScale,
  }) boardLayout(Size size, LevelModel level) {
    final widthCellSize = size.width / level.cols;
    final heightFitScale = size.height / (widthCellSize * level.rows);
    final verticalScale =
        heightFitScale.clamp(boardVerticalScale, maxBoardVerticalScale);
    final cellSize = math.min(
          widthCellSize,
          size.height / (level.rows * verticalScale),
        ) *
        boardScale;

    return (
      cellSize: cellSize,
      offsetX: (size.width - cellSize * level.cols) / 2,
      offsetY: (size.height - cellSize * level.rows * verticalScale) / 2,
      verticalScale: verticalScale,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final layout = boardLayout(size, level);
    final cs = layout.cellSize;
    final ox = layout.offsetX;
    final oy = layout.offsetY;

    canvas.save();
    canvas.translate(0, oy);
    canvas.scale(1, layout.verticalScale);

    if (paintBoard) {
      _drawParkingLotBg(canvas, ox, 0, cs);
      _drawParkingLines(canvas, ox, 0, cs);
      if (showGridCoordinates) {
        _drawGridCoordinates(canvas, ox, 0, cs);
      }
      _drawWalls(canvas, ox, 0, cs);
      _drawOneWays(canvas, ox, 0, cs);
      _drawPortals(canvas, ox, 0, cs);
    }
    if (paintCars) {
      _drawCars(canvas, ox, 0, cs);
    }

    canvas.restore();
  }

  // ═══════════════════════════════════════════════════
  // OTOPARK ZEMİNİ
  // ═══════════════════════════════════════════════════

  void _drawParkingLotBg(Canvas canvas, double ox, double oy, double cs) {
    final bounds = Rect.fromLTWH(ox, oy, cs * level.cols, cs * level.rows);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.inflate(9), const Radius.circular(26)),
      Paint()
        ..color = const Color(0xFF118DFF).withOpacity(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(20)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_asphaltTop, _asphaltBottom],
        ).createShader(bounds),
    );

    _drawAsphaltTexture(canvas, bounds, cs);

    for (int r = 0; r < level.rows; r++) {
      for (int c = 0; c < level.cols; c++) {
        if (level.isWall(r, c)) continue;
        final rect = Rect.fromLTWH(
          ox + c * cs + 2.5,
          oy + r * cs + 2.5,
          cs - 5,
          cs - 5,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1F3A50).withOpacity(0.52),
                const Color(0xFF0B1C2B).withOpacity(0.22),
              ],
            ).createShader(rect),
        );
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(20)),
      _boardBorderPaint,
    );
  }

  void _drawParkingLines(Canvas canvas, double ox, double oy, double cs) {
    final linePaint = Paint()
      ..color = _parkingLine.withOpacity(0.34)
      ..strokeWidth = math.max(0.75, cs * 0.012)
      ..strokeCap = StrokeCap.round;
    final softPaint = Paint()
      ..color = const Color(0xFF3B789D).withOpacity(0.08)
      ..strokeWidth = math.max(0.5, cs * 0.005)
      ..strokeCap = StrokeCap.round;

    // Yatay çizgiler
    for (int r = 1; r < level.rows; r++) {
      final y = oy + r * cs;
      canvas.drawLine(
        Offset(ox + cs * 0.16, y),
        Offset(ox + level.cols * cs - cs * 0.16, y),
        softPaint,
      );
    }

    // Dikey çizgiler
    for (int c = 1; c < level.cols; c++) {
      final x = ox + c * cs;
      canvas.drawLine(
        Offset(x, oy + cs * 0.16),
        Offset(x, oy + level.rows * cs - cs * 0.16),
        softPaint,
      );
    }

    for (int r = 0; r < level.rows; r++) {
      for (int c = 0; c < level.cols; c++) {
        if (level.isWall(r, c)) continue;
        final left = ox + c * cs + cs * 0.17;
        final right = ox + (c + 1) * cs - cs * 0.17;
        final top = oy + r * cs + cs * 0.12;
        final bottom = oy + (r + 1) * cs - cs * 0.12;
        canvas.drawLine(Offset(left, top), Offset(right, top), linePaint);
        canvas.drawLine(Offset(left, bottom), Offset(right, bottom), linePaint);
        canvas.drawLine(
            Offset(left, top), Offset(left, top + cs * 0.18), linePaint);
        canvas.drawLine(
            Offset(right, top), Offset(right, top + cs * 0.18), linePaint);
        canvas.drawLine(
            Offset(left, bottom - cs * 0.18), Offset(left, bottom), linePaint);
        canvas.drawLine(Offset(right, bottom - cs * 0.18),
            Offset(right, bottom), linePaint);

        final exit = level.exitAt(r, c);
        if (exit != null) {
          final exitRect = Rect.fromLTWH(
            ox + c * cs + cs * 0.08,
            oy + r * cs + cs * 0.08,
            cs * 0.84,
            cs * 0.84,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(exitRect, Radius.circular(cs * 0.12)),
            Paint()..color = _parkingLineWarm.withOpacity(0.12),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(exitRect, Radius.circular(cs * 0.12)),
            Paint()
              ..color = _parkingLineWarm.withOpacity(0.8)
              ..strokeWidth = math.max(1.2, cs * 0.02)
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }

    // Dış kenarlık
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(ox, oy, cs * level.cols, cs * level.rows),
        const Radius.circular(20),
      ),
      _parkingOuterBorderPaint,
    );
  }

  void _drawGridCoordinates(Canvas canvas, double ox, double oy, double cs) {
    final fontSize = (cs * 0.16).clamp(6.0, 11.0);
    final textStyle = TextStyle(
      color: const Color(0xFF7DAAC3).withOpacity(0.48),
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    final margin = math.max(2.0, cs * 0.08);

    for (int r = 0; r < level.rows; r++) {
      for (int c = 0; c < level.cols; c++) {
        if (level.isWall(r, c)) continue;
        final label = '${_rowLabel(r)}${c + 1}';
        final tp = TextPainter(
          text: TextSpan(text: label, style: textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: cs - margin * 2);

        final cellLeft = ox + c * cs;
        final cellTop = oy + r * cs;
        tp.paint(canvas, Offset(cellLeft + margin, cellTop + margin));
      }
    }
  }

  String _rowLabel(int row) {
    var value = row;
    final letters = StringBuffer();
    do {
      final remainder = value % 26;
      letters.writeCharCode(65 + remainder);
      value = value ~/ 26 - 1;
    } while (value >= 0);
    return letters.toString().split('').reversed.join();
  }

  void _drawAsphaltTexture(Canvas canvas, Rect bounds, double cs) {
    final speckPaint = _asphaltSpeckPaint;
    final darkPaint = _asphaltDarkPaint;
    final step = math.max(12.0, cs * 0.23);
    for (double y = bounds.top + step * 0.5; y < bounds.bottom; y += step) {
      for (double x = bounds.left + step * 0.35; x < bounds.right; x += step) {
        final n = math.sin(x * 12.9898 + y * 78.233);
        final dx = (n - n.floorToDouble()) * step * 0.38;
        final dy = (math.cos(x * 4.11 + y * 9.31) + 1) * step * 0.16;
        canvas.drawCircle(Offset(x + dx, y + dy), 0.7, speckPaint);
        if (n > 0.45) {
          canvas.drawCircle(Offset(x - dx * 0.4, y - dy * 0.3), 0.9, darkPaint);
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // DUVARLAR — Beton kolon görünümü
  // ═══════════════════════════════════════════════════

  void _drawWalls(Canvas canvas, double ox, double oy, double cs) {
    for (final (r, c) in level.walls) {
      final rect = Rect.fromLTWH(ox + c * cs, oy + r * cs, cs, cs);
      final inner = rect.deflate(2);

      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(7)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF53677A), Color(0xFF202D3A)],
          ).createShader(inner),
      );

      canvas.drawLine(Offset(inner.left + 5, inner.top + 5),
          Offset(inner.right - 5, inner.bottom - 5), _wallXPaint);
      canvas.drawLine(Offset(inner.right - 5, inner.top + 5),
          Offset(inner.left + 5, inner.bottom - 5), _wallXPaint);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.2),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.white.withOpacity(0.14),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(7)),
        Paint()
          ..color = const Color(0xFF93A6B8).withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  // ═══════════════════════════════════════════════════
  // ONE-WAY HÜCRELER
  // ═══════════════════════════════════════════════════

  void _drawOneWays(Canvas canvas, double ox, double oy, double cs) {
    for (final ow in level.oneWays) {
      final rect = Rect.fromLTWH(ox + ow.col * cs, oy + ow.row * cs, cs, cs);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
          _oneWayBgPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
          _oneWayBorderPaint);
      _arrow(canvas, rect.center, ow.allowedDirection, cs * 0.28,
          _oneWayArrowPaint);
    }
  }

  // ═══════════════════════════════════════════════════
  // TELEPORT PORTALLARI
  // ═══════════════════════════════════════════════════

  void _drawPortals(Canvas canvas, double ox, double oy, double cs) {
    for (final portal in level.portals) {
      final rect =
          Rect.fromLTWH(ox + portal.col * cs, oy + portal.row * cs, cs, cs);
      final color =
          portal.isA ? const Color(0xFFA855F7) : const Color(0xFF22D3EE);

      canvas.drawCircle(
          rect.center,
          cs * 0.38,
          Paint()
            ..color = color.withOpacity(0.32)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(8)),
          Paint()
            ..color = color.withOpacity(0.82)
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke);

      canvas.drawCircle(
          rect.center,
          cs * 0.22,
          Paint()
            ..color = color.withOpacity(0.72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawCircle(
          rect.center, cs * 0.09, Paint()..color = color.withOpacity(0.95));

      _drawTextAt(
          canvas, rect.center, portal.isA ? 'A' : 'B', color, cs * 0.17);
    }
  }

  // ═══════════════════════════════════════════════════
  // ARAÇLAR — Top-down gerçekçi çizim
  // ═══════════════════════════════════════════════════

  void _drawCars(Canvas canvas, double ox, double oy, double cs) {
    for (final car in cars) {
      final isAnim = car.id == animCarId;
      final isCrash = car.id == crashCarId;

      // Çıkış animasyonu sırasında exited araçlar da çizilsin
      if (car.isExited && !isAnim) continue;

      // Araç bounding box merkezi — List allocation olmadan direkt hesap.
      // occupiedCells: (row - dr*i, col - dc*i) for i in 0..size-1
      // cx = ox + (col + endCol + 1) / 2 * cs  (min+max = col + endCol)
      final (dr, dc) = car.direction.delta;
      final endRow = car.row - dr * (car.size - 1);
      final endCol = car.col - dc * (car.size - 1);
      double cx = ox + ((car.col + endCol + 1) / 2.0) * cs;
      double cy = oy + ((car.row + endRow + 1) / 2.0) * cs;

      if (isAnim) {
        cx += animOffset.dx;
        cy += animOffset.dy;
      } else if (isCrash) {
        cx += crashOffset.dx;
        cy += crashOffset.dy;
      }

      if (isAnim && animOffset.distance > 0.5) {
        _drawMotionTrail(canvas, car, cx, cy, cs);
      }

      _drawSingleCar(
        canvas,
        car,
        cx,
        cy,
        cs,
        isHint: car.id == hintCarId,
        isCrash: isCrash,
        crashIntensity: isCrash ? crashIntensity : 0.0,
      );

      if (isCrash && crashIntensity > 0.05) {
        _drawImpactSparks(canvas, car, cx, cy, cs, crashIntensity);
      }
    }
  }

  void _drawMotionTrail(
      Canvas canvas, CarModel car, double cx, double cy, double cs) {
    final (dr, dc) = car.direction.delta;
    // MaskFilter.blur kaldırıldı — GPU blur pass tasarrufu.
    // Opacity azaltılarak derinlik hissi korundu.
    final paint = Paint()
      ..color = const Color(0x6B5EDCFF)
      ..strokeWidth = math.max(1.5, cs * 0.035)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final gap = cs * (0.22 + i * 0.14);
      final half = cs * (0.15 - i * 0.025);
      final center = Offset(cx - dc * gap, cy - dr * gap);
      final lateral = Offset(-dr * half, dc * half);
      canvas.drawLine(center - lateral, center + lateral, paint);
    }
  }

  void _drawImpactSparks(Canvas canvas, CarModel car, double cx, double cy,
      double cs, double intensity) {
    final (dr, dc) = car.direction.delta;
    final front = Offset(cx + dc * cs * 0.42, cy + dr * cs * 0.42);
    final forward = Offset(dc.toDouble(), dr.toDouble());
    final side = Offset(-dr.toDouble(), dc.toDouble());
    final paint = Paint()
      ..color = AppTheme.accentGold.withOpacity(0.75 * intensity)
      ..strokeWidth = math.max(1.2, cs * 0.025)
      ..strokeCap = StrokeCap.round;

    for (final t in [-0.34, 0.0, 0.34]) {
      final start = front + side * (cs * t * 0.35);
      final end = start + forward * (cs * 0.16 * intensity) + side * (cs * t);
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawSingleCar(
    Canvas canvas,
    CarModel car,
    double cx,
    double cy,
    double cs, {
    required bool isHint,
    required bool isCrash,
    required double crashIntensity,
  }) {
    final carImage = _imageFor(car);
    final angle = carImage != null
        ? switch (car.direction) {
            Direction.up => 0.0,
            Direction.right => math.pi / 2,
            Direction.down => math.pi,
            Direction.left => -math.pi / 2,
          }
        : switch (car.direction) {
            Direction.right => 0.0,
            Direction.down => math.pi / 2,
            Direction.left => math.pi,
            Direction.up => -math.pi / 2,
          };

    final hL = _bodyLengthFactor(car) * car.size * cs / 2;
    final hW = _bodyWidthFactor(car) * cs / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    if (carImage != null) {
      _paintCarImage(
        canvas,
        car,
        carImage,
        cs,
        isHint,
        crashIntensity,
        crashType == CrashType.vipBlocked
            ? AppTheme.vipColor
            : AppTheme.accentRed,
      );
    } else {
      _paintCar(canvas, car, hL, hW, cs, isHint, isCrash, crashIntensity);
    }

    canvas.restore();
  }

  void _paintCar(
    Canvas canvas,
    CarModel car,
    double hL,
    double hW,
    double cs,
    bool isHint,
    bool isCrash,
    double crashIntensity,
  ) {
    // ── Crash renk hesapla ─────────────────────────────────
    final flashColor = crashType == CrashType.vipBlocked
        ? AppTheme.vipColor
        : AppTheme.accentRed;
    final baseColor = car.color;
    final bodyColor = crashIntensity > 0.01
        ? Color.lerp(baseColor, flashColor, crashIntensity * 0.65)!
        : baseColor;

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(-hL, -hW, hL, hW),
      Radius.circular(hW * 0.36),
    );

    final paintRect = bodyRRect.outerRect;
    // ── Ana gövde ─────────────────────────────────────────
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(bodyColor, Colors.white, 0.18)!,
            bodyColor,
            Color.lerp(bodyColor, Colors.black, 0.20)!,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(paintRect),
    );
    final sideAccent = Paint()
      ..color = Color.lerp(bodyColor, Colors.black, 0.30)!.withOpacity(0.38);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-hL * 0.82, -hW * 0.93, hL * 0.78, -hW * 0.70),
        Radius.circular(hW * 0.14),
      ),
      sideAccent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-hL * 0.82, hW * 0.70, hL * 0.78, hW * 0.93),
        Radius.circular(hW * 0.14),
      ),
      sideAccent,
    );
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, hW * 0.055),
    );

    // ── Çatı (kabinin koyu alanı) ─────────────────────────
    final cabRect = Rect.fromLTRB(
      car.size > 1 ? -hL * 0.12 : -hL * 0.28,
      -hW * 0.48,
      car.size > 1 ? hL * 0.34 : hL * 0.36,
      hW * 0.48,
    );
    if (cabRect.width > 4 && cabRect.height > 4) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(cabRect, Radius.circular(hW * 0.24)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xFFCEEFFF),
              Color(0xFF5F7884),
            ],
          ).createShader(cabRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            cabRect.deflate(1.2), Radius.circular(hW * 0.2)),
        Paint()
          ..color = _paper.withOpacity(0.50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // ── Ön cam ────────────────────────────────────────────
    final windshieldRect = Rect.fromLTRB(
      hL * 0.48,
      -hW * 0.42,
      hL * 0.78,
      hW * 0.42,
    );
    if (windshieldRect.width > 3 && windshieldRect.height > 3) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(windshieldRect, Radius.circular(hW * 0.12)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFB7F0FF).withOpacity(0.55),
              _paper.withOpacity(0.90),
            ],
          ).createShader(windshieldRect),
      );
      // Yansıma çizgisi
      canvas.drawLine(
        Offset(windshieldRect.left + 3, windshieldRect.top + 3),
        Offset(windshieldRect.left + 3, windshieldRect.bottom - 3),
        Paint()
          ..color = Colors.white.withOpacity(0.24)
          ..strokeWidth = 1.2,
      );
    }

    // ── Arka cam ──────────────────────────────────────────
    final rearRect = Rect.fromLTRB(
      -hL * 0.74,
      -hW * 0.36,
      -hL * 0.48,
      hW * 0.36,
    );
    if (rearRect.width > 2 && rearRect.height > 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rearRect, Radius.circular(hW * 0.08)),
        Paint()..color = _paper.withOpacity(0.70),
      );
    }

    // ── Tekerlekler ───────────────────────────────────────
    // TOP-DOWN görünümde tekerlekler gövdenin kenarında küçük dikdörtgenler
    final wheelLong = math.max(hL * (car.size == 1 ? 0.20 : 0.14), 3.8);
    final wheelShort = math.max(hW * 0.20, 2.8);
    final wheelFX = hL * 0.62;
    final wheelRX = -(hL * (car.size > 1 ? 0.78 : 0.62));
    final wheelY = hW - wheelShort / 2 + 1;

    final wheelPaint = Paint()..color = _ink.withOpacity(0.92);
    final rimPaint = Paint()..color = _paper.withOpacity(0.72);
    final wheelRad = Radius.circular(wheelShort * 0.35);

    for (final (wx, wy) in [
      (wheelFX, -wheelY),
      (wheelFX, wheelY),
      (wheelRX, -wheelY),
      (wheelRX, wheelY),
    ]) {
      final wRect = Rect.fromCenter(
          center: Offset(wx, wy), width: wheelLong, height: wheelShort);
      canvas.drawRRect(RRect.fromRectAndRadius(wRect, wheelRad), wheelPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            wRect.deflate(wRect.shortestSide * 0.22), wheelRad),
        rimPaint,
      );
    }

    // ── Farlar (ön) ───────────────────────────────────────
    final lightR = math.max(hW * 0.08, 2.0);
    final lightFX = hL * 0.93;
    final lightY = hW * 0.46;

    final headPaint = Paint()..color = _paper;
    canvas.drawCircle(Offset(lightFX, -lightY), lightR, headPaint);
    canvas.drawCircle(Offset(lightFX, lightY), lightR, headPaint);
    // Far halo
    canvas.drawCircle(
        Offset(lightFX, -lightY),
        lightR * 1.9,
        Paint()
          ..color = _paper.withOpacity(0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(
        Offset(lightFX, lightY),
        lightR * 1.9,
        Paint()
          ..color = _paper.withOpacity(0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // ── Stop lambalar (arka) ──────────────────────────────
    final stopPaint = Paint()..color = _paper.withOpacity(0.85);
    canvas.drawCircle(Offset(-lightFX, -lightY), lightR * 0.88, stopPaint);
    canvas.drawCircle(Offset(-lightFX, lightY), lightR * 0.88, stopPaint);

    // ── Araç tipi özellikleri ─────────────────────────────
    _drawTypeDetails(canvas, car, hL, hW);

    // ── Gövde üst parlaması (car paint sheen) ─────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-hL * 0.5, -hW * 0.9, hL * 0.45, -hW * 0.1),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withOpacity(0.07),
    );

    // ── Hint çerçevesi ────────────────────────────────────
    if (isHint) {
      canvas.drawRRect(bodyRRect.inflate(2.5), _hintStrokePaint);
      canvas.drawRRect(
        bodyRRect.inflate(5),
        Paint()
          ..color = const Color(0x61FFC400)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // ── Crash impact flash (gövde dışında parlama) ─────────
    if (crashIntensity > 0.05) {
      canvas.drawRRect(
        bodyRRect.inflate(crashIntensity * 8),
        Paint()
          ..color = flashColor.withOpacity(crashIntensity * 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, crashIntensity * 10),
      );
    }
  }

  double _bodyLengthFactor(CarModel car) => switch (car.type) {
        CarType.truck || CarType.tir => 0.94,
        CarType.suv || CarType.emergency => 0.88,
        _ => 0.82,
      };

  double _bodyWidthFactor(CarModel car) => switch (car.type) {
        CarType.truck || CarType.tir => 0.66,
        CarType.suv || CarType.emergency => 0.64,
        _ => 0.60,
      };

  ui.Image? _imageFor(CarModel car) {
    final key = _imageKeyFor(car);
    if (key == null) return null;
    return carImages[key];
  }

  String? _imageKeyFor(CarModel car) => switch (car.type) {
        CarType.vip => 'vip',
        CarType.emergency => 'ambulans',
        CarType.truck => 'truck',
        CarType.tir => 'tir',
        CarType.spinner => null,
        CarType.suv => _suvPattern[_stableCarIndex(car) % _suvPattern.length],
        CarType.standard => _standardCarPattern[
            _stableCarIndex(car) % _standardCarPattern.length],
      };

  int _stableCarIndex(CarModel car) {
    final match = _digitRegex.firstMatch(car.id);
    if (match != null) return int.parse(match.group(0)!) - 1;
    return car.id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  }

  void _paintCarImage(
    Canvas canvas,
    CarModel car,
    ui.Image image,
    double cs,
    bool isHint,
    double crashIntensity,
    Color flashColor,
  ) {
    final imageKey = _imageKeyFor(car);
    final src = _sourceRectFor(imageKey, image);
    final destHalfW = _imageWidthFactor(car) * cs / 2;
    final destHalfH = _imageLengthFactor(car) * car.size * cs / 2;
    final rect = Rect.fromLTRB(-destHalfW, -destHalfH, destHalfW, destHalfH);
    final outline = RRect.fromRectAndRadius(
      rect,
      Radius.circular(destHalfW * 0.22),
    );

    canvas.drawImageRect(image, src, rect, _carImagePaint);

    if (crashIntensity > 0.01) {
      canvas.drawRRect(
        outline,
        Paint()
          ..color = flashColor.withOpacity(crashIntensity * 0.28)
          ..blendMode = BlendMode.srcATop,
      );
    }

    if (isHint) {
      canvas.drawRRect(outline.inflate(2.5), _hintStrokePaint);
      canvas.drawRRect(
        outline.inflate(5),
        Paint()
          ..color = const Color(0x61FFC400)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    if (crashIntensity > 0.05) {
      canvas.drawRRect(
        outline.inflate(crashIntensity * 8),
        Paint()
          ..color = flashColor.withOpacity(crashIntensity * 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, crashIntensity * 10),
      );
    }
  }

  double _imageLengthFactor(CarModel car) => switch (car.type) {
        CarType.truck || CarType.tir => 0.92,
        CarType.suv || CarType.emergency => 0.88,
        _ => 0.86,
      };

  double _imageWidthFactor(CarModel car) => switch (car.type) {
        CarType.truck || CarType.tir => 0.60,
        CarType.suv || CarType.emergency => 0.58,
        _ => 0.56,
      };

  Rect _sourceRectFor(String? imageKey, ui.Image image) {
    final visible = imageKey == null ? null : _carImageVisibleBounds[imageKey];
    if (visible == null) {
      return Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
    }

    const pad = 0.03;
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final left = ((visible.left - pad) * width).clamp(0.0, width).toDouble();
    final top = ((visible.top - pad) * height).clamp(0.0, height).toDouble();
    final right =
        ((visible.right + pad) * width).clamp(left + 1, width).toDouble();
    final bottom =
        ((visible.bottom + pad) * height).clamp(top + 1, height).toDouble();
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _drawTypeDetails(Canvas canvas, CarModel car, double hL, double hW) {
    switch (car.type) {
      case CarType.vip:
        final stripe =
            Rect.fromLTRB(-hL * 0.62, -hW * 0.11, hL * 0.62, hW * 0.11);
        canvas.drawRRect(
          RRect.fromRectAndRadius(stripe, Radius.circular(hW * 0.08)),
          Paint()..color = _paper.withOpacity(0.88),
        );
        _drawStar(canvas, Offset(-hL * 0.2, 0), hW * 0.18, _ink);

      case CarType.emergency:
        final barRect =
            Rect.fromLTRB(-hL * 0.24, -hW * 0.82, hL * 0.24, -hW * 0.58);
        if (barRect.width > 4) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(barRect, Radius.circular(hW * 0.07)),
            Paint()..color = _paper.withOpacity(0.88),
          );
          final midY = (barRect.top + barRect.bottom) / 2;
          canvas.drawCircle(
              Offset(-hL * 0.1, midY), hW * 0.08, Paint()..color = _ink);
          canvas.drawCircle(
              Offset(hL * 0.1, midY), hW * 0.08, Paint()..color = _ink);
        }

      case CarType.truck:
        if (hL > 20) {
          final cargo =
              Rect.fromLTRB(-hL * 0.86, -hW * 0.74, -hL * 0.18, hW * 0.74);
          canvas.drawRRect(
            RRect.fromRectAndRadius(cargo, Radius.circular(hW * 0.16)),
            Paint()..color = _paper.withOpacity(0.18),
          );
          canvas.drawLine(
            Offset(-hL * 0.25, -hW),
            Offset(-hL * 0.25, hW),
            Paint()
              ..color = _paper.withOpacity(0.55)
              ..strokeWidth = 1.4,
          );
          for (final x in [-0.68, -0.50]) {
            canvas.drawLine(
              Offset(hL * x, -hW * 0.50),
              Offset(hL * x, hW * 0.50),
              Paint()
                ..color = _paper.withOpacity(0.32)
                ..strokeWidth = 1.0,
            );
          }
        }

      case CarType.spinner:
        // Döner ok halkası
        canvas.drawCircle(
          Offset.zero,
          hW * 0.35,
          Paint()
            ..color = _paper.withOpacity(0.72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

      default:
        break;
    }
  }

  // ── Yardımcı çizim fonksiyonları ──────────────────────

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerA = -math.pi / 2 + (i * 2 * math.pi / 5);
      final innerA = outerA + math.pi / 5;
      final outer = Offset(center.dx + size * math.cos(outerA),
          center.dy + size * math.sin(outerA));
      final inner = Offset(center.dx + size * 0.42 * math.cos(innerA),
          center.dy + size * 0.42 * math.sin(innerA));
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _arrow(
      Canvas canvas, Offset center, Direction dir, double size, Paint p) {
    final (dr, dc) = dir.delta;
    final dx = dc.toDouble();
    final dy = dr.toDouble();
    final tip = center + Offset(dx * size, dy * size);
    final tail = center - Offset(dx * size * 0.55, dy * size * 0.55);
    canvas.drawLine(tail, tip, p);
    final wx = -dy * size * 0.42;
    final wy = dx * size * 0.42;
    canvas.drawLine(
        tip, tip - Offset(dx * size * 0.45 + wx, dy * size * 0.45 + wy), p);
    canvas.drawLine(
        tip, tip - Offset(dx * size * 0.45 - wx, dy * size * 0.45 - wy), p);
  }

  void _drawTextAt(
      Canvas canvas, Offset center, String text, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(GridPainter old) {
    if (old.paintBoard != paintBoard || old.paintCars != paintCars) return true;
    if (old.level != level) return true;

    if (paintBoard && old.showGridCoordinates != showGridCoordinates) {
      return true;
    }

    return paintCars &&
        (old.cars != cars ||
            old.hintCarId != hintCarId ||
            old.animCarId != animCarId ||
            old.animOffset != animOffset ||
            old.crashCarId != crashCarId ||
            old.crashOffset != crashOffset ||
            old.crashIntensity != crashIntensity ||
            old.crashType != crashType ||
            old.carImages != carImages);
  }
}
