import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'main_menu_screen.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _ctrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool _navigated = false;
  bool _videoReady = false;
  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _initVideo();
      // Güvenlik zamanlayıcısı
      Future.delayed(const Duration(seconds: 8), _startFadeOut);
    });
  }

  Future<void> _initVideo() async {
    try {
      final ctrl =
          VideoPlayerController.asset('assets/images/splashscreen.mp4');
      await ctrl.initialize().timeout(const Duration(seconds: 3));
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      _ctrl = ctrl;
      _ctrl!.setLooping(false);
      _ctrl!.setVolume(1.0);
      _ctrl!.addListener(_onProgress);
      _ctrl!.play();
      setState(() => _videoReady = true);
    } catch (_) {
      _navigate();
    }
  }

  void _onProgress() {
    final ctrl = _ctrl;
    if (ctrl == null || _fadingOut || _navigated) return;
    final dur = ctrl.value.duration;
    final pos = ctrl.value.position;
    // Video bitmek üzereyken (son 100ms) fade başlat
    if (dur > Duration.zero && dur - pos <= const Duration(milliseconds: 100)) {
      _startFadeOut();
    }
  }

  Future<void> _startFadeOut() async {
    if (_fadingOut || _navigated || !mounted) return;
    _fadingOut = true;
    _ctrl?.pause();
    await _fadeCtrl.forward();
    _navigate();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    // Siyah ekran zaten hazır — anında geç, transition yok
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainMenuScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _ctrl?.removeListener(_onProgress);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _startFadeOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video katmanı
            if (_videoReady && ctrl != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: ctrl.value.size.width,
                  height: ctrl.value.size.height,
                  child: VideoPlayer(ctrl),
                ),
              ),
            // Siyah fade overlay — video bitince animasyonla kapanır
            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) => Opacity(
                opacity: _fadeAnim.value,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
