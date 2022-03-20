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
                Button("Rate", action: {
                    dismissAction?()
                    SKStoreReviewController.requestReviewInCurrentScene()
                    RatingHelper.setRatingResponse(RatingResponse.rate)
                })
                    .buttonStyle(DefaultButtonStyle())
            
                Button("No Thanks", action: {
                    dismissAction?()
                    RatingHelper.setRatingResponse(RatingResponse.no)
                })
                
                Button("Maybe Later", action: {
                    dismissAction?()
                    RatingHelper.setRatingResponse(RatingResponse.later)
                })
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


