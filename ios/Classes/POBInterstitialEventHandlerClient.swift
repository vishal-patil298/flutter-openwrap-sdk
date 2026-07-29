import OpenWrapSDK
import Flutter

/// The interstitial custom event delegate. It is used to inform ad server events back to the OpenWrap SDK
protocol POBFLTInterstitialEvent: POBInterstitialEvent {
    /// Method to route all the OpenWrapSDK global API calls
    /// - Parameters:
    ///     - name: method to invoke
    ///     -  call: FlutterMethodCall for argument & other details
    ///     - result: result block to invoke
    func invokeMethod(methodName: String, call: FlutterMethodCall, result: FlutterResult)
}

/// Wrapper class around `POBInterstitialEvent` to transfer the API calls
///
/// - Parameters:
/// - methodChannel: `MethodChannel` for native-dart communication
/// - delegate: instance of POBInterstitialEventDelegate
/// - adId: Int to uniquely identify ad request
/// - bid: Instance of POBBid

class POBInterstitialEventHandlerClient: NSObject, POBFLTInterstitialEvent {
    var methodChannel: FlutterMethodChannel?
    weak var eventDelegate: POBInterstitialEventDelegate?
    var adId: Int

    init(methodChannel: FlutterMethodChannel?, adId: Int) {
        self.methodChannel = methodChannel
        self.adId = adId
        super.init()
    }

    func requestAd(with bid: POBBid?) {
        let bidsProvider = eventDelegate?.bidsProvider()
        let targeting = bidsProvider?.targettingInfo()
        methodChannel?.invokeMethod("requestAd", arguments: POBUtils.convertCustomTargetingToMap(targeting: targeting,
                                                                                                 adId: adId))

    }

    func setDelegate(_ delegate: POBInterstitialEventDelegate) {
        self.eventDelegate = delegate
    }

    func show(from controller: UIViewController) {
        methodChannel?.invokeMethod("show", arguments: ["adId": adId])
    }

    deinit {
        methodChannel?.invokeMethod("destroy", arguments: ["adId": adId])
        methodChannel = nil
        eventDelegate = nil
    }

    /// The method is called by the client to pass the callbacks from the flutter event handler
    /// back to the OW-SDK.
    ///
    /// - Parameters:
    ///     - methodName: Method name to be called
    ///     - call: Method call
    ///     - result: Result of the method call used to pass data back to flutter part
    func invokeMethod(methodName: String, call: FlutterMethodCall, result: FlutterResult) {
        switch methodName {
        case "onOpenWrapPartnerWin":
            if let args = call.arguments as? [String: Any], let bidId = args["bidId"] as? String {
                eventDelegate?.openWrapPartnerDidWin(forBid: bidId)
            }
            result(nil)
        case "onAdServerWin":
            eventDelegate?.adServerDidWin()
            result(nil)
        case "onAdOpened":
            eventDelegate?.didPresentAd()
            result(nil)
        case "onAdClosed":
            eventDelegate?.didDismissAd()
            result(nil)
        case "onAdExpired":
            eventDelegate?.adDidExpireAd()
            result(nil)
        case "onAdClick":
            eventDelegate?.didClickAd()
            result(nil)
        case "onAdLeftApplication":
            eventDelegate?.willLeaveApp()
            result(nil)
        case "onAdImpression":
            eventDelegate?.adServerAdDidRecordImpression()
            result(nil)
        case "onFailedToLoad":
            let values = call.arguments as? [String: Any]
            eventDelegate?.failedToLoadWithError(POBUtils.error(from: values))
            result(nil)
        case "onFailedToShow":
            let values = call.arguments as? [String: Any]
            eventDelegate?.failedToShowWithError(POBUtils.error(from: values))
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
