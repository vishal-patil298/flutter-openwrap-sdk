import UIKit
import OpenWrapSDK
import Flutter

/// The banner custom event protocol. Your banner custom event handler must implement this protocol
/// to communicate with ad server SDK.
protocol POBFLTBannerEvent: POBBannerEvent {
    /// To check status of ad server ad reques
    /// - Return: Returns true if ad server wins
    func isAdServerWin() -> Bool

    /// Method to route all the OpenWrapSDK global API calls
    /// - Parameters:
    ///     - name: method to invoke
    ///     -  call: FlutterMethodCall for argument & other details
    ///     - result: result block to invoke
    func invokeMethod(methodName: String, call: FlutterMethodCall, result: FlutterResult)
}

/// Handler client to communicate between the ad server handlers & native OW sdk
class POBBannerEventHandlerClient: NSObject, POBFLTBannerEvent {
    weak var eventDelegate: POBBannerEventDelegate?
    private var methodChannel: FlutterMethodChannel?
    private var sizes: [POBAdSize]
    private var adId: Int
    private var adServerWin: Bool = false

    init(adIndex: Int,
         adSizes: [POBAdSize],
         channel: FlutterMethodChannel) {
        adId = adIndex
        methodChannel = channel
        sizes = adSizes
    }

    func setDelegate(_ delegate: POBBannerEventDelegate) {
        eventDelegate = delegate
    }

    func adContentSize() -> CGSize {
        // This won't be invoked in case of flutter apps
        // The content size is returned from the plugin itself
        return CGSize.zero
    }

    func requestedAdSizes() -> [POBAdSize] {
        return sizes
    }

    func requestAd(with bid: POBBid?) {
        adServerWin = false
        let bidsProvider = eventDelegate?.bidsProvider()
        let targeting = bidsProvider?.targettingInfo()
        methodChannel?.invokeMethod("requestAd",
                                    arguments: POBUtils.convertCustomTargetingToMap(targeting: targeting,
                                                                                    adId: adId))
    }

    func isAdServerWin() -> Bool {
        return adServerWin
    }

    func invokeMethod(methodName: String, call: FlutterMethodCall, result: FlutterResult) {
        switch methodName {
        case "onOpenWrapPartnerWin":
            adServerWin = false
            if let args = call.arguments as? [String: Any], let bidId = args["bidId"] as? String {
                eventDelegate?.openWrapPartnerDidWin(forBid: bidId)
            }
            result(nil)
        case "onAdServerWin":
            adServerWin = true
            eventDelegate?.adServerDidWin(UIView())
            result(nil)
        case "onAdImpression":
            eventDelegate?.adServerAdDidRecordImpression()
            result(nil)
        case "onFailed":
            let values = call.arguments as? [String: Any]
            eventDelegate?.failedWithError(POBUtils.error(from: values))
            result(nil)
        case "onAdClick":
            eventDelegate?.didClickAd?()
            result(nil)
        case "onAdClosed":
            eventDelegate?.didDismissModal()
            result(nil)
        case "onAdOpened":
            eventDelegate?.willPresentModal()
            result(nil)
        case "onAdLeftApplication":
            eventDelegate?.willLeaveApp()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
