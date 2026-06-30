import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../services/ad/ad_manager.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════
// CAN GÖSTERGESİ — 3 kalp (animasyonlu azalma)
// ══════════════════════════════════════════════════════

class LivesBar extends StatelessWidget {
  const LivesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (p, c) => p.lives != c.lives,
      builder: (context, state) {
        if (state.lives > startingLives) {
          return const Text(
            '∞',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          );
        }

        // En fazla 3 kalp göster (oyun mekaniğine göre)
        const displayMax = startingLives;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(displayMax, (i) {
            final filled = i < state.lives.clamp(0, displayMax);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TweenAnimationBuilder<double>(
                tween:
                    Tween(begin: filled ? 0.6 : 1.0, end: filled ? 1.0 : 0.7),
                duration: const Duration(milliseconds: 350),
                curve: filled ? Curves.elasticOut : Curves.easeIn,
                builder: (_, v, __) => Transform.scale(
                  scale: v,
                  child: Icon(
                    filled
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        filled ? AppTheme.accentRed : const Color(0xFF536A88),
                    size: 22,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════
// HAMLE SAYACI
// ══════════════════════════════════════════════════════

class MoveCounter extends StatelessWidget {
  const MoveCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (p, c) => p.moveCount != c.moveCount,
      builder: (context, state) {
        final par = state.level?.parMoves ?? 0;
        final moves = state.moveCount;
        final overPar = par > 0 && moves > par;

        return AnimatedContainer(
          key: const Key('move_counter_capsule'),
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 128, minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: overPar
                  ? const [Color(0xFF721C3C), Color(0xFF35142C)]
                  : const [Color(0xFF174B72), Color(0xFF10243F)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: overPar
                  ? AppTheme.accentRed.withOpacity(0.68)
                  : const Color(0xFF65E5FF).withOpacity(0.7),
              width: 1.35,
            ),
            boxShadow: [
              BoxShadow(
                color: (overPar ? AppTheme.accentRed : const Color(0xFF26C9FF))
                    .withOpacity(0.2),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 17,
                    color:
                        overPar ? AppTheme.accentRed : const Color(0xFF63E6FF),
                  ),
                  const SizedBox(width: 7),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(moves),
                    tween: Tween(begin: 1.3, end: 1.0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.elasticOut,
                    builder: (_, v, __) => Transform.scale(
                      scale: v,
                      child: Text(
                        '$moves',
                        style: TextStyle(
                          fontSize: 25,
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                          color: overPar ? AppTheme.accentRed : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 1),
                    child: Text(
                      'HAMLE',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFFC9E7F7),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              if (par > 0) ...[
                const SizedBox(height: 5),
                Text(
                  overPar
                      ? 'HEDEF A\u015eILDI  •  $par'
                      : 'HEDEF  •  $par HAMLE',
                  style: TextStyle(
                    fontSize: 8.5,
                    color:
                        overPar ? AppTheme.accentRed : const Color(0xFF80C8E8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.75,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════
// COMBO POPUP
// ══════════════════════════════════════════════════════

class ComboPopup extends StatefulWidget {
  const ComboPopup({super.key});

  @override
  State<ComboPopup> createState() => _ComboPopupState();
}

class _ComboPopupState extends State<ComboPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.55, 1.0)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameBloc, GameState>(
      listenWhen: (p, c) => c.showCombo && !p.showCombo,
      listener: (_, __) => _ctrl.forward(from: 0),
      child: BlocBuilder<GameBloc, GameState>(
        buildWhen: (p, c) => c.consecutiveExits != p.consecutiveExits,
        builder: (context, state) {
          if (state.consecutiveExits < 2) return const SizedBox.shrink();
          return FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentOrange, AppTheme.accentPink],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentOrange.withOpacity(0.5),
                      blurRadius: 22,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  '🔥 COMBO ×${state.consecutiveExits}!',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ALT HUD ÇUBUĞU
// ══════════════════════════════════════════════════════

class GameHudBottom extends StatelessWidget {
  final VoidCallback onRewardedUndo;
  final VoidCallback onRewardedHint;

  const GameHudBottom({
    super.key,
    required this.onRewardedUndo,
    required this.onRewardedHint,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdManager.instance,
      builder: (context, _) {
        final state = context.watch<GameBloc>().state;
        final adReady = AdManager.instance.isRewardedReady;
        final canUndo = state.status == GameStatus.playing &&
            state.history.isNotEmpty &&
            adReady;
        final canHint = state.status == GameStatus.playing &&
            (state.level?.hintSolution.isNotEmpty ?? false) &&
            adReady;

        return Container(
          margin: const EdgeInsets.fromLTRB(8, 1, 8, 7),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C3959), Color(0xFF10243E), Color(0xFF09172B)],
            ),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: const Color(0xFF67E4FF).withOpacity(0.48),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22B8F0).withOpacity(0.13),
                blurRadius: 24,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.48),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Geri Al
                Expanded(
                  child: _HudBtn(
                    icon: Icons.undo_rounded,
                    label: 'Geri Al',
                    rewarded: true,
                    onTap: canUndo ? onRewardedUndo : null,
                  ),
                ),
                const SizedBox(width: 8),
                // Hamle sayacı — merkez
                const Expanded(flex: 3, child: Center(child: MoveCounter())),
                const SizedBox(width: 8),
                // İpucu
                Expanded(
                  child: _HudBtn(
                    icon: Icons.lightbulb_rounded,
                    label: 'İpucu',
                    rewarded: true,
                    color: const Color(0xFFFFD23F),
                    onTap: canHint ? onRewardedHint : null,
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

class _HudBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool rewarded;
  final VoidCallback? onTap;

  const _HudBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF72DFFF),
    this.rewarded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFF14263A) : const Color(0xFF1D3857),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        splashColor: color.withOpacity(0.2),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.12), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: color.withOpacity(0.38)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.08), blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: onTap == null ? Colors.white30 : color,
                size: 21,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: onTap == null
                            ? Colors.white38
                            : const Color(0xFFE8F4FF),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (rewarded) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.ondemand_video_rounded,
                        size: 10,
                        color: onTap == null ? Colors.white24 : color,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
