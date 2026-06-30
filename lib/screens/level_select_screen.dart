import 'package:flutter/material.dart';

import '../data/level_repository.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  Widget build(BuildContext context) {
    final levels = LevelRepository.instance.allLevels;
    final completed = levels
        .where((level) => ProgressService.instance.isLevelCompleted(level.id))
        .length;
    final earnedStars = levels.fold<int>(
      0,
      (sum, level) => sum + ProgressService.instance.getStars(level.id),
    );
    final totalStars = levels.length * 3;

    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      body: Stack(
        children: [
          const Positioned.fill(child: _LevelBackdrop()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _LevelHeader(
                    completed: completed,
                    totalLevels: levels.length,
                    earnedStars: earnedStars,
                    totalStars: totalStars,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.crossAxisExtent >= 390 ? 4 : 3;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 11,
                          childAspectRatio: columns == 4 ? 0.78 : 0.88,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final level = levels[index];
                            final stars =
                                ProgressService.instance.getStars(level.id);
                            final bestMoves =
                                ProgressService.instance.getBestMoves(level.id);
                            final isLocked = index > 0 &&
                                !ProgressService.instance.isLevelCompleted(
                                  levels[index - 1].id,
                                );

                            return _LevelCard(
                              key: Key('level_card_${level.id}'),
                              level: level,
                              stars: stars,
                              bestMoves: bestMoves,
                              isLocked: isLocked,
                              onTap: isLocked
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              GameScreen(levelId: level.id),
                                        ),
                                      );
                                      if (mounted) setState(() {});
                                    },
                            );
                          },
                          childCount: levels.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final int completed;
  final int totalLevels;
  final int earnedStars;
  final int totalStars;
  final VoidCallback onBack;

  const _LevelHeader({
    required this.completed,
    required this.totalLevels,
    required this.earnedStars,
    required this.totalStars,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalLevels == 0 ? 0.0 : completed / totalLevels;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              _RoundButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEV\u0130YE HAR\u0130TASI',
                      style: TextStyle(
                        color: Color(0xFF63DFFF),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Leveller',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3150),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFFD23F).withOpacity(0.38),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD23F),
                      size: 19,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$earnedStars',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            key: const Key('level_progress_panel'),
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C3959), Color(0xFF0E203A)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF63DFFF).withOpacity(0.38),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF168BFF).withOpacity(0.14),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const _HeaderMetric(
                      icon: Icons.flag_rounded,
                      label: 'TAMAMLANAN',
                      color: Color(0xFF57E6A5),
                    ),
                    const Spacer(),
                    Text(
                      '$completed / $totalLevels',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(height: 8, color: const Color(0xFF091728)),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0, 1),
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF36E6B0), Color(0xFF35C8FF)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Text(
                      '${(progress * 100).round()}% TAMAMLANDI',
                      style: const TextStyle(
                        color: Color(0xFF8EABC8),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD23F),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$earnedStars / $totalStars',
                      style: const TextStyle(
                        color: Color(0xFFFFDE70),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Text(
                'SEV\u0130YEN\u0130 SE\u00c7',
                style: TextStyle(
                  color: Color(0xFFD9EAFA),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              Spacer(),
              _DifficultyDot(color: Color(0xFF57E6A5), label: 'Kolay'),
              SizedBox(width: 8),
              _DifficultyDot(color: Color(0xFFFFC64A), label: 'Orta'),
              SizedBox(width: 8),
              _DifficultyDot(color: Color(0xFFFF5D9E), label: 'Zor'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LevelModel level;
  final int stars;
  final int? bestMoves;
  final bool isLocked;
  final VoidCallback? onTap;

  const _LevelCard({
    super.key,
    required this.level,
    required this.stars,
    required this.bestMoves,
    required this.isLocked,
    this.onTap,
  });

  Color get _difficultyColor => switch (level.difficulty) {
        DifficultyLevel.easy => const Color(0xFF57E6A5),
        DifficultyLevel.medium => const Color(0xFFFFC64A),
        DifficultyLevel.hard => const Color(0xFFFF5D9E),
        DifficultyLevel.expert => const Color(0xFFFF5664),
      };

  String get _difficultyLabel => switch (level.difficulty) {
        DifficultyLevel.easy => 'KOLAY',
        DifficultyLevel.medium => 'ORTA',
        DifficultyLevel.hard => 'ZOR',
        DifficultyLevel.expert => 'UZMAN',
      };

  @override
  Widget build(BuildContext context) {
    final completed = stars > 0;
    final accent = isLocked ? const Color(0xFF52657B) : _difficultyColor;

    return Semantics(
      button: true,
      enabled: !isLocked,
      label:
          isLocked ? 'Seviye ${level.level} kilitli' : 'Seviye ${level.level}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accent.withOpacity(0.18),
          child: AnimatedOpacity(
            opacity: isLocked ? 0.58 : 1,
            duration: const Duration(milliseconds: 250),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: completed
                      ? [
                          accent.withOpacity(0.22),
                          const Color(0xFF13263F),
                          const Color(0xFF0B172A),
                        ]
                      : const [Color(0xFF1A2E45), Color(0xFF101D30)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withOpacity(completed ? 0.7 : 0.32),
                  width: completed ? 1.3 : 1,
                ),
                boxShadow: completed
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.12),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _difficultyLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.75,
                        ),
                      ),
                    ),
                  ),
                  if (completed)
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: accent,
                        size: 15,
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLocked)
                          const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFF8EA0B5),
                            size: 25,
                          )
                        else
                          Text(
                            '${level.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        const SizedBox(height: 9),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (index) => Icon(
                              index < stars
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: index < stars
                                  ? const Color(0xFFFFD23F)
                                  : const Color(0xFF61758C),
                              size: 15,
                            ),
                          ),
                        ),
                        if (bestMoves != null) ...[
                          const SizedBox(height: 7),
                          Text(
                            'EN \u0130Y\u0130  $bestMoves',
                            style: const TextStyle(
                              color: Color(0xFF8FA9C4),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.25,
          ),
        ),
      ],
    );
  }
}

class _DifficultyDot extends StatelessWidget {
  final Color color;
  final String label;

  const _DifficultyDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF829BB7),
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A3150),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF63DFFF).withOpacity(0.35),
            ),
          ),
          child: Icon(icon, color: const Color(0xFFE8F6FF), size: 18),
        ),
      ),
    );
  }
}

class _LevelBackdrop extends StatelessWidget {
  const _LevelBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07162D), Color(0xFF07101F), Color(0xFF030812)],
        ),
      ),
      child: CustomPaint(painter: _LevelBackdropPainter()),
    );
  }
}

class _LevelBackdropPainter extends CustomPainter {
  const _LevelBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF168BFF).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.18),
        radius: size.width * 0.78,
      ));
    canvas.drawRect(Offset.zero & size, glow);

    final paint = Paint()
      ..color = const Color(0xFF2C79B8).withOpacity(0.055)
      ..strokeWidth = 1;
    const gap = 34.0;
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
