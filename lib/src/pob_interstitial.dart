import 'package:flutter/services.dart';
import 'event_handler/pob_interstitial_event.dart';
import 'helpers/pob_utils.dart';
import 'openwrap_sdk_method_channel.dart';
import 'pob_ad.dart';
import 'pob_ad_instance_manager.dart';
import 'pob_constants.dart';
import 'pob_data_types.dart';
import 'pob_type_definition.dart';

/// Displays full-screen interstitial ads.
class POBInterstitial extends POBAd {
  POBInterstitialListener? _interstitialListener;

  /// Instance of [POBBaseEvent] for interacting with Ad Server
  POBInterstitialEvent? _eventHandler;

  /// Instance of [POBVideoListener] for giving video completion call back
  POBVideoListener? _videoListener;

  /// Initializes and returns newly allocated interstitial object for supporting
  /// `OpenWrap Configuration`.
  ///
  /// [pubId] Identifier of the publisher
  /// [profileId] Profile ID of an ad tag
  /// [adUnitId] Ad unit id used to identify unique placement on screen
  /// [eventHandler] Valid Instance of [POBInterstitialEvent]
  POBInterstitial(
      {required String pubId,
      required int profileId,
      required String adUnitId,
      POBInterstitialEvent? eventHandler})
      : super(
            pubId: pubId,
            profileId: profileId,
            adUnitId: adUnitId,
            tag: tagPOBInterstitial) {
    _eventHandler = eventHandler;
    eventHandler?.setInterstitialEventListener(
        _EventHandlerInterstitialListener(ad: this));
    adId = POBAdInstanceManager.instance.loadAd(this);
    adIdMap = {keyAdId: adId};
    openWrapMethodChannel.callPlatformMethod<void>(
        methodName: 'initInterstitialAd',
        argument: <String, dynamic>{
          keyPubId: pubId,
          keyProfileId: profileId,
          keyAdUnitId: adUnitId,
          keyHeaderBidding: _eventHandler != null,
          ...adIdMap
        });
  }

  /// Initiate the loading of an interstitial ad
  Future<void> loadAd() =>
      openWrapMethodChannel.callPlatformMethodWithTag<void>(
          tag: tag, methodName: "loadAd", argument: adIdMap);

  /// Presents an interstitial ad in full screen view until the user dismisses it. Calling this
  /// method has no effect until the ad is received i.e. onAdReceived() gets called. Recommended to
  /// check if isReady() returns true before calling showAd().
  Future<void> showAd() =>
      openWrapMethodChannel.callPlatformMethodWithTag<void>(
          tag: tag, methodName: "show", argument: adIdMap);

  /// Method to check whether the ad is loaded and ready to show InterstitialAd.
  Future<bool?> isReady() =>
      openWrapMethodChannel.callPlatformMethodWithTag<bool>(
          tag: tag, methodName: 'isReady', argument: adIdMap);

  /// Invoke this method when your screen is about to destroy. It cleans the
  /// resources.
  Future<void> destroy() {
    _interstitialListener = null;
    _videoListener = null;
    _eventHandler?.destroy();
    _eventHandler = null;
    return openWrapMethodChannel
        .callPlatformMethodWithTag<void>(
            tag: tag, methodName: 'destroy', argument: adIdMap)
        .then((value) => POBAdInstanceManager.instance.unregister(adId));
  }

  /// Sets instance of [POBInterstitialListener] for getting callbacks
  set listener(POBInterstitialListener listener) {
    openWrapMethodChannel.callPlatformMethodWithTag<void>(
        tag: tag, methodName: 'setListener', argument: adIdMap);
    _interstitialListener = listener;
  }

  /// Sets instance of [POBVideoListener for getting callbacks of VAST based video ad
  set videoListener(POBVideoListener listener) {
    openWrapMethodChannel.callPlatformMethodWithTag<void>(
        tag: tag, methodName: 'setVideoListener', argument: adIdMap);
    _videoListener = listener;
  }

  @override
  void onAdCallBack(MethodCall call) {
    switch (call.method) {
      case 'onAdReceived':
        _interstitialListener?.onAdReceived?.call(this);
        break;
      case 'onAppLeaving':
        _interstitialListener?.onAppLeaving?.call(this);
        break;
      case 'onAdOpened':
        _interstitialListener?.onAdOpened?.call(this);
        break;
      case 'onAdClosed':
        _interstitialListener?.onAdClosed?.call(this);
        break;
      case 'onAdClicked':
        _interstitialListener?.onAdClicked?.call(this);
        break;
      case 'onAdFailedToLoad':
        POBError error =
            POBUtils.convertMapToPOBError(POBUtils.cast(call.arguments));
        _interstitialListener?.onAdFailedToLoad?.call(this, error);
        break;
      case 'onAdFailedToShow':
        POBError error =
            POBUtils.convertMapToPOBError(POBUtils.cast(call.arguments));
        _interstitialListener?.onAdFailedToShow?.call(this, error);
        break;
      case 'onAdExpired':
        _interstitialListener?.onAdExpired?.call(this);
        break;
      case 'onAdImpression':
        _interstitialListener?.onAdImpression?.call(this);
        break;
      case 'onVideoPlaybackCompleted':
        _videoListener?.onVideoPlaybackCompleted(this);
        break;
      case 'requestAd':
        Map<String, String>? owTargeting =
            POBUtils.convertMapOfObjectToMapOfString(
                POBUtils.cast(call.arguments[keyOpenWrapTargeting]));
        _eventHandler?.requestAd(openWrapTargeting: owTargeting);
        break;
      case 'show':
        _eventHandler?.show();
        break;
    }
  }
}

/// The listener implementation for [POBInterstitialEventListener]
/// and extends [EventHandlerListener] which is used to get the callbacks from
/// eventHandler [POBInterstitialEvent] and pass it to the native event handler.
class _EventHandlerInterstitialListener extends EventHandlerListener
    implements POBInterstitialEventListener {
  _EventHandlerInterstitialListener({required POBInterstitial ad})
      : super(ad: ad);

  @override
  POBAdServerAdEvent get onAdExpired =>
      () => openWrapMethodChannel.callPlatformMethodWithTag<void>(
          tag: ad.tag,
          methodName: '$eventHandlerTag#onAdExpired',
          argument: ad.adIdMap);

  @override
  POBEventError get onFailedToLoad => (Map<String, Object> error) =>
      openWrapMethodChannel.callPlatformMethodWithTag<void>(
          tag: ad.tag,
          methodName: '$eventHandlerTag#onFailedToLoad',
          argument: {...ad.adIdMap, ...error});

  @override
  POBEventError get onFailedToShow => (Map<String, Object> error) =>
      openWrapMethodChannel.callPlatformMethodWithTag<void>(
          tag: ad.tag,
          methodName: '$eventHandlerTag#onFailedToShow',
          argument: {...ad.adIdMap, ...error});
}

/// Class for interaction with the POBInterstitial instance for video events.
/// These events will only invoked for VAST based video creative.
/// All methods are guaranteed to occur on the main thread.
class POBVideoListener {
  const POBVideoListener({required this.onVideoPlaybackCompleted});

  ///Notifies the listener that the playback of the video ad has been completed.
  ///
  /// [ad] The POBInterstitial instance invoking this method.
  final POBAdEvent<POBInterstitial> onVideoPlaybackCompleted;
}

/// Static member class for interaction with the POBInterstitial instance.
/// All methods are guaranteed to occur on the main thread.
class POBInterstitialListener extends POBAdListener<POBInterstitial> {
  POBInterstitialListener({
    POBAdEvent<POBInterstitial>? onAdReceived,
    POBAdEvent<POBInterstitial>? onAdOpened,
    POBAdEvent<POBInterstitial>? onAdClosed,
    POBAdEvent<POBInterstitial>? onAdClicked,
    POBAdEvent<POBInterstitial>? onAppLeaving,
    POBAdEvent<POBInterstitial>? onAdImpression,
    this.onAdFailedToLoad,
    this.onAdFailedToShow,
    this.onAdExpired,
  }) : super(
          onAdClicked: onAdClicked,
          onAdClosed: onAdClosed,
          onAdOpened: onAdOpened,
          onAppLeaving: onAppLeaving,
          onAdReceived: onAdReceived,
          onAdImpression: onAdImpression,
        );

  /// Notifies the listener of an error encountered while loading an ad.
  ///
  /// [ad] The POBInterstitial instance invoking this method.
  /// [error] The error encountered while loading the ad.
  final POBAdFailed<POBInterstitial>? onAdFailedToLoad;

  /// Notifies the listener of an error encountered while showing an ad.
  ///
  /// [ad] The POBInterstitial instance invoking this method.
  /// [error] The error encountered while loading the ad.
  final POBAdFailed<POBInterstitial>? onAdFailedToShow;

  /// Notifies that the interstitial ad has been expired. After this callback,
  /// 'POBInterstitial' instances marked as invalid and may not be presented and no impression
  /// counting is considered. After Expiration callback, POBInterstitial.isReady() returns 'false'.
  ///
  /// [ad] The POBInterstitial instance invoking this method.
  final POBAdEvent<POBInterstitial>? onAdExpired;
}
