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
        
        /*
        self.alertX(isPresented: isPresented) {
            
            let buttons = [
                AlertX.Button.default(Text(L10n.RatingAlert.rateButton),
                        accessibilityIdentifier: A12.RatingAlert.rateButton) {
                        isPresented.wrappedValue = false
                        SKStoreReviewController.requestReviewInCurrentScene()
                        RatingHelper.setRatingResponse(RatingResponse.rate)
                },
                
                AlertX.Button.cancel(Text(L10n.RatingAlert.noButton),
                    accessibilityIdentifier: A12.RatingAlert.noButton) {
                        isPresented.wrappedValue = false
                        RatingHelper.setRatingResponse(RatingResponse.no)
                }]
                
            
            return AlertX(
                title: Text(L10n.RatingAlert.title),
                message: Text(L10n.RatingAlert.message),
                buttonStack: buttons,
                theme: alertX.mfTheme
            )
        }
         
         */
    }
}
