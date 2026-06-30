import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../data/level_repository.dart';
import '../services/daily_challenge_service.dart';
import '../services/ad/ad_manager.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_grid.dart';
import '../widgets/fail_overlay.dart';
import '../widgets/hud_widgets.dart';
import '../widgets/win_overlay.dart';

class GameScreen extends StatelessWidget {
  final String levelId;

  const GameScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = GameBloc();
        final level = LevelRepository.instance.getLevel(levelId);
        if (level != null) bloc.add(GameLoaded(level));
        return bloc;
      },
      child: _GameView(levelId: levelId),
    );
  }
}

class _GameView extends StatelessWidget {
  static const bool showGridCoordinates = false;

  final String levelId;
  const _GameView({required this.levelId});

  Future<void> _onWin(GameState state) async {
    final result = state.result!;
    final level = state.level!;

    await ProgressService.instance.saveStars(levelId, result.stars);
    await ProgressService.instance.saveHighScore(levelId, result.score);
    await ProgressService.instance.saveBestMoves(levelId, result.moveCount);
    await DailyChallengeService.instance.onLevelCompleted(
      stars: result.stars,
      moves: result.moveCount,
      parMoves: level.parMoves,
      hintsUsed: state.hintsUsed,
      comboCount: result.comboCount,
    );

    final levelNumber = LevelRepository.instance.allLevels
            .indexWhere((level) => level.id == levelId) +
        1;
    if (levelNumber > 0) {
      AdManager.instance.recordLevelCompleted(levelNumber);
    }
  }

  void _openNextLevel(BuildContext context) {
    if (!context.mounted) return;
    final nextId = LevelRepository.instance.nextLevelId(levelId);
    if (nextId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(levelId: nextId)),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _continueAfterInterstitial(BuildContext context) async {
    await AdManager.instance.showInterstitialAfterLevel(
      onComplete: () => _openNextLevel(context),
    );
  }

  Future<void> _showRewarded(
    BuildContext context,
    RewardedPlacement placement,
    GameEvent rewardEvent,
  ) async {
    final shown = await AdManager.instance.showRewarded(
      placement: placement,
      onRewardEarned: () {
        if (context.mounted) context.read<GameBloc>().add(rewardEvent);
      },
    );
    if (!shown && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reklam hazır değil. Lütfen biraz bekle.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GameBloc, GameState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: (context, state) async {
            if (state.status == GameStatus.won && state.result != null) {
              SoundService.instance.playWin();
              await _onWin(state);
            }
            if (state.status == GameStatus.failed &&
                state.failReason == FailReason.deadlock) {
              SoundService.instance.playDeadlock();
            }
          },
        ),
        BlocListener<GameBloc, GameState>(
          listenWhen: (p, c) =>
              c.lastCrash != null && c.lastCrash != p.lastCrash,
          listener: (context, state) {
            if (state.lastCrash?.type == CrashType.vipBlocked) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('⭐ Önce VIP aracı çıkar!'),
                backgroundColor: AppTheme.vipColor,
                duration: Duration(milliseconds: 1200),
              ));
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF050B18),
        body: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(child: _GameBackdrop()),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    _TopBar(levelId: levelId),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: const Color(0xFF36D9FF).withOpacity(0.34),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF168BFF).withOpacity(0.13),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: GameGrid(
                                showGridCoordinates:
                                    kDebugMode && showGridCoordinates,
                              ),
                            ),
                            const Positioned(
                              top: 10,
                              left: 0,
                              right: 0,
                              child: Center(child: ComboPopup()),
                            ),
                            _TutorialHint(levelId: levelId),
                            _EmergencyBanner(),
                            _VipReminderBanner(),
                            BlocBuilder<GameBloc, GameState>(
                              buildWhen: (p, c) => p.status != c.status,
                              builder: (context, state) {
                                if (state.status != GameStatus.failed) {
                                  return const SizedBox.shrink();
                                }
                                return FailOverlay(
                                  reason: state.failReason,
                                  lives: state.lives,
                                  canRewardUndo: state.history.isNotEmpty,
                                  onRetry: () => context
                                      .read<GameBloc>()
                                      .add(RestartRequested()),
                                  onRewardLife: () => unawaited(_showRewarded(
                                    context,
                                    RewardedPlacement.extraLife,
                                    RewardLifeGranted(),
                                  )),
                                  onRewardUndo: () => unawaited(_showRewarded(
                                    context,
                                    RewardedPlacement.undo,
                                    RewardUndoGranted(),
                                  )),
                                  onMenu: () => Navigator.popUntil(
                                      context, (r) => r.isFirst),
                                );
                              },
                            ),
                            BlocBuilder<GameBloc, GameState>(
                              buildWhen: (p, c) => p.status != c.status,
                              builder: (context, state) {
                                if (state.status != GameStatus.won) {
                                  return const SizedBox.shrink();
                                }
                                return WinOverlay(
                                  onNextLevel: () => unawaited(
                                    _continueAfterInterstitial(context),
                                  ),
                                  onReplay: () => context
                                      .read<GameBloc>()
                                      .add(RestartRequested()),
                                  onMenu: () => Navigator.popUntil(
                                      context, (r) => r.isFirst),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    GameHudBottom(
                      onRewardedUndo: () => unawaited(_showRewarded(
                        context,
                        RewardedPlacement.undo,
                        RewardUndoGranted(),
                      )),
                      onRewardedHint: () => unawaited(_showRewarded(
                        context,
                        RewardedPlacement.hint,
                        RewardHintGranted(),
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameBackdrop extends StatelessWidget {
  const _GameBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF07152B),
            Color(0xFF081225),
            Color(0xFF040814),
          ],
        ),
      ),
      child: CustomPaint(painter: _GameBackdropPainter()),
    );
  }
}

class _GameBackdropPainter extends CustomPainter {
  const _GameBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF168BFF).withOpacity(0.24),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.38),
        radius: size.width * 0.72,
      ));
    canvas.drawRect(Offset.zero & size, glow);

    final linePaint = Paint()
      ..color = const Color(0xFF2F7CC7).withOpacity(0.08)
      ..strokeWidth = 1;
    const gap = 34.0;
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════
// TOP BAR
// ══════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String levelId;
  const _TopBar({required this.levelId});

  String _difficultyLabel(String name) => switch (name) {
        'easy' => 'KOLAY',
        'medium' => 'ORTA',
        'hard' => 'ZOR',
        'expert' => 'UZMAN',
        _ => name.toUpperCase(),
      };

  Color _difficultyColor(String name) => switch (name) {
        'easy' => AppTheme.accentGreen,
        'medium' => AppTheme.accentOrange,
        'hard' => AppTheme.accentRed,
        'expert' => AppTheme.accentPink,
        _ => AppTheme.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (p, c) => p.level != c.level,
      builder: (context, state) {
        final level = state.level;
        final diffName = level?.difficulty.name ?? '';

        return Container(
          margin: const EdgeInsets.fromLTRB(8, 7, 8, 2),
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF162B48), Color(0xFF0C1930)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF43D8FF).withOpacity(0.38),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.38),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Geri butonu
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFEAF7FF),
                  size: 17,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF243C5D),
                  side: BorderSide(
                    color: const Color(0xFF68DFFF).withOpacity(0.28),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // Yeniden başla
              IconButton(
                onPressed: () =>
                    context.read<GameBloc>().add(RestartRequested()),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFFFFD44D),
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF243C5D),
                  side: BorderSide(
                    color: const Color(0xFFFFD44D).withOpacity(0.25),
                  ),
                ),
              ),

              // Level adı ve zorluk
              Expanded(
                child: Column(
                  children: [
                    if (level != null) ...[
                      Text(
                        level.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'LEVEL ${level.level}',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: Color(0xFF8FA8C7),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  _difficultyColor(diffName).withOpacity(0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _difficultyColor(diffName)
                                    .withOpacity(0.38),
                              ),
                            ),
                            child: Text(
                              _difficultyLabel(diffName),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: _difficultyColor(diffName),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Canlar
              const LivesBar(),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════
// ÖĞRETİCİ METİN — sadece ilk levelde
// ══════════════════════════════════════════════════════

class _TutorialHint extends StatefulWidget {
  final String levelId;
  const _TutorialHint({required this.levelId});

  @override
  State<_TutorialHint> createState() => _TutorialHintState();
}

class _TutorialHintState extends State<_TutorialHint> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible || widget.levelId != 'ch1_l1') return const SizedBox.shrink();
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (p, c) => p.moveCount != c.moveCount,
      builder: (ctx, state) {
        if (state.moveCount > 0) return const SizedBox.shrink();
        return Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: GestureDetector(
            onTap: () => setState(() => _visible = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xF21A3150), Color(0xF20E1C35)],
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFFFFC642).withOpacity(0.55),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Text('🚗', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Arabaya dokun → otoparktan çıkar.\nÖnü kapalıysa çarparsın!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD5E5F7),
                        height: 1.5,
                      ),
                    ),
                  ),
                  Icon(Icons.close_rounded, color: Color(0xFF8DA6C4), size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════
// EMERGENCY BANNER
// ══════════════════════════════════════════════════════

class _EmergencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (p, c) =>
          p.hasActiveEmergency != c.hasActiveEmergency ||
          p.minEmergencyMovesLeft != c.minEmergencyMovesLeft,
      builder: (context, state) {
        if (!state.hasActiveEmergency) return const SizedBox.shrink();
        final left = state.minEmergencyMovesLeft;
        final urgent = left <= 2;

        return Positioned(
          top: 12,
          left: 14,
          right: 14,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: urgent
                  ? const Color(0xFF5B1730).withOpacity(0.96)
                  : const Color(0xFF342047).withOpacity(0.94),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: urgent
                    ? const Color(0xFFFF4D73).withOpacity(0.8)
                    : const Color(0xFFFF7A9E).withOpacity(0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF315F).withOpacity(0.22),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Row(
              children: [
                Text(urgent ? '🚨' : '🚑',
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ambulans $left hamle içinde çıkmalı!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          urgent ? AppTheme.accentRed : AppTheme.emergencyColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════
// VIP BANNER
// ══════════════════════════════════════════════════════

class _VipReminderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (p, c) => p.hasVip != c.hasVip,
      builder: (context, state) {
        if (!state.hasVip) return const SizedBox.shrink();
        if (state.level?.vipRequired != true) return const SizedBox.shrink();

        return Positioned(
          bottom: 12,
          left: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xEE4C3714), Color(0xEE25213A)],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFFFD23F).withOpacity(0.65),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB020).withOpacity(0.18),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Row(
              children: [
                Text('⭐', style: TextStyle(fontSize: 15)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'VIP araç önce çıkmalı!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vipColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
