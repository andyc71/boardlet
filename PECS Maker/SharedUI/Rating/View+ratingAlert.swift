//
//  UIView+ratingAlert.swift
//  PECS Maker
//
//  Created by Andy on 09/04/2022.
//

import SwiftUI
import SharedSwiftUI
import StoreKit

enum RatingAlertState {
    case hidden, askInitialQuestion, selectFeedbackCategory, requestMoreInfo, thankYou
    mutating func start() {
        self = .askInitialQuestion
    }
}


extension View {
    
    func ratingAlert(state: Binding<RatingAlertState> ) -> some View {

//        let binding1 = Binding<Bool>(
//                get: { state.wrappedValue == .initialQuestion },
//                //set: { newValue in state.wrappedValue = newValue ? .initialQuestion : .requestFeedback }
//                set: { _ in  }
//        )
//        let binding2 = Binding<Bool>(
//            get: { state.wrappedValue == .requestFeedback },
//            //set: { newValue in state.wrappedValue = newValue ? .requestFeedback : .hidden }
//            set: { _ in  }
//        )

        return self
            .askInitialQuestion(state: state)
            .selectFeedbackCategory(state: state)
            .requestMoreInfo(state: state)
            .thankYouAlert2(state: state)
        
    }
    
   
    func askInitialQuestion(state: Binding<RatingAlertState>) -> some View {

        let yesButton = MFButton(text: L10n.RatingAlert.rateButton, accessibilityId: L10n.RatingAlert.rateButton, purpose: .primary, shouldCallDismiss: false, action: {
            SKStoreReviewController.requestReviewInCurrentScene()
            RatingHelper.setRatingResponse(RatingResponse.rate)
            DispatchQueue.main.async {
                state.wrappedValue = .hidden
            }
            //completion(RatingResponse.rate)
        })
        
        let noButton = MFButton(text: L10n.RatingAlert.noButton, accessibilityId: L10n.RatingAlert.noButton, purpose: .primary, shouldCallDismiss: false, action: {
            RatingHelper.setRatingResponse(RatingResponse.no)
            DispatchQueue.main.async {
                state.wrappedValue = .selectFeedbackCategory
            }
            //completion(RatingResponse.no)
        })
        
        let isPresented = Binding<Bool>(
                get: { state.wrappedValue == .askInitialQuestion },
                //set: { newValue in state.wrappedValue = newValue ? .initialQuestion : .requestFeedback }
                set: { _ in  }
        )

        return self.askQuestion(isPresented: isPresented, title: L10n.RatingAlert.title, message: L10n.RatingAlert.message, buttons: [yesButton, noButton])
        
    }
    
    func selectFeedbackCategory(state: Binding<RatingAlertState>) -> some View {
        
        let suggestions: [String] = [
            "Add a new feature",
            "Make it easier to use",
            "Fix a problem",
            "Another suggestion",
            ]
        
        var buttons = [MFButton]()
        for issue in suggestions {
            let button = MFButton(text: issue, accessibilityId: L10n.RatingAlert.rateButton, purpose: .primary, action: {
                DispatchQueue.main.async { state.wrappedValue = .requestMoreInfo }
            })
            buttons.append(button)
        }
        
        let isPresented = Binding<Bool>(
            get: { state.wrappedValue == .selectFeedbackCategory },
            //set: { newValue in state.wrappedValue = newValue ? .requestFeedback : .hidden }
            set: { _ in  }
        )
        
        return self.askQuestion(isPresented: isPresented, title: L10n.RatingAlert.title, message: L10n.RatingAlert.message, buttons: buttons)
        
    }
    
    func requestMoreInfo(state: Binding<RatingAlertState>) -> some View {
        
        let yesButton = MFButton(text: "Yes", accessibilityId: L10n.RatingAlert.rateButton, purpose: .primary, shouldCallDismiss: false, action: {
            SKStoreReviewController.requestReviewInCurrentScene()
            RatingHelper.setRatingResponse(RatingResponse.rate)
            DispatchQueue.main.async {
                state.wrappedValue = .thankYou
            }
            //completion(RatingResponse.rate)
        })
        
        let noButton = MFButton(text: "No", accessibilityId: L10n.RatingAlert.noButton, purpose: .primary, shouldCallDismiss: false, action: {
            RatingHelper.setRatingResponse(RatingResponse.no)
            DispatchQueue.main.async {
                state.wrappedValue = .thankYou
            }
            //completion(RatingResponse.no)
        })
        
        let isPresented = Binding<Bool>(
                get: { state.wrappedValue == .requestMoreInfo },
                //set: { newValue in state.wrappedValue = newValue ? .initialQuestion : .requestFeedback }
                set: { _ in  }
        )

        return self.askQuestion(isPresented: isPresented, title: "Provide More Information", message: "Are you happy to send some more information?", buttons: [yesButton, noButton])
        
    }
    
    func thankYouAlert2(state: Binding<RatingAlertState>) -> some View {
        
        let isPresented = Binding<Bool>(
            get: { state.wrappedValue == .thankYou },
            //set: { newValue in state.wrappedValue = newValue ? .requestFeedback : .hidden }
            set: { _ in  }
        )
        
        return self.thankYouAlertView(isPresented: isPresented, completion: {
            //DispatchQueue.main.async {
                state.wrappedValue = .hidden
            //}
        })
        
    }
    

    
}
