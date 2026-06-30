import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/game_bloc.dart';
import '../models/models.dart';

/// Level tamamlandiginda gosterilen sonuc ekrani.
class WinOverlay extends StatefulWidget {
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback onMenu;

  const WinOverlay({
    super.key,
    required this.onNextLevel,
    required this.onReplay,
    required this.onMenu,
  });

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _backdropOpacity;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardOffset;
  late final Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _backdropOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );
    _cardOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.42, curve: Curves.easeOut),
    );
    _cardOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.58, curve: Curves.easeOutCubic),
    ));
    _cardScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.62, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (previous, current) => previous.result != current.result,
      builder: (context, state) {
        final result = state.result;
        if (result == null) return const SizedBox.shrink();

        return Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  Opacity(
                    opacity: _backdropOpacity.value,
                    child: const _VictoryBackdrop(),
                  ),
                  Opacity(
                    opacity: _backdropOpacity.value,
                    child: CustomPaint(
                      painter: _CelebrationPainter(_controller.value),
                      size: Size.infinite,
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: FadeTransition(
                          opacity: _cardOpacity,
                          child: SlideTransition(
                            position: _cardOffset,
                            child: ScaleTransition(
                              scale: _cardScale,
                              child: _ResultCard(
                                result: result,
                                animation: _controller,
                                onMenu: widget.onMenu,
                                onReplay: widget.onReplay,
                                onNextLevel: widget.onNextLevel,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _VictoryBackdrop extends StatelessWidget {
  const _VictoryBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6090B24),
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.05,
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.46),
            const Color(0xF20F1B4D),
            const Color(0xFA070817),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final GameResult result;
  final Animation<double> animation;
  final VoidCallback onMenu;
  final VoidCallback onReplay;
  final VoidCallback onNextLevel;

  const _ResultCard({
    required this.result,
    required this.animation,
    required this.onMenu,
    required this.onReplay,
    required this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 680;
    final title = result.isPerfect
        ? 'M\u00fckemmel S\u00fcr\u00fc\u015f!'
        : 'Seviye Tamamland\u0131!';
    final subtitle = switch (result.stars) {
      3 => 'Kusursuz performans. T\u00fcm y\u0131ld\u0131zlar senin!',
      2 => 'Harika gidiyorsun. Bir y\u0131ld\u0131z daha kazanabilirsin.',
      _ =>
        'Park alan\u0131 temizlendi. S\u0131radaki seviyeye haz\u0131rs\u0131n.',
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 38),
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 26,
              compact ? 48 : 56,
              compact ? 20 : 26,
              compact ? 20 : 26,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF252060),
                  Color(0xFF17275B),
                  Color(0xFF111A3B),
                ],
                stops: [0, 0.52, 1],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF67E8F9).withOpacity(0.5),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF080B28).withOpacity(0.72),
                  blurRadius: 42,
                  offset: const Offset(0, 22),
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.34),
                  blurRadius: 58,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SEV\u0130YE TAMAMLANDI',
                  style: TextStyle(
                    color: Color(0xFFFFE45E),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 25 : 29,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC8D5FF),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 16 : 22),
                _StarRow(stars: result.stars, animation: animation),
                SizedBox(height: compact ? 18 : 24),
                _StatsRow(result: result),
                SizedBox(height: compact ? 18 : 24),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF67E8F9).withOpacity(0.62),
                        const Color(0xFFC084FC).withOpacity(0.62),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SizedBox(height: compact ? 18 : 22),
                _PrimaryButton(onTap: onNextLevel),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryButton(
                        icon: Icons.home_rounded,
                        label: 'Ana Men\u00fc',
                        onTap: onMenu,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SecondaryButton(
                        icon: Icons.replay_rounded,
                        label: 'Tekrar Oyna',
                        onTap: onReplay,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _TrophyBadge(animation: animation),
        ],
      ),
    );
  }
}

class _TrophyBadge extends StatelessWidget {
  final Animation<double> animation;

  const _TrophyBadge({required this.animation});

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.65, curve: Curves.elasticOut),
    );

    return ScaleTransition(
      scale: scale,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFF7A),
              Color(0xFFFFB020),
              Color(0xFFFF6B35),
            ],
          ),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB020).withOpacity(0.68),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFF492000),
          size: 40,
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int stars;
  final Animation<double> animation;

  const _StarRow({required this.stars, required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final start = 0.3 + index * 0.12;
          final starAnimation = CurvedAnimation(
            parent: animation,
            curve: Interval(start, math.min(start + 0.35, 1),
                curve: Curves.elasticOut),
          );
          final filled = index < stars;
          final size = index == 1 ? 58.0 : 48.0;

          return ScaleTransition(
            scale: starAnimation,
            child: Container(
              width: size + 8,
              alignment: Alignment.center,
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                size: size,
                color: filled
                    ? const Color(0xFFFFE45E)
                    : const Color(0xFF7784C7).withOpacity(0.55),
                shadows: filled
                    ? [
                        Shadow(
                          color: const Color(0xFFFFB020).withOpacity(0.9),
                          blurRadius: 22,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final GameResult result;

  const _StatsRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.military_tech_rounded,
            label: 'PUAN',
            value: '${result.score}',
            color: const Color(0xFFFFD23F),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.touch_app_rounded,
            label: 'HAMLE',
            value: '${result.moveCount}',
            color: const Color(0xFF4DEBFF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'COMBO',
            value: '${result.comboCount}',
            color: const Color(0xFFFF5DB1),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.22),
            color.withOpacity(0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.52)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color.withOpacity(0.88), size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.82),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimaryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD23F),
              Color(0xFFFF8A34),
              Color(0xFFFF4D8D),
            ],
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D8D).withOpacity(0.42),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sonraki Seviye',
                  style: TextStyle(
                    color: Color(0xFF251032),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF251032),
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF29316F).withOpacity(0.88),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF7DD3FC).withOpacity(0.42),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 1),
              Icon(icon, size: 19, color: const Color(0xFF9BE7FF)),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE7EEFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  final double progress;

  const _CelebrationPainter(this.progress);

  static const _colors = [
    Color(0xFFFFE45E),
    Color(0xFFFF6B35),
    Color(0xFF4DEBFF),
    Color(0xFFFF5DB1),
    Color(0xFF8B5CF6),
    Color(0xFF4ADE80),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final appear = Curves.easeOut.transform(progress.clamp(0, 1));
    final fade = (1 - ((progress - 0.72) / 0.28).clamp(0, 1)) * appear;
    final center = Offset(size.width / 2, size.height * 0.28);

    for (var i = 0; i < 28; i++) {
      final angle = i * 2.399;
      final distance = (70 + (i % 7) * 24) * appear;
      final fall = 60 * progress * progress;
      final point = center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance + fall);
      final paint = Paint()
        ..color = _colors[i % _colors.length].withOpacity(fade);
      final particleSize = 2.5 + (i % 3).toDouble();

      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + progress * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSize * 2.2,
            height: particleSize,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
