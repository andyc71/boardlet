//
//  SKStoreReviewController.swift
//  PECS Maker
//
//  Created by Andy on 03/10/2021.
//

// From: https://stackoverflow.com/questions/63953891/requestreview-was-deprecated-in-ios-14-0

import UIKit
import StoreKit

extension SKStoreReviewController {
    public static func requestReviewInCurrentScene() {
        
        if #available(iOS 14.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
        
    }
}

