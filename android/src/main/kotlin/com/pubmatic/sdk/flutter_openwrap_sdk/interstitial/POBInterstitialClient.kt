package com.pubmatic.sdk.flutter_openwrap_sdk.interstitial

import android.content.Context
import com.pubmatic.sdk.common.POBError
import com.pubmatic.sdk.flutter_openwrap_sdk.POBAdClient
import com.pubmatic.sdk.flutter_openwrap_sdk.POBUtils
import com.pubmatic.sdk.openwrap.interstitial.POBInterstitial
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Wrapper around [POBInterstitial] to transfer dart method calls to OpenWrap SDK.
 *
 * @property channel [MethodChannel] for native-dart communication
 * @constructor
 * Initializes the [POBInterstitial] with necessary properties
 *
 * @param adId Unique Instance manager id
 * @param channel MethodChannel for triggering callback on dart side
 * @param context Application context
 * @param pubId Identifier of the publisher
 * @param profileId Profile ID of an ad tag
 * @param adUnitId Ad unit id used to identify unique placement on screen
 * @param isHeaderBidding Boolean indicates whether the GAM flow is included or not
 */
class POBInterstitialClient(
  adId: Int,
  channel: MethodChannel,
  context: Context,
  pubId: String,
  profileId: Int,
  adUnitId: String,
  isHeaderBidding: Boolean
) : POBAdClient(adId, channel) {

  private val interstitial: POBInterstitial
  private var eventHandler: POBFLTInterstitialEvent? = null

  // Initialize [POBInterstitialDefaultEventHandler] in case of header bidding flow
  // by using [isHeaderBidding] parameter else use the default constructor
  init {
    if (isHeaderBidding) {
      eventHandler = POBInterstitialEventHandlerClient(adId, channel)
      interstitial = POBInterstitial(context, pubId, profileId, adUnitId, eventHandler!!)
    } else {
      interstitial = POBInterstitial(context, pubId, profileId, adUnitId)
    }
    request = interstitial.adRequest
    impression = interstitial.impression
  }

  override fun methodCall(names: List<String>, call: MethodCall, result: Result) {
    when (names[1]) {
      "loadAd" -> {
        interstitial.loadAd()
        result.success(null)
      }

      "show" -> {
        interstitial.show()
        result.success(null)
      }

      "isReady" -> result.success(interstitial.isReady)


      "setListener" -> {
        interstitial.setListener(POBInterstitialListenerImpl(channel, adId))
        result.success(null)
      }

      "setVideoListener" -> {
        interstitial.setVideoListener(POBVideoListenerImpl(channel, adId))
        result.success(null)
      }

      "getBid" -> result.success(convertBidToMap(interstitial.bid))

      "destroy" -> {
        super.destroy()
        interstitial.destroy()
        result.success(null)
      }

      "EventHandler" -> eventHandler?.methodCall(names[2], call, result)

      else -> super.methodCall(names, call, result)
    }
  }

  /**
   * Listener for receiving callbacks of [POBInterstitial] events from OpenWrapSDK.
   */
  private class POBInterstitialListenerImpl(
    private val channel: MethodChannel,
    private val adId: Int
  ) : POBInterstitial.POBInterstitialListener() {

    override fun onAdReceived(ad: POBInterstitial) {
      channel.invokeMethod("onAdReceived", POBUtils.getArgumentMap(adId))
    }

    override fun onAdFailedToLoad(ad: POBInterstitial, error: POBError) {
      channel.invokeMethod("onAdFailedToLoad", POBUtils.getArgumentMap(adId, error))
    }

    override fun onAdFailedToShow(ad: POBInterstitial, error: POBError) {
      channel.invokeMethod("onAdFailedToShow", POBUtils.getArgumentMap(adId, error))
    }

    override fun onAppLeaving(ad: POBInterstitial) {
      channel.invokeMethod("onAppLeaving", POBUtils.getArgumentMap(adId))
    }

    override fun onAdOpened(ad: POBInterstitial) {
      channel.invokeMethod("onAdOpened", POBUtils.getArgumentMap(adId))
    }

    override fun onAdClosed(ad: POBInterstitial) {
      channel.invokeMethod("onAdClosed", POBUtils.getArgumentMap(adId))
    }

    override fun onAdClicked(ad: POBInterstitial) {
      channel.invokeMethod("onAdClicked", POBUtils.getArgumentMap(adId))
    }

    override fun onAdExpired(ad: POBInterstitial) {
      channel.invokeMethod("onAdExpired", POBUtils.getArgumentMap(adId))
    }

    override fun onAdImpression(ad: POBInterstitial) {
      channel.invokeMethod("onAdImpression", POBUtils.getArgumentMap(adId))
    }
  }

  /**
   * Listener for receiving callbacks of [POBInterstitial] video events from OpenWrapSDK.
   */
  private class POBVideoListenerImpl(
    private val channel: MethodChannel,
    private val adId: Int
  ) : POBInterstitial.POBVideoListener() {
    override fun onVideoPlaybackCompleted(ad: POBInterstitial) {
      channel.invokeMethod("onVideoPlaybackCompleted", POBUtils.getArgumentMap(adId))
    }
  }
}