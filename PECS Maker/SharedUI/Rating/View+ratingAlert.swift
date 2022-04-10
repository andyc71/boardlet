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
    
    var alertXTheme : AlertX.Theme {
        let theme = AlertX.Theme.custom(
                            windowColor: Color.mfPaleBlue,
                            alertTextColor: Color.label,
                            enableShadow: true,
                            enableRoundedCorners: true,
                            enableTransparency: true,
                            cancelButtonColor: Color.mfLightBlue,
                            cancelButtonTextColor: Color.label,
                            defaultButtonColor: Color.mfBrightBlue,
                            defaultButtonTextColor: Color.mfWhite,
                            roundedCornerRadius: 16)
        return theme
    }
    
    
    
    func ratingAlert(isPresented: Binding<Bool>) -> some View {
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
                theme: alertXTheme
            )
        }
    }
}
