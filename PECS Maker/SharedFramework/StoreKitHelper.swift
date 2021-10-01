//
//  StoreKitHelper.swift
//  SharedUI
//
//  Created by Andy on 10/09/2020.
//  Copyright © 2020 Andrew Clynes. All rights reserved.
//

import StoreKit

public class StoreKitHelper {

    public static func requestRating() {
        SKStoreReviewController.requestReview()
    }
    
    // 1.
    static let minimumReviewWorthyActionCount = 3

    public static func requestReviewIfAppropriate() {
      let defaults = UserDefaults.standard
      let bundle = Bundle.main

      // 2.
      var actionCount = defaults.integer(forKey: .reviewWorthyActionCount)

      // 3.
      actionCount += 1

      // 4.
      defaults.set(actionCount, forKey: .reviewWorthyActionCount)

      // 5.
      guard actionCount >= minimumReviewWorthyActionCount else {
        return
      }

      // 6.
      let bundleVersionKey = kCFBundleVersionKey as String
      let currentVersion = bundle.object(forInfoDictionaryKey: bundleVersionKey) as? String
      let lastVersion = defaults.string(forKey: .lastReviewRequestAppVersion)

      // 7.
      guard lastVersion == nil || lastVersion != currentVersion else {
        return
      }

      // 8.
      SKStoreReviewController.requestReview()

      // 9.
      defaults.set(0, forKey: .reviewWorthyActionCount)
      defaults.set(currentVersion, forKey: .lastReviewRequestAppVersion)
    }
}
