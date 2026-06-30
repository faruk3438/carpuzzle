import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentManager {
  ConsentManager._();

  static final ConsentManager instance = ConsentManager._();

  bool _initialized = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;

  bool get canRequestAds => _canRequestAds;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final updateCompleter = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      updateCompleter.complete,
      (error) {
        debugPrint('[AdMob][Consent] Update failed: ${error.message}');
        updateCompleter.complete();
      },
    );
    await updateCompleter.future;

    final formCompleter = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) {
        debugPrint('[AdMob][Consent] Form failed: ${error.message}');
      }
      formCompleter.complete();
    });
    await formCompleter.future;

    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    _privacyOptionsRequired = await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;

    // TODO: Configure the messages in AdMob > Privacy & messaging and expose
    // showPrivacyOptionsForm() from the settings screen when required.
  }

  Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        debugPrint('[AdMob][Consent] Privacy options failed: ${error.message}');
      }
      completer.complete();
    });
    await completer.future;
  }
}
