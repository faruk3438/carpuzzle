import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/daily_challenge_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'level_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late final VideoPlayerController _videoCtrl;
  bool _videoReady = false;
  List<DailyTask> _dailyTasks = [];

  @override
  void initState() {
    super.initState();
    _initVideo();
    _refresh();
  }

  Future<void> _initVideo() async {
    _videoCtrl = VideoPlayerController.asset('assets/images/girisekrani.mp4');
    await _videoCtrl.initialize();
    _videoCtrl.setLooping(true);
    _videoCtrl.setVolume(0);
    _videoCtrl.play();
    if (mounted) setState(() => _videoReady = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _dailyTasks = DailyChallengeService.instance.tasks);
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020A18),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 941,
                  height: 1672,
                  child: Stack(
                    children: [
                      // Video arka plan
                      Positioned.fill(
                        child: _videoReady
                            ? FittedBox(
                                fit: BoxFit.fill,
                                child: SizedBox(
                                  width: _videoCtrl.value.size.width,
                                  height: _videoCtrl.value.size.height,
                                  child: VideoPlayer(_videoCtrl),
                                ),
                              )
                            : const ColoredBox(color: Color(0xFF020A18)),
                      ),
                      // Günlük görevler
                      Positioned(
                        left: 94,
                        top: 800,
                        width: 753,
                        height: 320,
                        child: _ImageDailyTasks(tasks: _dailyTasks),
                      ),
                      // Oyna butonu
                      _ImageHotspot(
                        key: const Key('main_menu_play'),
                        semanticLabel: 'Oyna',
                        left: 93,
                        top: 1190,
                        width: 755,
                        height: 205,
                        borderRadius: 104,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LevelSelectScreen(),
                          ),
                        ).then((_) => _refresh()),
                      ),
                      // Ayarlar butonu
                      _ImageHotspot(
                        key: const Key('main_menu_settings'),
                        semanticLabel: 'Ayarlar',
                        left: 120,
                        top: 1420,
                        width: 700,
                        height: 165,
                        borderRadius: 52,
                        onTap: () => _showSettings(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _ImageDailyTasks extends StatelessWidget {
  final List<DailyTask> tasks;

  const _ImageDailyTasks({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final visibleTasks = tasks.take(3).toList();
    final completed = tasks.where((task) => task.completed).length;
    final allDone = tasks.isNotEmpty && completed == tasks.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone ? Icons.celebration_rounded : Icons.task_alt_rounded,
                color:
                    allDone ? const Color(0xFFFFD33D) : const Color(0xFF55D9FF),
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  allDone ? 'Günlük Görevler Tamamlandı!' : 'Günlük Görevler',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${tasks.isEmpty ? 0 : completed}/${tasks.length}',
                style: const TextStyle(
                  color: Color(0xFFB8CAE5),
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'Bugün için yeni görev bulunmuyor.',
                  style: TextStyle(color: Color(0xFF9DB0CC), fontSize: 24),
                ),
              ),
            )
          else
            ...visibleTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      task.completed
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: task.completed
                          ? const Color(0xFF55E6A5)
                          : const Color(0xFF6C86A9),
                      size: 27,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: task.completed
                              ? const Color(0xFF8FA2BC)
                              : const Color(0xFFD8E5F5),
                          fontSize: 23,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: const Color(0xFF8FA2BC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageHotspot extends StatelessWidget {
  final String semanticLabel;
  final double left;
  final double top;
  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback onTap;

  const _ImageHotspot({
    super.key,
    required this.semanticLabel,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ayarlar',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.volume_up_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ses Efektleri',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Switch(
                value: SoundService.instance.sfxEnabled,
                onChanged: (_) {
                  SoundService.instance.toggleSfx();
                  setState(() {});
                },
                activeColor: AppTheme.accentOrange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kapat',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
