import 'dart:math';
import 'package:flutter/material.dart';

/// Zappio Games Ultra Premium Splash Screen
///
/// Kullanım:
///
/// ZappioSplashScreen(
///   onComplete: () {
///     Navigator.pushReplacement(
///       context,
///       MaterialPageRoute(builder: (_) => const HomeScreen()),
///     );
///   },
/// )
///
/// Özellikler:
/// - Harici görsel gerektirmez.
/// - Tamamen Flutter CustomPainter ile çizilir.
/// - Ultra premium oyun stüdyosu intro hissi verir.
/// - onComplete ve displayDuration mevcut sistemle uyumludur.
/// - Alttaki küçük POWERING UP yazısı kaldırılmıştır.
class ZappioSplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration displayDuration;

  const ZappioSplashScreen({
    super.key,
    this.onComplete,
    this.displayDuration = const Duration(milliseconds: 3400),
  });

  @override
  State<ZappioSplashScreen> createState() => _ZappioSplashScreenState();
}

class _ZappioSplashScreenState extends State<ZappioSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _brandController;
  late final AnimationController _orbitController;
  late final AnimationController _particleController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _exitController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRise;
  late final Animation<double> _brandOpacity;
  late final Animation<double> _brandSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _subtitleSpacing;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );

    _brandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7600),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.62, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.58, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.05, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _logoRise = Tween<double>(begin: 28.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _brandOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _brandController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _brandSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _brandController,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _brandController,
        curve: const Interval(0.34, 0.95, curve: Curves.easeOut),
      ),
    );

    _subtitleSpacing = Tween<double>(begin: 8.0, end: 3.6).animate(
      CurvedAnimation(
        parent: _brandController,
        curve: const Interval(0.34, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;
    _introController.forward();

    await Future.delayed(const Duration(milliseconds: 620));

    if (!mounted) return;
    _brandController.forward();

    await Future.delayed(widget.displayDuration);

    if (!mounted) return;
    await _exitController.forward();

    if (!mounted) return;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _introController.dispose();
    _brandController.dispose();
    _orbitController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03030A),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _introController,
          _brandController,
          _orbitController,
          _particleController,
          _pulseController,
          _shimmerController,
          _exitController,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _UltraBackgroundPainter(
                        particleProgress: _particleController.value,
                        pulse: _pulseController.value,
                        intro: _introController.value,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _UltraNebulaPainter(
                        pulse: _pulseController.value,
                        shimmer: _shimmerController.value,
                        intro: _introController.value,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _UltraVignettePainter(),
                    ),
                  ),
                  Center(
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.translate(
                              offset: Offset(0, _logoRise.value),
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: _UltraLogoStage(
                                  orbit: _orbitController.value,
                                  pulse: _pulseController.value,
                                  shimmer: _shimmerController.value,
                                  intro: _introController.value,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Opacity(
                            opacity: _brandOpacity.value,
                            child: Transform.translate(
                              offset: Offset(0, _brandSlide.value),
                              child: _UltraBrandName(
                                shimmer: _shimmerController.value,
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Opacity(
                            opacity: _subtitleOpacity.value,
                            child: Text(
                              'G A M E S',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: _subtitleSpacing.value,
                                color:
                                    const Color(0xFFE9D5FF).withOpacity(0.78),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Opacity(
                            opacity: _subtitleOpacity.value,
                            child: _UltraDivider(
                              shimmer: _shimmerController.value,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Opacity(
                            opacity: _subtitleOpacity.value,
                            child: Text(
                              'A ZAPPIO GAMES EXPERIENCE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.7,
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UltraLogoStage extends StatelessWidget {
  final double orbit;
  final double pulse;
  final double shimmer;
  final double intro;

  const _UltraLogoStage({
    required this.orbit,
    required this.pulse,
    required this.shimmer,
    required this.intro,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 246,
      height: 246,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(246, 246),
            painter: _LogoEnergyFieldPainter(
              pulse: pulse,
              intro: intro,
            ),
          ),
          CustomPaint(
            size: const Size(232, 232),
            painter: _LogoOrbitPainter(
              orbit: orbit,
              intro: intro,
            ),
          ),
          CustomPaint(
            size: const Size(198, 198),
            painter: _LogoShardPainter(
              orbit: orbit,
              pulse: pulse,
              intro: intro,
            ),
          ),
          Transform.scale(
            scale: 0.98 + pulse * 0.035,
            child: CustomPaint(
              size: const Size(146, 146),
              painter: _ZappioUltraEmblemPainter(
                pulse: pulse,
                shimmer: shimmer,
                intro: intro,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(222, 222),
            painter: _LogoImpactLinesPainter(
              orbit: orbit,
              intro: intro,
            ),
          ),
        ],
      ),
    );
  }
}

class _UltraBrandName extends StatelessWidget {
  final double shimmer;

  const _UltraBrandName({
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'ZAPPIO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 51,
            height: 0.94,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: const Color(0xFFA78BFA).withOpacity(0.22),
            shadows: [
              Shadow(
                color: const Color(0xFFA78BFA).withOpacity(0.35),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) {
            final double x = shimmer;

            return LinearGradient(
              begin: Alignment(-1.2 + x * 2.4, -1),
              end: Alignment(0.2 + x * 2.4, 1),
              colors: const [
                Color(0xFFFFFFFF),
                Color(0xFFE9D5FF),
                Color(0xFFFFD166),
                Color(0xFFFFFFFF),
              ],
              stops: const [0.0, 0.42, 0.62, 1.0],
            ).createShader(bounds);
          },
          child: const Text(
            'ZAPPIO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 51,
              height: 0.94,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.6,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _UltraDivider extends StatelessWidget {
  final double shimmer;

  const _UltraDivider({
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 14,
      child: CustomPaint(
        painter: _UltraDividerPainter(
          shimmer: shimmer,
        ),
      ),
    );
  }
}

class _UltraBackgroundPainter extends CustomPainter {
  final double particleProgress;
  final double pulse;
  final double intro;

  const _UltraBackgroundPainter({
    required this.particleProgress,
    required this.pulse,
    required this.intro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF03030A),
          Color(0xFF09051E),
          Color(0xFF130A32),
          Color(0xFF070712),
        ],
        stops: [0.0, 0.34, 0.68, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, base);

    _drawMainGlow(canvas, size);
    _drawPerspectiveFloor(canvas, size);
    _drawParticles(canvas, size);
    _drawMicroStars(canvas, size);
  }

  void _drawMainGlow(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.42);
    final double radius = size.width * (0.55 + pulse * 0.05);

    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C3AED).withOpacity(0.30 * intro),
          const Color(0xFF312E81).withOpacity(0.15 * intro),
          const Color(0xFF0F172A).withOpacity(0.04 * intro),
          Colors.transparent,
        ],
        stops: const [0.0, 0.38, 0.68, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, glow);

    final Offset goldCenter = Offset(size.width * 0.68, size.height * 0.34);
    final double goldRadius = size.width * 0.35;

    final Paint gold = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD166).withOpacity(0.105 * intro),
          const Color(0xFFFF9F1C).withOpacity(0.035 * intro),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: goldCenter, radius: goldRadius),
      );

    canvas.drawCircle(goldCenter, goldRadius, gold);
  }

  void _drawPerspectiveFloor(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.66;
    final Offset vanish = Offset(size.width / 2, horizonY);

    final Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(0.026 * intro)
      ..strokeWidth = 0.7;

    for (int i = -9; i <= 9; i++) {
      final double x = size.width / 2 + i * size.width * 0.105;

      canvas.drawLine(
        Offset(x, size.height),
        vanish,
        linePaint,
      );
    }

    for (int i = 0; i < 10; i++) {
      final double t = i / 9;
      final double y = horizonY + pow(t, 1.9) * (size.height - horizonY);

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    final Random random = Random(934);
    final double time = particleProgress;

    for (int i = 0; i < 72; i++) {
      final double baseX = random.nextDouble() * size.width;
      final double baseY = random.nextDouble() * size.height;
      final double speed = 10 + random.nextDouble() * 44;
      final double drift =
          sin(time * pi * 2 + i * 0.7) * (4 + random.nextDouble() * 12);

      double y = baseY - time * speed;

      if (y < -18) {
        y += size.height + 36;
      }

      final double blink = 0.35 + sin(time * pi * 2 + i).abs() * 0.65;
      final bool gold = i % 6 == 0;
      final Color color =
          gold ? const Color(0xFFFFD166) : const Color(0xFFC4B5FD);

      final Paint paint = Paint()
        ..color = color.withOpacity(
          (0.08 + random.nextDouble() * 0.22) * blink * intro,
        );

      canvas.drawCircle(
        Offset(baseX + drift, y),
        0.7 + random.nextDouble() * 1.8,
        paint,
      );
    }
  }

  void _drawMicroStars(Canvas canvas, Size size) {
    final Random random = Random(42);

    for (int i = 0; i < 38; i++) {
      final Offset p = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );

      final Paint paint = Paint()
        ..color = Colors.white.withOpacity(
          (0.035 + random.nextDouble() * 0.055) * intro,
        );

      canvas.drawCircle(p, 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UltraBackgroundPainter oldDelegate) {
    return oldDelegate.particleProgress != particleProgress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.intro != intro;
  }
}

class _UltraNebulaPainter extends CustomPainter {
  final double pulse;
  final double shimmer;
  final double intro;

  const _UltraNebulaPainter({
    required this.pulse,
    required this.shimmer,
    required this.intro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random(711);

    for (int i = 0; i < 8; i++) {
      final double x = size.width * (0.15 + random.nextDouble() * 0.7);
      final double y = size.height * (0.18 + random.nextDouble() * 0.55);
      final double radius = size.width * (0.13 + random.nextDouble() * 0.16);
      final double shift = sin(shimmer * pi * 2 + i) * 8;

      final Color color =
          i.isEven ? const Color(0xFFA78BFA) : const Color(0xFFFFD166);

      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity((0.018 + pulse * 0.012) * intro),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(x + shift, y - shift),
            radius: radius,
          ),
        );

      canvas.drawCircle(
        Offset(x + shift, y - shift),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UltraNebulaPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.intro != intro;
  }
}

class _UltraVignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.08),
        radius: 1.08,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.18),
          Colors.black.withOpacity(0.66),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, vignette);

    final Paint topBottom = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.32),
          Colors.transparent,
          Colors.black.withOpacity(0.36),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, topBottom);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoEnergyFieldPainter extends CustomPainter {
  final double pulse;
  final double intro;

  const _LogoEnergyFieldPainter({
    required this.pulse,
    required this.intro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint aura = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD166).withOpacity(0.14 * intro),
          const Color(0xFFA78BFA).withOpacity(0.20 * intro),
          const Color(0xFF7C3AED).withOpacity(0.08 * intro),
          Colors.transparent,
        ],
        stops: const [0.0, 0.27, 0.58, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: size.width * (0.45 + pulse * 0.045),
        ),
      );

    canvas.drawCircle(
      center,
      size.width * (0.45 + pulse * 0.045),
      aura,
    );

    final Paint halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.08 * intro);

    canvas.drawCircle(center, size.width * 0.41, halo);

    final Paint innerHalo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.045 * intro);

    canvas.drawCircle(center, size.width * 0.34, innerHalo);
  }

  @override
  bool shouldRepaint(covariant _LogoEnergyFieldPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.intro != intro;
  }
}

class _LogoOrbitPainter extends CustomPainter {
  final double orbit;
  final double intro;

  const _LogoOrbitPainter({
    required this.orbit,
    required this.intro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    _drawArc(
      canvas,
      center,
      size.width * 0.46,
      orbit * pi * 2,
      pi * 1.28,
      const Color(0xFFA78BFA).withOpacity(0.52 * intro),
      1.7,
    );

    _drawArc(
      canvas,
      center,
      size.width * 0.38,
      -orbit * pi * 2 + 0.8,
      pi * 0.82,
      const Color(0xFFFFD166).withOpacity(0.55 * intro),
      1.9,
    );

    _drawArc(
      canvas,
      center,
      size.width * 0.52,
      -orbit * pi * 1.35 + 2.4,
      pi * 0.42,
      Colors.white.withOpacity(0.30 * intro),
      1.1,
    );

    for (int i = 0; i < 3; i++) {
      final double angle = orbit * pi * 2 + i * pi * 2 / 3;
      final double radius = i == 0 ? size.width * 0.46 : size.width * 0.38;

      final Offset point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      final Color color =
          i == 0 ? const Color(0xFFFFD166) : const Color(0xFFA78BFA);

      final Paint dot = Paint()
        ..color = color.withOpacity(0.86 * intro)
        ..style = PaintingStyle.fill;

      final Paint glow = Paint()
        ..color = color.withOpacity(0.38 * intro)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(point, 7, glow);
      canvas.drawCircle(point, 2.8, dot);
    }
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    double radius,
    double start,
    double sweep,
    Color color,
    double width,
  ) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoOrbitPainter oldDelegate) {
    return oldDelegate.orbit != orbit || oldDelegate.intro != intro;
  }
}

class _LogoShardPainter extends CustomPainter {
  final double orbit;
  final double pulse;
  final double intro;

  const _LogoShardPainter({
    required this.orbit,
    required this.pulse,
    required this.intro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 9; i++) {
      final double angle =
          orbit * pi * 2 * (i.isEven ? 1 : -1) + i * pi * 2 / 9;

      final double distance = size.width * (0.43 + sin(pulse * pi + i) * 0.018);

      final Offset p = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );

      final double shardSize = 4.0 + (i % 3) * 1.5;

      final Paint paint = Paint()
        ..color =
            (i % 2 == 0 ? const Color(0xFFFFD166) : const Color(0xFFA78BFA))
                .withOpacity(0.32 * intro)
        ..style = PaintingStyle.fill;

      final Path shard = Path()
        ..moveTo(p.dx, p.dy - shardSize)
        ..lineTo(p.dx + shardSize * 0.55, p.dy)
        ..lineTo(p.dx, p.dy + shardSize)
        ..lineTo(p.dx - shardSize * 0.55, p.dy)
        ..close();

      canvas.drawPath(shard, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoShardPainter oldDelegate) {
    return oldDelegate.orbit != orbit ||
        oldDelegate.pulse != pulse ||
        oldDelegate.intro != intro;
  }
}

class _LogoImpactLinesPainter extends CustomPainter {
  final double orbit;
  final double intro;

  const _LogoImpactLinesPainter({
    required this.orbit,
    required this.intro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint paint = Paint()
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.12 * intro);

    for (int i = 0; i < 12; i++) {
      final double angle = orbit * pi * 2 + i * pi * 2 / 12;
      final double inner = size.width * 0.25;
      final double outer = size.width * (0.32 + (i % 2) * 0.05);

      final Offset a = Offset(
        center.dx + cos(angle) * inner,
        center.dy + sin(angle) * inner,
      );

      final Offset b = Offset(
        center.dx + cos(angle) * outer,
        center.dy + sin(angle) * outer,
      );

      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoImpactLinesPainter oldDelegate) {
    return oldDelegate.orbit != orbit || oldDelegate.intro != intro;
  }
}

class _ZappioUltraEmblemPainter extends CustomPainter {
  final double pulse;
  final double shimmer;
  final double intro;

  const _ZappioUltraEmblemPainter({
    required this.pulse,
    required this.shimmer,
    required this.intro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Path outerHex = _hexagonPath(size, 0.49);
    final Path innerHex = _hexagonPath(size, 0.37);
    final Path zPath = _zPath(size);

    final Paint hexGlow = Paint()
      ..color = const Color(0xFFA78BFA).withOpacity(0.34 * intro)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.fill;

    canvas.drawPath(outerHex, hexGlow);

    final Paint hexBody = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF36106B),
          Color(0xFF4C1D95),
          Color(0xFF17112F),
          Color(0xFF080814),
        ],
        stops: [0.0, 0.42, 0.78, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(outerHex, hexBody);

    final Paint hexHighlight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.55),
        colors: [
          Colors.white.withOpacity(0.24 * intro),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(outerHex, hexHighlight);

    final Paint border = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.52 * intro),
          const Color(0xFFA78BFA).withOpacity(0.78 * intro),
          const Color(0xFFFFD166).withOpacity(0.82 * intro),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.35;

    canvas.drawPath(outerHex, border);

    final Paint inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = Colors.white.withOpacity(0.10 * intro);

    canvas.drawPath(innerHex, inner);

    final Paint zGlow = Paint()
      ..color =
          const Color(0xFFFFD166).withOpacity((0.42 + pulse * 0.18) * intro)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..style = PaintingStyle.fill;

    canvas.drawPath(zPath, zGlow);

    final Paint zBody = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + shimmer * 1.2, -1),
        end: Alignment(0.2 + shimmer * 1.2, 1),
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFFFF3B0),
          Color(0xFFFFD166),
          Color(0xFFFF9F1C),
        ],
        stops: [0.0, 0.35, 0.68, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(zPath, zBody);

    final Paint zEdge = Paint()
      ..color = Colors.white.withOpacity(0.34 * intro)
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(zPath, zEdge);

    final Paint core = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95 * intro),
          const Color(0xFFFFD166).withOpacity(0.40 * intro),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: 13,
        ),
      );

    canvas.drawCircle(center, 13, core);
  }

  Path _hexagonPath(Size size, double scale) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * scale;
    final Path path = Path();

    for (int i = 0; i < 6; i++) {
      final double angle = -pi / 2 + i * pi / 3;

      final Offset p = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    path.close();
    return path;
  }

  Path _zPath(Size size) {
    final double w = size.width;
    final double h = size.height;

    return Path()
      ..moveTo(w * 0.28, h * 0.285)
      ..lineTo(w * 0.765, h * 0.285)
      ..lineTo(w * 0.765, h * 0.405)
      ..lineTo(w * 0.505, h * 0.595)
      ..lineTo(w * 0.755, h * 0.595)
      ..lineTo(w * 0.755, h * 0.725)
      ..lineTo(w * 0.245, h * 0.725)
      ..lineTo(w * 0.245, h * 0.61)
      ..lineTo(w * 0.515, h * 0.415)
      ..lineTo(w * 0.28, h * 0.415)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _ZappioUltraEmblemPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.intro != intro;
  }
}

class _UltraDividerPainter extends CustomPainter {
  final double shimmer;

  const _UltraDividerPainter({
    required this.shimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint line = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFFA78BFA).withOpacity(0.85),
          const Color(0xFFFFD166).withOpacity(0.85),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      line,
    );

    final double shimmerX = size.width * shimmer;

    final Paint sweep = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.55),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(shimmerX, center.dy),
          radius: 18,
        ),
      );

    canvas.drawCircle(
      Offset(shimmerX, center.dy),
      18,
      sweep,
    );

    final Paint dotGlow = Paint()
      ..color = const Color(0xFFFFD166).withOpacity(0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final Paint dot = Paint()..color = const Color(0xFFFFD166);

    canvas.drawCircle(center, 7, dotGlow);
    canvas.drawCircle(center, 3.2, dot);
  }

  @override
  bool shouldRepaint(covariant _UltraDividerPainter oldDelegate) {
    return oldDelegate.shimmer != shimmer;
  }
}
