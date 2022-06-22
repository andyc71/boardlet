//
//  UIView+ratingAlert.swift
//  PECS Maker
//
//  Created by Andy on 09/04/2022.
//

import SwiftUI
import SharedSwiftUI
import StoreKit

extension View {
    
    func ratingAlert(isPresented: Binding<Bool>) -> some View {
        
        self.askQuestionYesNo(isPresented: isPresented, title: L10n.RatingAlert.title, message: L10n.RatingAlert.message, yesAction: {
            SKStoreReviewController.requestReviewInCurrentScene()
            RatingHelper.setRatingResponse(RatingResponse.rate)
        },
            noAction: {
                RatingHelper.setRatingResponse(RatingResponse.no)
            }
        )
    }
}
