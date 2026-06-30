import 'package:flutter/foundation.dart';

enum AdAnalyticsEvent {
  interstitialRequested('ad_interstitial_requested'),
  interstitialLoaded('ad_interstitial_loaded'),
  interstitialShowed('ad_interstitial_showed'),
  interstitialFailed('ad_interstitial_failed'),
  rewardedRequested('ad_rewarded_requested'),
  rewardedLoaded('ad_rewarded_loaded'),
  rewardedShowed('ad_rewarded_showed'),
  rewardedEarned('ad_rewarded_earned'),
  rewardedFailed('ad_rewarded_failed');

  const AdAnalyticsEvent(this.eventName);

  final String eventName;
}

abstract final class AdEventLogger {
  static void log(AdAnalyticsEvent event,
      [Map<String, Object?> data = const {}]) {
    // TODO: Forward this event to Firebase Analytics when it is added.
    debugPrint('[Ads] ${event.eventName} $data');
  }
}
