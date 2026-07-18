package com.pubmatic.sdk.flutter_openwrap_sdk.banner

import android.content.Context
import android.view.View

import com.pubmatic.sdk.flutter_openwrap_sdk.POBAdInstanceManager
import com.pubmatic.sdk.flutter_openwrap_sdk.POBFlutterConstants

import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * View factory class to host the native view on flutter side.
 */
class POBBannerViewFactory: PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
    return object : PlatformView {
      override fun getView(): View {
        (args as HashMap<*, *>)[POBFlutterConstants.KEY_AD_ID]?.let {
          val client = POBAdInstanceManager.getAd(it as Int)
          if (client is POBBannerViewClient) {
            return client.getAdView()
          }
        }
        return View(context)
      }

      override fun dispose() {
        // No action required.
      }
    }
  }
}