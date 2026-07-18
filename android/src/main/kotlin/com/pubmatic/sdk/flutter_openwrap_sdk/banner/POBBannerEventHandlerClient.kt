package com.pubmatic.sdk.flutter_openwrap_sdk.banner

import android.content.Context
import android.view.View
import com.pubmatic.sdk.common.POBAdSize
import com.pubmatic.sdk.common.POBError
import com.pubmatic.sdk.common.log.POBLog
import com.pubmatic.sdk.flutter_openwrap_sdk.POBFlutterConstants
import com.pubmatic.sdk.flutter_openwrap_sdk.POBUtils
import com.pubmatic.sdk.openwrap.banner.POBBannerEvent
import com.pubmatic.sdk.openwrap.banner.POBBannerEventListener
import com.pubmatic.sdk.openwrap.core.POBBid
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The banner custom event abstract class. Your banner custom event handler must implement this
 * class to communicate with ad server SDK.
 */
abstract class POBFLTBannerEvent: POBBannerEvent() {
  /**
   * To check status of ad server ad request
   * @return Returns true if ad server wins
   */
  abstract fun isAdServerWin(): Boolean

  /**
   * The method is called by the client to pass the callbacks from the flutter event handler
   * back to the OW-SDK.
   *
   * @param methodName Method name to be called
   * @param call Method call
   * @param result Result of the method call used to pass data back to flutter part
   */
  abstract fun methodCall(methodName: String, call: MethodCall, result: MethodChannel.Result)
}

/**
 * This event handler is used to fetch the winning bid from OpenWrap sdk and transfer it flutter
 * side event handler to request the ad from GAM SDK.
 *
 * @property context Application context.
 * @property adId for instance management.
 * @property channel for transferring methods calls.
 * @property adSizes List of banner ad sizes.
 */
class POBBannerEventHandlerClient(
  private val context: Context,
  private val adId: Int,
  private val channel: MethodChannel,
  private val adSizes: Array<POBAdSize?>
) : POBFLTBannerEvent() {

  private var eventListener: POBBannerEventListener? = null
  private var adServerWin: Boolean = false

  override fun requestAd(bid: POBBid?) {
    adServerWin = false
    eventListener?.let {
      val customTargeting = it.bidsProvider?.targetingInfo
      channel.invokeMethod("requestAd", POBUtils.getArgumentMap(adId, customTargeting))
    }
  }

  override fun isAdServerWin(): Boolean {
    return adServerWin
  }

  override fun methodCall(methodName: String, call: MethodCall, result: MethodChannel.Result) {
    when (methodName) {
      "onOpenWrapPartnerWin" -> {
        adServerWin = false
        POBLog.info(TAG, "OpenWrap Partner win.")
        eventListener?.onOpenWrapPartnerWin(call.argument("bidId"))
        result.success(null)
      }

      "onAdClick" -> {
        eventListener?.onAdClick()
        result.success(null)
      }

      "onAdClosed" -> {
        eventListener?.onAdClosed()
        result.success(null)
      }

      "onAdLeftApplication" -> {
        eventListener?.onAdLeftApplication()
        result.success(null)
      }

      "onAdOpened" -> {
        eventListener?.onAdOpened()
        result.success(null)
      }

      "onAdImpression" -> {
        POBLog.info(TAG, "GAM banner recorded the impression")
        eventListener?.onAdImpression()
        result.success(null)
      }

      "onAdServerWin" -> {
        adServerWin = true
        POBLog.info(TAG, "Ad Server won.")
        eventListener?.onAdServerWin(View(context))
        result.success(null)
      }

      "onFailed" -> {
        POBLog.info(TAG, "Ad failed to load")
        eventListener?.onFailed(
          POBError(
            call.argument<Int>(POBFlutterConstants.KEY_ERROR_CODE)!!,
            call.argument<String>(POBFlutterConstants.KEY_ERROR_MESSAGE)!!
          )
        )
        result.success(null)
      }

      else -> result.notImplemented()
    }
  }

  override fun setEventListener(eventListener: POBBannerEventListener) {
    this.eventListener = eventListener
  }

  override fun requestedAdSizes(): Array<POBAdSize?> {
    return adSizes
  }

  override fun destroy() {
    eventListener = null
  }

  companion object {
    private const val TAG = "POBBannerEventHandlerClient"
  }
}