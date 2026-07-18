package com.pubmatic.sdk.flutter_openwrap_sdk.interstitial

import com.pubmatic.sdk.common.POBError
import com.pubmatic.sdk.common.log.POBLog
import com.pubmatic.sdk.flutter_openwrap_sdk.POBFlutterConstants
import com.pubmatic.sdk.flutter_openwrap_sdk.POBUtils
import com.pubmatic.sdk.openwrap.core.POBBid
import com.pubmatic.sdk.openwrap.interstitial.POBInterstitialEvent
import com.pubmatic.sdk.openwrap.interstitial.POBInterstitialEventListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The OpenWrap interstitial custom event abstract class. Your interstitial custom event handler must
 * implement this class to communicate with ad server SDK.
 */
abstract class POBFLTInterstitialEvent : POBInterstitialEvent() {
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
 * Implementation of [POBInterstitialEvent] which is used as the event handler for OW-SDK in case of
 * header bidding.
 *
 * @param adId AdId used for storing the Ad object in the map
 * @param channel Instance of [MethodChannel] used to call flutter methods and pass data
 */
class POBInterstitialEventHandlerClient(
  private val adId: Int,
  private val channel: MethodChannel
) :
  POBFLTInterstitialEvent() {

  private var eventListener: POBInterstitialEventListener? = null

  override fun requestAd(bid: POBBid?) {
    eventListener?.let {
      val openWrapTargeting = it.bidsProvider?.targetingInfo
      channel.invokeMethod("requestAd", POBUtils.getArgumentMap(adId, openWrapTargeting))
    }
  }

  override fun methodCall(methodName: String, call: MethodCall, result: MethodChannel.Result) {
    when (methodName) {
      "onAdOpened" -> {
        eventListener?.onAdOpened()
        result.success(null)
      }

      "onAdClosed" -> {
        eventListener?.onAdClosed()
        result.success(null)
      }

      "onAdServerWin" -> {
        POBLog.info(TAG, "Ad Server won.")
        eventListener?.onAdServerWin()
        result.success(null)
      }

      "onAdExpired" -> {
        eventListener?.onAdExpired()
        result.success(null)
      }

      "onAdClick" -> {
        eventListener?.onAdClick()
        result.success(null)
      }

      "onAdLeftApplication" -> {
        eventListener?.onAdLeftApplication()
        result.success(null)
      }

      "onAdImpression" -> {
        POBLog.info(TAG, "GAM interstitial recorded the impression")
        eventListener?.onAdImpression()
        result.success(null)
      }

      "onFailedToLoad" -> {
        eventListener?.onFailedToLoad(
          POBError(
            call.argument<Int>(POBFlutterConstants.KEY_ERROR_CODE)!!,
            call.argument<String>(POBFlutterConstants.KEY_ERROR_MESSAGE)!!
          )
        )
        result.success(null)
      }

      "onFailedToShow" -> {
        eventListener?.onFailedToShow(
          POBError(
            call.argument<Int>(POBFlutterConstants.KEY_ERROR_CODE)!!,
            call.argument<String>(POBFlutterConstants.KEY_ERROR_MESSAGE)!!
          )
        )
        result.success(null)
      }

      "onOpenWrapPartnerWin" -> {
        POBLog.info(TAG, "OpenWrap Partner win.")
        eventListener?.onOpenWrapPartnerWin(call.argument<String>("bidId"))
        result.success(null)
      }

      else -> result.notImplemented()
    }
  }

  override fun show() {
    channel.invokeMethod("show", POBUtils.getArgumentMap(adId))
  }

  override fun destroy() {
    eventListener = null
  }

  override fun setEventListener(eventListener: POBInterstitialEventListener) {
    this.eventListener = eventListener
  }

  companion object {
    private const val TAG = "POBInterstitialEventHandlerClient"
  }
}