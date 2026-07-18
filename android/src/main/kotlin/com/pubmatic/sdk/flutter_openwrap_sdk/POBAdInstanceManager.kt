package com.pubmatic.sdk.flutter_openwrap_sdk

/**
 * Singleton class for managing the instance on android side.
 */
object POBAdInstanceManager {
  private val adMap: MutableMap<Int, POBAdClient> = HashMap()

  /**
   * Add the ad in [adMap] with its adId.
   *
   * @param ad format client
   */
  fun registerAd(ad: POBAdClient) {
    adMap[ad.adId] = ad
  }

  /**
   * Remove the ad from [adMap].
   *
   * @param ad format client
   */
  fun unRegisterAd(ad: POBAdClient) {
    adMap.remove(ad.adId)
  }

  /**
   * Return the instance of ad client from [adMap].
   *
   * @param id unique identifier of instance
   * @return Instance of respective ad client
   */
  fun getAd(id: Int): POBAdClient? {
    return adMap[id]
  }
}