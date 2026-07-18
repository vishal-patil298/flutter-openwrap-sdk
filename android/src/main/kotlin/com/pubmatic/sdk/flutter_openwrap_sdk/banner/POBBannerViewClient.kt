package com.pubmatic.sdk.flutter_openwrap_sdk.banner

import android.content.Context
import com.pubmatic.sdk.common.POBError
import com.pubmatic.sdk.flutter_openwrap_sdk.POBAdClient
import com.pubmatic.sdk.flutter_openwrap_sdk.POBUtils
import com.pubmatic.sdk.openwrap.banner.POBBannerView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Wrapper class around [POBBannerView] to transfer the APIs calls.
 *
 * @property channel [MethodChannel] for native-dart communication
 * @constructor
 * Initializes the [POBBannerView] with necessary properties
 *
 * @param adId Unique Instance manager id
 * @param channel MethodChannel for triggering callback on dart side
 * @param context Application context
 * @param pubId Identifier of the publisher
 * @param profileId Profile ID of an ad tag
 * @param adUnitId Ad unit id used to identify unique placement on screen
 * @param adSizes List of HashMap containing ad sizes
 */
class POBBannerViewClient(
  adId: Int,
  channel: MethodChannel,
  context: Context,
  pubId: String,
  profileId: Int,
  adUnitId: String,
  adSizes: List<HashMap<String, Int>>,
  isHeaderBidding: Boolean
) : POBAdClient(adId, channel) {
  private var bannerView: POBBannerView

  private var eventHandler: POBFLTBannerEvent? = null

  init {
    if (isHeaderBidding) {
      eventHandler = POBBannerEventHandlerClient(
        context, adId, channel,
        POBUtils.convertListToPOBAdSizes(adSizes)
      )
      bannerView = POBBannerView(context, pubId, profileId, adUnitId, eventHandler!!)
    } else {
      bannerView = POBBannerView(
        context, pubId, profileId, adUnitId,
        *POBUtils.convertListToPOBAdSizes(adSizes)
      )
    }
    bannerView.setListener(POBBannerViewListenerImpl(channel, adId))
    request = bannerView.adRequest
    impression = bannerView.impression
  }

  override fun methodCall(names: List<String>, call: MethodCall, result: Result) {
    when (names[1]) {
      "loadAd" -> {
        bannerView.loadAd()
        result.success(null)
      }

      "pauseAutoRefresh" -> {
        bannerView.pauseAutoRefresh()
        result.success(null)
      }

      "resumeAutoRefresh" -> {
        bannerView.resumeAutoRefresh()
        result.success(null)
      }

      "forceRefresh" -> result.success(bannerView.forceRefresh())

      "getBid" -> result.success(convertBidToMap(bannerView.bid))

      "getCreativeSize" -> result.success(
        hashMapOf(
          "w" to bannerView.creativeSize?.adWidth,
          "h" to bannerView.creativeSize?.adHeight
        )
      )

      "destroy" -> {
        super.destroy()
        bannerView.destroy()
        result.success(null)
      }

      "EventHandler" -> eventHandler?.methodCall(names[2], call, result)

      else -> super.methodCall(names, call, result)
    }
  }

  /**
   * Return the banner ad, use by [POBBannerViewFactory].
   *
   * @return Instance of [POBBannerView]
   */
  internal fun getAdView(): POBBannerView {
    // In-case of gam ad win, empty POBBannerView is returned to support ad refresh
    if (eventHandler?.isAdServerWin() == true) {
      bannerView.removeAllViews()
    }
    return bannerView
  }

  /**
   * Listener for receiving callbacks of [POBBannerView] events from OpenWrapSDK.
   */
  private class POBBannerViewListenerImpl(
    private val channel: MethodChannel,
    private val adId: Int
  ) : POBBannerView.POBBannerViewListener() {
    override fun onAdReceived(bannerView: POBBannerView) {
      channel.invokeMethod("onAdReceived", POBUtils.getArgumentMap(adId))
    }

    override fun onAdFailed(bannerView: POBBannerView, error: POBError) {
      channel.invokeMethod("onAdFailed", POBUtils.getArgumentMap(adId, error))
    }

    override fun onAppLeaving(bannerView: POBBannerView) {
      channel.invokeMethod("onAppLeaving", POBUtils.getArgumentMap(adId))
    }

    override fun onAdOpened(bannerView: POBBannerView) {
      channel.invokeMethod("onAdOpened", POBUtils.getArgumentMap(adId))
    }

    override fun onAdClosed(bannerView: POBBannerView) {
      channel.invokeMethod("onAdClosed", POBUtils.getArgumentMap(adId))
    }

    override fun onAdClicked(bannerView: POBBannerView) {
      channel.invokeMethod("onAdClicked", POBUtils.getArgumentMap(adId))
    }

    override fun onAdImpression(view: POBBannerView) {
      channel.invokeMethod("onAdImpression", POBUtils.getArgumentMap(adId))
    }
  }
}