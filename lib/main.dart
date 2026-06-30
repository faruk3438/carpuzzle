import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/video_splash_screen.dart';
import 'services/daily_challenge_service.dart';
import 'services/sound_service.dart';
import 'services/progress_service.dart';
import 'services/ad/ad_ids.dart';
import 'services/ad/ad_manager.dart';
import 'services/ad/consent_manager.dart';
import 'data/level_repository.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Birbirinden bağımsız başlangıç işlerini aynı anda tamamla.
  await Future.wait([
    ProgressService.instance.init(),
    SoundService.instance.init(),
    LevelRepository.instance.preloadAll(),
  ]);
  await DailyChallengeService.instance.init();

  if (AdIds.isSupportedPlatform) {
    AdIds.logConfigurationWarning();
    if (AdIds.isConfigured) {
      await ConsentManager.instance.initialize();
      if (ConsentManager.instance.canRequestAds) {
        await MobileAds.instance.initialize();
        await AdManager.instance.initialize();
      }
    }
  }

  runApp(const CarParkApp());
}

class CarParkApp extends StatelessWidget {
  const CarParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarPark Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    return const VideoSplashScreen();
  }
}
