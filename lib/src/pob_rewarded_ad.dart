import 'package:flutter/services.dart';
import 'helpers/pob_utils.dart';
import 'openwrap_sdk_method_channel.dart';
import 'pob_ad.dart';
import 'pob_ad_instance_manager.dart';
import 'pob_constants.dart';
import 'pob_data_types.dart';
import 'pob_type_definition.dart';

/// Displays full-screen rewarded ads.
class POBRewardedAd extends POBAd {
  POBRewardedAdListener? _rewardedAdListener;

  /// Initializes and returns newly allocated rewarded object for supporting
  /// `OpenWrap Configuration`.
  ///
  /// [pubId] Identifier of the publisher
  /// [profileId] Profile ID of an ad tag
  /// [adUnitId] Ad unit id used to identify unique placement on screen
  /// [eventHandler] Valid Instance of [POBRewardedAdEvent]
  POBRewardedAd(
      {required String pubId, required int profileId, required String adUnitId})
      : super(
            pubId: pubId,
            profileId: profileId,
            adUnitId: adUnitId,
            tag: tagPOBRewardedAd) {
    adId = POBAdInstanceManager.instance.loadAd(this);
    adIdMap = {keyAdId: adId};
    openWrapMethodChannel.callPlatformMethod<void>(
        methodName: 'initRewardedAd',
        argument: <String, dynamic>{
          keyPubId: pubId,
          keyProfileId: profileId,
          keyAdUnitId: adUnitId,
          ...adIdMap
        });
  }

  /// Initiate the loading of an rewarded ad
  Future<void> loadAd() =>
      openWrapMethodChannel.callPlatformMethodWithTag<void>(
          tag: tag, methodName: "loadAd", argument: adIdMap);

  /// Presents an rewarded ad in full screen view until the user dismisses it. Calling this
  /// method has no effect until the ad is received i.e. onAdReceived() gets called. Recommended to
  /// check if isReady() returns true before calling showAd().
  Future<void> showAd() =>
      openWrapMethodChannel.callPlatformMethodWithTag<void>(
          tag: tag, methodName: "show", argument: adIdMap);

  /// Method to check whether the ad is loaded and ready to show rewardedAd.
  Future<bool?> isReady() =>
      openWrapMethodChannel.callPlatformMethodWithTag<bool>(
          tag: tag, methodName: 'isReady', argument: adIdMap);

  /// Invoke this method when your screen is about to destroy. It cleans the
  /// resources.
  Future<void> destroy() {
    _rewardedAdListener = null;
    return openWrapMethodChannel
        .callPlatformMethodWithTag<void>(
            tag: tag, methodName: 'destroy', argument: adIdMap)
        .then((value) => POBAdInstanceManager.instance.unregister(adId));
  }

  Future<void> setSkipAlertDialogInfo(String title, String message,
          String resumeTitle, String closeTitle) =>
      openWrapMethodChannel.callPlatformMethodWithTag<void>(
          tag: tag,
          methodName: 'setSkipAlertDialogInfo',
          argument: <String, dynamic>{
            ...adIdMap,
            'title': title,
            'message': message,
            'resumeTitle': resumeTitle,
            'closeTitle': closeTitle
          });

  /// Sets instance of [POBRewardedAdListener] for getting callbacks
  set listener(POBRewardedAdListener listener) {
    openWrapMethodChannel.callPlatformMethodWithTag<void>(
        tag: tag, methodName: 'setListener', argument: adIdMap);
    _rewardedAdListener = listener;
  }

  @override
  void onAdCallBack(MethodCall call) {
    switch (call.method) {
      case 'onAdReceived':
        _rewardedAdListener?.onAdReceived?.call(this);
        break;
      case 'onAppLeaving':
        _rewardedAdListener?.onAppLeaving?.call(this);
        break;
      case 'onAdOpened':
        _rewardedAdListener?.onAdOpened?.call(this);
        break;
      case 'onAdClosed':
        _rewardedAdListener?.onAdClosed?.call(this);
        break;
      case 'onAdClicked':
        _rewardedAdListener?.onAdClicked?.call(this);
        break;
      case 'onAdImpression':
        _rewardedAdListener?.onAdImpression?.call(this);
        break;
      case 'onAdFailedToLoad':
        POBError? error =
            POBUtils.convertMapToPOBError(POBUtils.cast(call.arguments));
        _rewardedAdListener?.onAdFailedToLoad?.call(this, error);
        break;
      case 'onAdFailedToShow':
        POBError error =
            POBUtils.convertMapToPOBError(POBUtils.cast(call.arguments));
        _rewardedAdListener?.onAdFailedToShow?.call(this, error);
        break;
      case 'onAdExpired':
        _rewardedAdListener?.onAdExpired?.call(this);
        break;
      case 'onReceiveReward':
        POBReward reward =
            POBUtils.convertMapToPOBReward(POBUtils.cast(call.arguments));
        _rewardedAdListener?.onReceiveReward?.call(this, reward);
    }
  }
}

/// Static member class for interaction with the POBRewardedAd instance.
/// All methods are guaranteed to occur on the main thread.
class POBRewardedAdListener extends POBAdListener<POBRewardedAd> {
  POBRewardedAdListener({
    POBAdEvent<POBRewardedAd>? onAdReceived,
    POBAdEvent<POBRewardedAd>? onAdOpened,
    POBAdEvent<POBRewardedAd>? onAdClosed,
    POBAdEvent<POBRewardedAd>? onAdClicked,
    POBAdEvent<POBRewardedAd>? onAppLeaving,
    POBAdEvent<POBRewardedAd>? onAdImpression,
    this.onAdFailedToLoad,
    this.onAdFailedToShow,
    this.onAdExpired,
    this.onReceiveReward,
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
  /// [ad] The POBRewardedAd instance invoking this method.
  /// [error] The error encountered while loading the ad.
  final POBAdFailed<POBRewardedAd>? onAdFailedToLoad;

  /// Notifies the listener of an error encountered while showing an ad.
  ///
  /// [ad] The POBRewardedAd instance invoking this method.
  /// [error] The error encountered while loading the ad.
  final POBAdFailed<POBRewardedAd>? onAdFailedToShow;

  /// Notifies that the rewarded ad has been expired. After this callback,
  /// 'POBRewardedAd' instances marked as invalid and may not be presented and no impression
  /// counting is considered. After Expiration callback, POBRewardedAd.isReady() returns 'false'.
  ///
  /// [ad] The POBRewardedAd instance invoking this method.
  final POBAdEvent<POBRewardedAd>? onAdExpired;

  /// Notify reward received for this Rewarded video ad
  ///
  /// [ad] The POBRewardedAd instance invoking this method.
  /// [reward] reward the reward given to user
  final POBAdEventReward<POBRewardedAd>? onReceiveReward;
}
