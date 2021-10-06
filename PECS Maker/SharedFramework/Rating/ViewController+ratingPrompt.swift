//
//  RatingPromptDialog.swift
//  SharedUI
//
//  Created by Andy on 06/06/2021.
//  Copyright © 2021 Andrew Clynes. All rights reserved.
//

import UIKit
import PopupDialog

public extension UIViewController {
    
    func promptForRating( resultClosure: @escaping(RatingPromptChoice)->Void ) {
    
        let vc = RatingPromptViewController()

        // Create the dialog
        let popup = PopupDialog(viewController: vc,
                                buttonAlignment: .horizontal,
                                transitionStyle: .fadeIn,
                                tapGestureDismissal: false,
                                panGestureDismissal: false
                                
                                )
        

        let okButton = DefaultButton(title: "Rate") {
            
            self.showLockScreen(
                title: "Confirm",
                subheading: "Thank you. Please enter the code below to continue.",
                footnote: "The PIN code is there to stop children from accidentally submitting a rating.",
                successAction: { _ in
                    resultClosure(RatingPromptChoice.rate)
                }
            )
            
        }

        let cancelButton = CancelButton(title: "Maybe Later") {
            resultClosure(RatingPromptChoice.maybeLater)
        }

        // Add buttons to dialog
        popup.addButtons([okButton, cancelButton])

        // Present dialog
        present(popup, animated: true, completion: nil)
    }
    
    

    
}

