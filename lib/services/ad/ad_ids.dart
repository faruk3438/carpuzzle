import 'dart:io';

import 'package:flutter/foundation.dart';

/// Single source of truth for AdMob ad unit IDs.
///
/// Debug and profile builds always use Google's test IDs. Replace only the
/// production constants before creating a release build.
abstract final class AdIds {
  static const String androidAdMobAppId = 'YOUR_ANDROID_ADMOB_APP_ID';
  static const String androidInterstitialAdUnitId =
      'YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID';
  static const String androidRewardedAdUnitId =
      'YOUR_ANDROID_REWARDED_AD_UNIT_ID';
  static const String androidBannerAdUnitId = 'YOUR_ANDROID_BANNER_AD_UNIT_ID';

  static const String iosAdMobAppId = 'YOUR_IOS_ADMOB_APP_ID';
  static const String iosInterstitialAdUnitId =
      'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID';
  static const String iosRewardedAdUnitId = 'YOUR_IOS_REWARDED_AD_UNIT_ID';
  static const String iosBannerAdUnitId = 'YOUR_IOS_BANNER_AD_UNIT_ID';

  static const _androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const _androidTestInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const _androidTestRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _androidTestBanner = 'ca-app-pub-3940256099942544/6300978111';

  static const _iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const _iosTestInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _iosTestRewarded = 'ca-app-pub-3940256099942544/1712485313';
  static const _iosTestBanner = 'ca-app-pub-3940256099942544/2934735716';

  static bool get isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  static String? get appId => _select(
        androidTest: _androidTestAppId,
        iosTest: _iosTestAppId,
        androidProduction: androidAdMobAppId,
        iosProduction: iosAdMobAppId,
      );

  static String? get interstitialAdUnitId => _select(
        androidTest: _androidTestInterstitial,
        iosTest: _iosTestInterstitial,
        androidProduction: androidInterstitialAdUnitId,
        iosProduction: iosInterstitialAdUnitId,
      );

  static String? get rewardedAdUnitId => _select(
        androidTest: _androidTestRewarded,
        iosTest: _iosTestRewarded,
        androidProduction: androidRewardedAdUnitId,
        iosProduction: iosRewardedAdUnitId,
      );

  static String? get bannerAdUnitId => _select(
        androidTest: _androidTestBanner,
        iosTest: _iosTestBanner,
        androidProduction: androidBannerAdUnitId,
        iosProduction: iosBannerAdUnitId,
      );

  static bool get isConfigured {
    if (!isSupportedPlatform) return false;
    if (!kReleaseMode) return true;

    final values = Platform.isAndroid
        ? [
            androidAdMobAppId,
            androidInterstitialAdUnitId,
            androidRewardedAdUnitId,
            androidBannerAdUnitId,
          ]
        : [
            iosAdMobAppId,
            iosInterstitialAdUnitId,
            iosRewardedAdUnitId,
            iosBannerAdUnitId,
          ];
    return values.every(_looksLikeAdMobId);
  }

  static void logConfigurationWarning() {
    if (kReleaseMode && !isConfigured) {
      debugPrint(
        '[AdMob] RELEASE ADS DISABLED: production IDs in ad_ids.dart still '
        'contain placeholders. The game will continue without ads.',
      );
    }
  }

  static String? _select({
    required String androidTest,
    required String iosTest,
    required String androidProduction,
    required String iosProduction,
  }) {
    if (!isSupportedPlatform) return null;
    if (!kReleaseMode) return Platform.isAndroid ? androidTest : iosTest;
    if (!isConfigured) return null;
    return Platform.isAndroid ? androidProduction : iosProduction;
  }

  static bool _looksLikeAdMobId(String value) =>
      value.startsWith('ca-app-pub-') && !value.contains('YOUR_');
}
