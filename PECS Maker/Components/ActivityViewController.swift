//
//  ActivityViewController.swift
//  PECS Maker
//
//  Created by Andy on 27/09/2021.
//

import SwiftUI
/*
class ActivityViewController : UIViewController {

    var uiImage:UIImage!

    @objc func shareImage() {
        
//        let activityTypes: UIActivity = [
//            UIActivity.ActivityType.saveToCameraRoll,
//            UIActivity.ActivityType.print,
//            UIActivity.ActivityType.copyToPasteboard,
//            UIActivity.ActivityType.airDrop,
//            UIActivity.ActivityType.mail,
//            UIActivity.ActivityType.message
//        ]
        
        let vc = UIActivityViewController(activityItems: [uiImage!], applicationActivities: nil)
        
//        vc.excludedActivityTypes =  [
//            UIActivity.ActivityType.postToWeibo,
//            UIActivity.ActivityType.assignToContact,
//            UIActivity.ActivityType.addToReadingList,
//            UIActivity.ActivityType.postToVimeo,
//            UIActivity.ActivityType.postToTencentWeibo
//        ]
        
        vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if !completed {
                print("User cancelled.")
                return
            }
            if activityType == .saveToCameraRoll {
                print("Saved to photo library.")
            }
        }
        
        present(vc,
                animated: true,
                completion: nil)
        vc.popoverPresentationController?.sourceView = self.view
    }
}

struct SwiftUIActivityViewController : UIViewControllerRepresentable {

    let activityViewController = ActivityViewController()

    func makeUIViewController(context: Context) -> ActivityViewController {
        activityViewController
    }
    func updateUIViewController(_ uiViewController: ActivityViewController, context: Context) {
        //
    }
    func shareImage(uiImage: UIImage) {
        activityViewController.uiImage = uiImage
        activityViewController.shareImage()
    }
}
*/
struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var completionHandler: UIActivityViewController.CompletionWithItemsHandler?
    
    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, completionHandler: UIActivityViewController.CompletionWithItemsHandler? ) {
        
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.completionHandler = completionHandler
    }
    

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        
        vc.completionWithItemsHandler = completionHandler

        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

}
