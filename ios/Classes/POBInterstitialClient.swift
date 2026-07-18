import UIKit
import OpenWrapSDK
import Flutter

/// Wrapper class around `POBInterstitial` to transfer the API calls
class POBInterstitialClient: POBAdClient, POBInterstitialDelegate, POBInterstitialVideoDelegate {
    var instl: POBInterstitial?
    var methodChannel: FlutterMethodChannel?
    var eventHandler: POBFLTInterstitialEvent?

    /// Initiates a new interstitial client
    /// - Parameters:
    ///
    /// - adIndex: index to identify the client instance
    /// - pubId: Identifier of the publisher
    /// - profileId: OpenWrap profile ID
    /// - adUnitId: Ad unit id used to identify unique placement on screen
    /// - channel: `FlutterMethodChannel` for native-dart communication
    init(adIndex: Int, publisherId: String, profileId: NSNumber,
         adUnitId: String, isHeaderBidding: Bool, channel: FlutterMethodChannel) {
        super.init(adId: adIndex)
        methodChannel = channel
        if isHeaderBidding {
            eventHandler = POBInterstitialEventHandlerClient(methodChannel: methodChannel, adId: adId)
            instl = POBInterstitial(publisherId: publisherId,
                                    profileId: profileId,
                                    adUnitId: adUnitId,
                                    eventHandler: eventHandler!)
        } else {
            instl = POBInterstitial(publisherId: publisherId,
                                    profileId: profileId,
                                    adUnitId: adUnitId)
        }
        request = instl?.request
    }
    
    override func invokeMethod(names: [String], call: FlutterMethodCall, result: FlutterResult) {
        switch names[1] {
        case "loadAd":
            instl?.loadAd()
            result(nil)
        case "show":
            instl?.show(from: UIApplication.presentedViewController())
            result(nil)
        case "isReady":
            result(instl?.isReady)
        case "setListener":
            instl?.delegate = self
            result(nil)
        case "setVideoListener":
            instl?.videoDelegate = self
            result(nil)
        case "getBid":
            result(convertBidToMap(bid: instl?.bid()))
        case "destroy":
            // ad is removed from super class switch case
            instl = nil
            result(nil)
        case "EventHandler":
            eventHandler?.invokeMethod(methodName: names[2], call: call, result: result)
        default:
            super.invokeMethod(names: names, call: call, result: result)
        }
    }
    
    // MARK: Interstitial delegate methods
    
    // Notifies the delegate that an ad has been received successfully.
    func interstitialDidReceiveAd(_ interstitial: POBInterstitial) {
        methodChannel?.invokeMethod("onAdReceived", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate of an error encountered while loading or rendering an ad.
    func interstitial(_ interstitial: POBInterstitial, didFailToReceiveAdWithError error: Error) {
        let errMap = POBUtils.convertErrorAndAdIdToMap(error: error as NSError, adId: adId)
        methodChannel?.invokeMethod("onAdFailedToLoad", arguments: errMap)
    }
    
    func interstitial(_ interstitial: POBInterstitial, didFailToShowAdWithError error: Error) {
        let errMap = POBUtils.convertErrorAndAdIdToMap(error: error as NSError, adId: adId)
        methodChannel?.invokeMethod("onAdFailedToShow", arguments: errMap)
    }
    
    // Notifies the delegate that the interstitial ad will be presented as a modal
    func interstitialWillPresentAd(_ interstitial: POBInterstitial) {
        // no op
    }
    
    func interstitialDidPresentAd(_ interstitial: POBInterstitial) {
        methodChannel?.invokeMethod("onAdOpened", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate that the interstitial ad has been animated off the screen.
    func interstitialDidDismissAd(_ interstitial: POBInterstitial) {
        methodChannel?.invokeMethod("onAdClosed", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate of ad click
    func interstitialDidClickAd(_ interstitial: POBInterstitial) {
        methodChannel?.invokeMethod("onAdClicked", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate that a user interaction will open another app (e.g. App Store), leaving the current app.
    func interstitialWillLeaveApplication(_ interstitial: POBInterstitial) {
        methodChannel?.invokeMethod("onAppLeaving", arguments: POBUtils.adIdArgs(adId: adId))
    }
    
    // Notifies the delegate that the ad has expired
    func interstitialDidExpireAd(_ interstitial: POBInterstitial) {
        methodChannel?.invokeMethod("onAdExpired", arguments: POBUtils.adIdArgs(adId: adId))
    }

    // Notifies the delegate that the video playback is completed
    func interstitialDidFinishVideoPlayback(_ interstitial: POBInterstitial) {
        methodChannel?.invokeMethod("onVideoPlaybackCompleted", arguments: POBUtils.adIdArgs(adId: adId))
    }

    // Notifies the delegate that the ad impression
    func interstitialDidRecordImpression(_ interstitial: POBInterstitial) {
        methodChannel?.invokeMethod("onAdImpression", arguments: POBUtils.adIdArgs(adId: adId))
    }
}
