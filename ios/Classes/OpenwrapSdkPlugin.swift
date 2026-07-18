import Flutter
import UIKit

/// FlutterOpenwrapSdkPlugin
public class OpenwrapSdkPlugin: NSObject, FlutterPlugin {
    var channel: FlutterMethodChannel
    let errMsgMissingParam = "Missing required parameter/s"
    let errCodeMissingParam = "Missing parameter/s"
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_openwrap_sdk", binaryMessenger: registrar.messenger())
        let instance = OpenwrapSdkPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        let factory = POBBannerViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "POBBannerView")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        //Fetch class & method names from the flutter call
        let names = call.method.components(separatedBy: "#")
        let className = names.first
        let method = names.last ?? ""
        switch className {
        case "OpenWrapSDK":
            OpenWrapSDKClient.invokeMethod(name: method, call: call, result: result)
        case "initInterstitialAd":
            initInterstitialAd(call, result: result)
        case "POBInterstitial":
            if let values = call.arguments as? [String: Any],
               let adIdx = values[Constants.kAdIdKey] as? Int {
                let instl = POBAdInstanceManager.shared.ad(adId: adIdx) as? POBInterstitialClient
                instl?.invokeMethod(names: names, call: call, result: result)
            }
        case "initRewardedAd":
            initRewardedAd(call, result: result)
        case "POBRewardedAd":
            if let values = call.arguments as? [String: Any],
               let adIdx = values[Constants.kAdIdKey] as? Int {
                let rewardedAd = POBAdInstanceManager.shared.ad(adId: adIdx) as? POBRewardedClient
                rewardedAd?.invokeMethod(names: names, call: call, result: result)
            }
        case "initBannerAd":
            initBannerAd(call, result: result)
        case "POBBannerView":
            if let values = call.arguments as? [String: Any],
               let adIdx = values[Constants.kAdIdKey] as? Int {
                let banner = POBAdInstanceManager.shared.ad(adId: adIdx) as? POBBannerClient
                banner?.invokeMethod(names: names, call: call, result: result)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func initBannerAd(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let values = call.arguments as? [String: Any],
           let adIdx = values[Constants.kAdIdKey] as? Int,
           let pubid = values[Constants.kPubIdKey] as? String,
           let profileId = values[Constants.kProfileIdKey] as? NSNumber,
           let adUnitId = values[Constants.kAdUnitIdKey] as? String,
           let adSizes = values[Constants.kAdSizesKey] as? [[String: Int]] {
            let isHB = values[Constants.kHBKey] as? Bool ?? false
            let bannerClient = POBBannerClient.init(adIndex: adIdx,
                                                    publisherId: pubid,
                                                    profileId: profileId,
                                                    adUnitId: adUnitId,
                                                    adSizes: adSizes,
                                                    isHeaderBidding: isHB,
                                                    channel: self.channel)
            POBAdInstanceManager.shared.registerAd(adClient: bannerClient)
            result(nil)
        } else {
            result(FlutterError(code: errCodeMissingParam, message: errMsgMissingParam, details: nil))
        }
    }

    func initInterstitialAd(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let values = call.arguments as? [String: Any],
           let adIdx = values[Constants.kAdIdKey] as? Int,
           let pubid = values[Constants.kPubIdKey] as? String,
           let profileId = values[Constants.kProfileIdKey] as? NSNumber,
           let adUnitId = values[Constants.kAdUnitIdKey] as? String,
           let isHeaderBidding = values[Constants.kHBKey] as? Bool {
            let instlClient = POBInterstitialClient.init(adIndex: adIdx,
                                                         publisherId: pubid,
                                                         profileId: profileId,
                                                         adUnitId: adUnitId,
                                                         isHeaderBidding: isHeaderBidding,
                                                         channel: self.channel)
            POBAdInstanceManager.shared.registerAd(adClient: instlClient)
            result(nil)
        } else {
            result(FlutterError(code: errCodeMissingParam, message: errMsgMissingParam, details: nil))
        }
    }

    func initRewardedAd(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let values = call.arguments as? [String: Any],
           let adIdx = values["adId"] as? Int,
            let pubid = values["pubId"] as? String,
            let profileId = values["profileId"] as? NSNumber,
            let adUnitId = values["adUnitId"] as? String {
            let rewardedClient = POBRewardedClient.init(adIndex: adIdx,
                                                     publisherId: pubid,
                                                     profileId: profileId,
                                                     adUnitId: adUnitId,
                                                     channel: self.channel)
            POBAdInstanceManager.shared.registerAd(adClient: rewardedClient)
            result(nil)
        } else {
            result(FlutterError(code: errCodeMissingParam, message: errMsgMissingParam, details: nil))
        }
    }
}
