import Flutter
import OpenWrapSDK
import UIKit

/// View factory class to host the native view on flutter side.
class POBBannerViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        // Return banner ad for adId
        if let values = args as? [String: Any],
           let adIdx = values["adId"] as? Int {
            guard let banner = POBAdInstanceManager.shared.ad(adId: adIdx) as? POBBannerClient else {
                return DefaultBannerClient()
            }
            return banner
        }
        //Return a default empty view if banner client isn't available
        return DefaultBannerClient()
    }

    /// Implementing this method is only necessary when the `arguments` in `createWithFrame` is not `nil`.
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class DefaultBannerClient: NSObject, FlutterPlatformView {
    func view() -> UIView {
        return UIView()
    }
}
