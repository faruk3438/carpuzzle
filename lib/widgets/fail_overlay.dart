import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bloc/game_bloc.dart';
import '../services/ad/ad_manager.dart';

class FailOverlay extends StatefulWidget {
  final FailReason reason;
  final int lives;
  final VoidCallback onRetry;
  final bool canRewardUndo;
  final VoidCallback? onRewardLife;
  final VoidCallback? onRewardUndo;
  final VoidCallback onMenu;

  const FailOverlay({
    super.key,
    required this.reason,
    required this.lives,
    required this.onRetry,
    this.canRewardUndo = false,
    this.onRewardLife,
    this.onRewardUndo,
    required this.onMenu,
  });

  @override
  State<FailOverlay> createState() => _FailOverlayState();
}

class _FailOverlayState extends State<FailOverlay>
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
      duration: const Duration(milliseconds: 1050),
    )..forward();

    _backdropOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.28, curve: Curves.easeOut),
    );
    _cardOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.42, curve: Curves.easeOut),
    );
    _cardOffset = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.58, curve: Curves.easeOutCubic),
    ));
    _cardScale = Tween<double>(begin: 0.9, end: 1).animate(
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
    final style = _FailStyle.forReason(widget.reason);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, AdManager.instance]),
        builder: (context, child) {
          return Stack(
            children: [
              Opacity(
                opacity: _backdropOpacity.value,
                child: _FailBackdrop(style: style),
              ),
              Opacity(
                opacity: _backdropOpacity.value,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FailureAtmospherePainter(
                    progress: _controller.value,
                    accent: style.accent,
                    secondary: style.secondary,
                  ),
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
                          child: _FailCard(
                            style: style,
                            reason: widget.reason,
                            lives: widget.lives,
                            rewardedAdReady: AdManager.instance.isRewardedReady,
                            canRewardUndo: widget.canRewardUndo,
                            animation: _controller,
                            onRetry: widget.onRetry,
                            onRewardLife: widget.onRewardLife,
                            onRewardUndo: widget.onRewardUndo,
                            onMenu: widget.onMenu,
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
  }
}

class _FailBackdrop extends StatelessWidget {
  final _FailStyle style;

  const _FailBackdrop({required this.style});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF0070817),
        gradient: RadialGradient(
          center: const Alignment(0, -0.28),
          radius: 1.08,
          colors: [
            style.accent.withOpacity(0.32),
            style.backdrop,
            const Color(0xFA060711),
          ],
          stops: const [0, 0.46, 1],
        ),
      ),
    );
  }
}

class _FailCard extends StatelessWidget {
  final _FailStyle style;
  final FailReason reason;
  final int lives;
  final bool rewardedAdReady;
  final bool canRewardUndo;
  final Animation<double> animation;
  final VoidCallback onRetry;
  final VoidCallback? onRewardLife;
  final VoidCallback? onRewardUndo;
  final VoidCallback onMenu;

  const _FailCard({
    required this.style,
    required this.reason,
    required this.lives,
    required this.rewardedAdReady,
    required this.canRewardUndo,
    required this.animation,
    required this.onRetry,
    required this.onRewardLife,
    required this.onRewardUndo,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 680;
    final canUndo = reason != FailReason.noLives && canRewardUndo;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 42),
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 26,
              compact ? 52 : 60,
              compact ? 20 : 26,
              compact ? 20 : 26,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: style.cardGradient,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: style.accent.withOpacity(0.56),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF050615).withOpacity(0.76),
                  blurRadius: 44,
                  offset: const Offset(0, 22),
                ),
                BoxShadow(
                  color: style.accent.withOpacity(0.28),
                  blurRadius: 54,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  style.kicker,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: style.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  style.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 25 : 29,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  style.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD3DAF7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: compact ? 18 : 24),
                _LivesPanel(
                  lives: lives,
                  accent: style.accent,
                  emptyAll: reason == FailReason.noLives,
                ),
                SizedBox(height: compact ? 14 : 18),
                _RecoveryTip(style: style, canUndo: canUndo),
                SizedBox(height: compact ? 18 : 22),
                _PrimaryRetryButton(
                  label: style.retryLabel,
                  accent: style.accent,
                  secondary: style.secondary,
                  onTap: onRetry,
                ),
                if (reason == FailReason.noLives && onRewardLife != null) ...[
                  const SizedBox(height: 11),
                  _RewardButton(
                    accent: style.rescue,
                    icon: Icons.favorite_rounded,
                    label: '+1 Can Kazan',
                    enabled: rewardedAdReady,
                    onTap: onRewardLife!,
                  ),
                ] else if (canUndo && onRewardUndo != null) ...[
                  const SizedBox(height: 11),
                  _RewardButton(
                    accent: style.rescue,
                    icon: Icons.undo_rounded,
                    label: 'Reklamla Geri Al',
                    enabled: rewardedAdReady,
                    onTap: onRewardUndo!,
                  ),
                ],
                const SizedBox(height: 12),
                _MenuButton(onTap: onMenu),
              ],
            ),
          ),
          _FailureBadge(style: style, animation: animation),
        ],
      ),
    );
  }
}

class _FailureBadge extends StatelessWidget {
  final _FailStyle style;
  final Animation<double> animation;

  const _FailureBadge({required this.style, required this.animation});

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.18, 0.64, curve: Curves.elasticOut),
    );
    final rotation = Tween<double>(begin: -0.09, end: 0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.14, 0.55, curve: Curves.easeOutBack),
      ),
    );

    return RotationTransition(
      turns: rotation,
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [style.accent, style.secondary],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: style.accent.withOpacity(0.62),
                blurRadius: 34,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(style.icon, color: Colors.white, size: 43),
        ),
      ),
    );
  }
}

class _LivesPanel extends StatelessWidget {
  final int lives;
  final Color accent;
  final bool emptyAll;

  const _LivesPanel({
    required this.lives,
    required this.accent,
    required this.emptyAll,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = emptyAll ? 0 : lives.clamp(0, 3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withOpacity(0.36)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KALAN CAN',
                  style: TextStyle(
                    color: Color(0xFF9CA8D4),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.55,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$remaining / 3',
                  style: TextStyle(
                    color: accent,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(3, (index) {
              final filled = index < remaining;
              return Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Icon(
                  filled ? Icons.favorite_rounded : Icons.heart_broken_rounded,
                  color: filled ? accent : const Color(0xFF596184),
                  size: 25,
                  shadows: filled
                      ? [
                          Shadow(
                            color: accent.withOpacity(0.65),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RecoveryTip extends StatelessWidget {
  final _FailStyle style;
  final bool canUndo;

  const _RecoveryTip({required this.style, required this.canUndo});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: style.rescue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            canUndo ? Icons.lightbulb_rounded : Icons.route_rounded,
            color: style.rescue,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canUndo ? 'KURTARMA HAMLES\u0130' : 'YEN\u0130 PLAN',
                style: TextStyle(
                  color: style.rescue,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.45,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                style.tip,
                style: const TextStyle(
                  color: Color(0xFFBFC8E8),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryRetryButton extends StatelessWidget {
  final String label;
  final Color accent;
  final Color secondary;
  final VoidCallback onTap;

  const _PrimaryRetryButton({
    required this.label,
    required this.accent,
    required this.secondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, secondary]),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.38),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.replay_rounded, color: Colors.white, size: 23),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardButton extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _RewardButton({
    required this.accent,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withOpacity(enabled ? 0.12 : 0.05),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: accent.withOpacity(enabled ? 0.52 : 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: enabled ? accent : Colors.white38, size: 21),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    enabled ? label : 'Reklam Hazırlanıyor',
                    maxLines: 1,
                    style: TextStyle(
                      color: enabled ? accent : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.ondemand_video_rounded,
                color: enabled ? accent : Colors.white24,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF29305C).withOpacity(0.78),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 47,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF7782B8).withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_rounded, color: Color(0xFFB9C4ED), size: 19),
              SizedBox(width: 7),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Ana Men\u00fc',
                    maxLines: 1,
                    style: TextStyle(
                      color: Color(0xFFDCE3FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureAtmospherePainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color secondary;

  const _FailureAtmospherePainter({
    required this.progress,
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final appear = Curves.easeOut.transform(progress.clamp(0, 1));
    final center = Offset(size.width / 2, size.height * 0.28);

    for (var ring = 0; ring < 3; ring++) {
      final ringProgress = ((progress - ring * 0.1) / 0.9).clamp(0.0, 1.0);
      final radius = 55 + ringProgress * (115 + ring * 34);
      final alpha = (1 - ringProgress) * 0.34;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    for (var i = 0; i < 24; i++) {
      final angle = i * 2.399 + 0.4;
      final distance = (72 + (i % 6) * 28) * appear;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final color = i.isEven ? accent : secondary;
      canvas.drawCircle(
        point,
        1.8 + (i % 3),
        Paint()..color = color.withOpacity(0.48 * (1 - progress * 0.5)),
      );
    }
  }

  @override
  bool shouldRepaint(_FailureAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary;
}

class _FailStyle {
  final String kicker;
  final String title;
  final String subtitle;
  final String tip;
  final String retryLabel;
  final IconData icon;
  final Color accent;
  final Color secondary;
  final Color rescue;
  final Color backdrop;
  final List<Color> cardGradient;

  const _FailStyle({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.tip,
    required this.retryLabel,
    required this.icon,
    required this.accent,
    required this.secondary,
    required this.rescue,
    required this.backdrop,
    required this.cardGradient,
  });

  factory _FailStyle.forReason(FailReason reason) => switch (reason) {
        FailReason.deadlock => const _FailStyle(
            kicker: 'TRAF\u0130K K\u0130L\u0130TLEND\u0130',
            title: 'Hareket Alan\u0131 Kalmad\u0131',
            subtitle:
                'Ara\u00e7lar birbirinin yolunu kapatt\u0131. Rotay\u0131 yeniden kur.',
            tip: 'Son hamleyi geri alarak oyunu kaybetmeden devam edebilirsin.',
            retryLabel: 'Seviyeyi Yeniden Dene',
            icon: Icons.car_crash_rounded,
            accent: Color(0xFFFFB020),
            secondary: Color(0xFFFF5C35),
            rescue: Color(0xFF4DEBFF),
            backdrop: Color(0xF22A1233),
            cardGradient: [
              Color(0xFF3A2058),
              Color(0xFF22264F),
              Color(0xFF151A38),
            ],
          ),
        FailReason.emergencyTimeout => const _FailStyle(
            kicker: 'AC\u0130L G\u00d6REV BA\u015eARISIZ',
            title: 'Zaman Doldu!',
            subtitle:
                'Acil durum arac\u0131 zaman\u0131nda \u00e7\u0131k\u0131\u015fa ula\u015famad\u0131.',
            tip:
                'Acil arac\u0131n yolunu ilk hamlelerden itibaren \u00f6nceliklendir.',
            retryLabel: 'G\u00f6revi Tekrarla',
            icon: Icons.emergency_rounded,
            accent: Color(0xFFFF3D71),
            secondary: Color(0xFFFF7A35),
            rescue: Color(0xFF55E6FF),
            backdrop: Color(0xF238102D),
            cardGradient: [
              Color(0xFF4A1748),
              Color(0xFF292052),
              Color(0xFF151937),
            ],
          ),
        FailReason.noLives => const _FailStyle(
            kicker: 'DENEME SONA ERD\u0130',
            title: 'Canlar T\u00fckendi',
            subtitle:
                'Bu tur sona erdi. Yeni bir planla park alan\u0131na geri d\u00f6n.',
            tip:
                'Ara\u00e7lar\u0131n \u00f6n\u00fcn\u00fc kontrol et ve riskli hamleleri sona b\u0131rak.',
            retryLabel: 'Ba\u015ftan Ba\u015fla',
            icon: Icons.heart_broken_rounded,
            accent: Color(0xFFFF4D8D),
            secondary: Color(0xFF8B5CF6),
            rescue: Color(0xFFFFD23F),
            backdrop: Color(0xF22B123E),
            cardGradient: [
              Color(0xFF471D5D),
              Color(0xFF282052),
              Color(0xFF151936),
            ],
          ),
        FailReason.none => const _FailStyle(
            kicker: 'SEV\u0130YE BA\u015eARISIZ',
            title: 'Bir Kez Daha Dene',
            subtitle:
                'Bu deneme tamamlanamad\u0131. Yeni bir rota olu\u015ftur.',
            tip:
                'Her arac\u0131n \u00e7\u0131k\u0131\u015f y\u00f6n\u00fcn\u00fc hamle yapmadan \u00f6nce kontrol et.',
            retryLabel: 'Yeniden Dene',
            icon: Icons.warning_rounded,
            accent: Color(0xFFFF5C6C),
            secondary: Color(0xFFFF8A35),
            rescue: Color(0xFF4DEBFF),
            backdrop: Color(0xF235132B),
            cardGradient: [
              Color(0xFF421E4F),
              Color(0xFF27204C),
              Color(0xFF151936),
            ],
          ),
      };
}
