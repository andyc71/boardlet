//
//  SKStoreReviewController.swift
//  PECS Maker
//
//  Created by Andy on 03/10/2021.
//

// From: https://stackoverflow.com/questions/64503955/skstoreproductviewcontroller-must-be-used-in-a-modal-view-controller-swiftui
// Problem is that it seems to work at the time, but then your app crashes when the window closes (something about needing to present
// the view as modal and not being able to subclass it.

import UIKit
import StoreKit
import SwiftUI

struct StoreView: UIViewControllerRepresentable {
    
    //AppID or DeveloperID to show other apps by the same dev
    let appID: String
    
    @Environment(\.presentationMode) var presentation
    
    class Coordinator: NSObject, SKStoreProductViewControllerDelegate {
        @Binding var presentation: PresentationMode
        init(presentation: Binding<PresentationMode> ) {
            _presentation = presentation
        }
        private func productViewControllerDidFinish(viewController: SKStoreProductViewController) {
            $presentation.wrappedValue.dismiss()
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<StoreView>) -> SKStoreProductViewController {
        let skStoreProductViewController = SKStoreProductViewController()
        skStoreProductViewController.delegate = context.coordinator
        let parameters = [
            SKStoreProductParameterITunesItemIdentifier : appID
        ]
        skStoreProductViewController.loadProduct(withParameters: parameters)
        return skStoreProductViewController
    }
    
    func updateUIViewController(_ uiViewController: SKStoreProductViewController, context: UIViewControllerRepresentableContext<StoreView>) {
    }
}


extension SKStoreProductViewController {
    
    func loadProduct(appID: String) {
        
        
        let parameters = [
            SKStoreProductParameterITunesItemIdentifier : appID
        ]
        self.loadProduct(withParameters: parameters, completionBlock: { (success,error) -> Void in
            
            
            if #available(iOS 14.0, *) {
                
                let rvc = UIApplication.shared.rootViewController
                
                rvc?.present(self, animated: true, completion: nil)
                
            }
        })
        
        //UIApplication.shared.windows.first?.rootViewController?.present(self, animated: true, completion: nil)
        
        /*
         if #available(iOS 14.0, *) {
         if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
         SKStoreReviewController.requestReview(in: scene)
         }
         } else {
         SKStoreReviewController.requestReview()
         }
         */
    }
    
}



extension UIApplication {
    var currentKeyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
    }
    
    var rootViewController: UIViewController? {
        currentKeyWindow?.rootViewController
    }
    
}

