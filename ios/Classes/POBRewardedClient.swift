import UIKit
import OpenWrapSDK
import Flutter

/// Wrapper class around `POBRewardedAd` to transfer the API calls
class POBRewardedClient: POBAdClient, POBRewardedAdDelegate {
    var rewardedAd: POBRewardedAd?
    var methodChannel: FlutterMethodChannel?

    /// Initiates a new rewarded client
    /// - Parameters:
    ///
    /// - adIndex: index to identify the client instance
    /// - pubId: Identifier of the publisher
    /// - profileId: OpenWrap profile ID
    /// - adUnitId: Ad unit id used to identify unique placement on screen
    /// - channel: `FlutterMethodChannel` for native-dart communication
    init(adIndex: Int, publisherId: String, profileId: NSNumber, adUnitId: String, channel: FlutterMethodChannel) {
        super.init(adId: adIndex)
        rewardedAd = POBRewardedAd(publisherId: publisherId, profileId: profileId, adUnitId: adUnitId)
        request = rewardedAd?.request
        methodChannel = channel
    }

    override func invokeMethod(names: [String], call: FlutterMethodCall, result: FlutterResult) {
        switch names[1] {
        case "loadAd":
            rewardedAd?.loadAd()
            result(nil)
        case "show":
            rewardedAd?.show(from: UIApplication.presentedViewController())
            result(nil)
        case "isReady":
            result(rewardedAd?.isReady)
        case "setListener":
            rewardedAd?.delegate = self
            result(nil)
        case "setSkipAlertDialogInfo":
            if let skipAlertInfo = call.arguments as? [String: Any] {
                setSkipAlert(info: skipAlertInfo)
            }
            result(nil)
        case "getBid":
            result(convertBidToMap(bid: rewardedAd?.bid()))
        case "destroy":
            // ad is removed from super class switch case
            rewardedAd = nil
            result(nil)
        default:
            super.invokeMethod(names: names, call: call, result: result)
        }
    }

    func setSkipAlert(info: [String: Any]) {
        if let title = info["title"] as? String,
           let msg = info["message"] as? String,
           let resumeTitle = info["resumeTitle"] as? String,
           let closeTitle = info["closeTitle"] as? String {
            rewardedAd?.setSkipAlertInfoWithTitle(title,
                                                  message: msg,
                                                  closeButtonTitle: closeTitle,
                                                  resumeButtonTitle: resumeTitle)
        }
    }

    // MARK: Rewarded delegate methods
    
    // Notifies the delegate that an ad has been received successfully.
    func rewardedAdDidReceive(_ rewardedAd: POBRewardedAd) {
        methodChannel?.invokeMethod("onAdReceived", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate that a user will be rewarded once the ad is completely viewed.
    func rewardedAd(_ rewardedAd: POBRewardedAd, shouldReward reward: POBReward) {
        let rewardInfo = ["currencyType": reward.currencyType, 
                          "amount": Int(truncating: reward.amount),
                          Constants.kAdIdKey: adId] as [String: Any]
        methodChannel?.invokeMethod("onReceiveReward", arguments: rewardInfo)
    }

    // Notifies the delegate of an error encountered while loading or rendering an ad.
    func rewardedAd(_ rewardedAd: POBRewardedAd, didFailToReceiveAdWithError error: Error) {
        let errMap = POBUtils.convertErrorAndAdIdToMap(error: error as NSError, adId: adId)
        methodChannel?.invokeMethod("onAdFailedToLoad", arguments: errMap)
    }
    
    // Notifies the delegate of an error encountered while showing an ad.
    func rewardedAd(_ rewardedAd: POBRewardedAd, didFailToShowAdWithError error: Error) {
        let errMap = POBUtils.convertErrorAndAdIdToMap(error: error as NSError, adId: adId)
        methodChannel?.invokeMethod("onAdFailedToShow", arguments: errMap)
    }
    
    // Notifies the delegate that the rewarded ad will be presented as a modal
    func rewardedAdWillPresent(_ rewardedAd: POBRewardedAd) {
        // no op
    }

    // Notifies the delegate that the rewarded ad has been presented as a modal
    func rewardedAdDidPresent(_ rewardedAd: POBRewardedAd) {
        methodChannel?.invokeMethod("onAdOpened", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate that the rewarded ad has been animated off the screen.
    func rewardedAdDidDismiss(_ rewardedAd: POBRewardedAd) {
        methodChannel?.invokeMethod("onAdClosed", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate of ad click
    func rewardedAdDidClick(_ rewardedAd: POBRewardedAd) {
        methodChannel?.invokeMethod("onAdClicked", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate that a user interaction will open another app (e.g. App Store), leaving the current app.
    func rewardedAdWillLeaveApplication(_ rewardedAd: POBRewardedAd) {
        methodChannel?.invokeMethod("onAppLeaving", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate that the ad has expired
    func rewardedAdDidExpireAd(_ rewardedAd: POBRewardedAd) {
        methodChannel?.invokeMethod("onAdExpired", arguments: POBUtils.adIdArgs(adId: adId))
    }

    // Notifies the delegate that the ad impression
    func rewardedAdDidRecordImpression(_ rewardedAd: POBRewardedAd) {
        methodChannel?.invokeMethod("onAdImpression", arguments: POBUtils.adIdArgs(adId: adId))
    }
}
