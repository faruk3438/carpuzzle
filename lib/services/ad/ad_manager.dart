import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_events.dart';
import 'ad_ids.dart';

enum RewardedPlacement { extraLife, hint, undo }

class AdManager extends ChangeNotifier {
  AdManager._();

  static final AdManager instance = AdManager._();

  static const interstitialCooldown = Duration(minutes: 2);
  static const _retryDelay = Duration(seconds: 30);

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  Timer? _interstitialRetryTimer;
  Timer? _rewardedRetryTimer;

  bool _initialized = false;
  bool _disposed = false;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  bool _isShowingFullScreenAd = false;
  bool _interstitialDue = false;
  int _eligibleCompletions = 0;
  int _nextInterstitialCadence = 2;
  DateTime? _lastInterstitialShownAt;

  bool get isInterstitialReady => _interstitialAd != null;
  bool get isRewardedReady =>
      _rewardedAd != null && !_isShowingFullScreenAd && !_disposed;
  bool get isShowingFullScreenAd => _isShowingFullScreenAd;

  Future<void> initialize() async {
    if (_initialized || _disposed || !AdIds.isConfigured) return;
    _initialized = true;
    preloadInterstitial();
    preloadRewarded();
  }

  void recordLevelCompleted(int levelNumber) {
    if (!_initialized || levelNumber <= 3) return;

    _eligibleCompletions++;
    if (_eligibleCompletions >= _nextInterstitialCadence) {
      _interstitialDue = true;
      _eligibleCompletions = 0;
      _nextInterstitialCadence = _nextInterstitialCadence == 2 ? 3 : 2;
    }
  }

  Future<void> showInterstitialAfterLevel({
    required VoidCallback onComplete,
  }) async {
    if (_isShowingFullScreenAd) return;

    final ad = _interstitialAd;
    if (!_interstitialDue || ad == null || !_cooldownElapsed) {
      onComplete();
      if (ad == null) preloadInterstitial();
      return;
    }

    _interstitialAd = null;
    _interstitialDue = false;
    _isShowingFullScreenAd = true;
    notifyListeners();

    var completed = false;
    void finish() {
      if (completed) return;
      completed = true;
      _isShowingFullScreenAd = false;
      notifyListeners();
      preloadInterstitial();
      onComplete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _lastInterstitialShownAt = DateTime.now();
        AdEventLogger.log(AdAnalyticsEvent.interstitialShowed);
      },
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        AdEventLogger.log(
          AdAnalyticsEvent.interstitialFailed,
          {'stage': 'show', 'error': error.message},
        );
        failedAd.dispose();
        finish();
      },
    );

    try {
      ad.show();
    } catch (error) {
      AdEventLogger.log(
        AdAnalyticsEvent.interstitialFailed,
        {'stage': 'exception', 'error': '$error'},
      );
      ad.dispose();
      finish();
    }
  }

  Future<bool> showRewarded({
    required RewardedPlacement placement,
    required VoidCallback onRewardEarned,
    VoidCallback? onComplete,
  }) async {
    if (_isShowingFullScreenAd) return false;

    final ad = _rewardedAd;
    if (ad == null) {
      preloadRewarded();
      return false;
    }

    _rewardedAd = null;
    _isShowingFullScreenAd = true;
    notifyListeners();

    var finished = false;
    var rewardGranted = false;
    void finish() {
      if (finished) return;
      finished = true;
      _isShowingFullScreenAd = false;
      notifyListeners();
      preloadRewarded();
      onComplete?.call();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        AdEventLogger.log(
          AdAnalyticsEvent.rewardedShowed,
          {'placement': placement.name},
        );
      },
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        AdEventLogger.log(
          AdAnalyticsEvent.rewardedFailed,
          {
            'stage': 'show',
            'placement': placement.name,
            'error': error.message,
          },
        );
        failedAd.dispose();
        finish();
      },
    );

    try {
      ad.show(onUserEarnedReward: (_, reward) {
        if (rewardGranted) return;
        rewardGranted = true;
        AdEventLogger.log(
          AdAnalyticsEvent.rewardedEarned,
          {
            'placement': placement.name,
            'amount': reward.amount,
            'type': reward.type,
          },
        );
        onRewardEarned();
      });
      return true;
    } catch (error) {
      AdEventLogger.log(
        AdAnalyticsEvent.rewardedFailed,
        {
          'stage': 'exception',
          'placement': placement.name,
          'error': '$error',
        },
      );
      ad.dispose();
      finish();
      return false;
    }
  }

  void preloadInterstitial() {
    final adUnitId = AdIds.interstitialAdUnitId;
    if (!_initialized ||
        _disposed ||
        adUnitId == null ||
        _loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _loadingInterstitial = true;
    AdEventLogger.log(AdAnalyticsEvent.interstitialRequested);
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _loadingInterstitial = false;
          _interstitialRetryTimer?.cancel();
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          AdEventLogger.log(AdAnalyticsEvent.interstitialLoaded);
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          AdEventLogger.log(
            AdAnalyticsEvent.interstitialFailed,
            {'stage': 'load', 'error': error.message},
          );
          _scheduleInterstitialRetry();
        },
      ),
    );
  }

  void preloadRewarded() {
    final adUnitId = AdIds.rewardedAdUnitId;
    if (!_initialized ||
        _disposed ||
        adUnitId == null ||
        _loadingRewarded ||
        _rewardedAd != null) {
      return;
    }

    _loadingRewarded = true;
    AdEventLogger.log(AdAnalyticsEvent.rewardedRequested);
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _loadingRewarded = false;
          _rewardedRetryTimer?.cancel();
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          AdEventLogger.log(AdAnalyticsEvent.rewardedLoaded);
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          AdEventLogger.log(
            AdAnalyticsEvent.rewardedFailed,
            {'stage': 'load', 'error': error.message},
          );
          _scheduleRewardedRetry();
          notifyListeners();
        },
      ),
    );
  }

  BannerAd? createBannerAd({
    AdSize size = AdSize.banner,
    required BannerAdListener listener,
  }) {
    final adUnitId = AdIds.bannerAdUnitId;
    if (!_initialized || _disposed || adUnitId == null) return null;
    return BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: size,
      listener: listener,
    );
  }

  bool get _cooldownElapsed {
    final lastShown = _lastInterstitialShownAt;
    return lastShown == null ||
        DateTime.now().difference(lastShown) >= interstitialCooldown;
  }

  void _scheduleInterstitialRetry() {
    if (_disposed) return;
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = Timer(_retryDelay, preloadInterstitial);
  }

  void _scheduleRewardedRetry() {
    if (_disposed) return;
    _rewardedRetryTimer?.cancel();
    _rewardedRetryTimer = Timer(_retryDelay, preloadRewarded);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _interstitialRetryTimer?.cancel();
    _rewardedRetryTimer?.cancel();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    super.dispose();
  }
}
