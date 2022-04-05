//
//  RatingView.swift
//  PECS Maker
//
//  Created by Andy on 06/10/2021.
//

import SwiftUI
//import SharedUI
import StoreKit

struct RatingPromptView: View {
    
    var dismissAction: (() -> ())?

    var body: some View {
        VStack {
            
            HStack{
                Button(L10n.Ratingpromptview.ratebutton, action: {
                    dismissAction?()
                    SKStoreReviewController.requestReviewInCurrentScene()
                    RatingHelper.setRatingResponse(RatingResponse.rate)
                })
                    .buttonStyle(DefaultButtonStyle())
            
                Button(L10n.Ratingpromptview.nobutton
                
                Button(L10n.Ratingpromptview.laterbutton
            }
            .buttonStyle(BorderedButtonStyle())

        }
    }
    
}

struct RatingPromptView_Previews: PreviewProvider {

    static var previews: some View {
        RatingPromptView()
        //ContentView(showRatingPrompt: .constant(false))
    }
}


