//
//  ActivityViewController.swift
//  PECS Maker
//
//  Created by Andy on 27/09/2021.
//

import SwiftUI
import LogFramework
import LogFrameworkFirebase
import EngagementKit

struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var excludedActivities: [UIActivity.ActivityType]? = nil
    var completionHandler: UIActivityViewController.CompletionWithItemsHandler?
    
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    
    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, excludedActivities: [UIActivity.ActivityType]? = nil, completionHandler: UIActivityViewController.CompletionWithItemsHandler? ) {
        
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivities = excludedActivities
        self.completionHandler = completionHandler
    }
    

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {

        DispatchQueue.main.async {
            MFAnalytics.logScreenView(screenName: "ActivityView")
        }

        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.excludedActivityTypes = excludedActivities
        
        vc.completionWithItemsHandler = completionHandler

        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

}

@discardableResult
func presentSystemPrintController(
    printingItem: Any,
    jobName: String,
    from presentingViewController: UIViewController?,
    completionHandler: ((UIPrintInteractionController, Bool, Error?) -> Void)? = nil
) -> Bool {
    let printController = UIPrintInteractionController.shared
    let printInfo = UIPrintInfo(dictionary: nil)
    printInfo.jobName = jobName
    printInfo.outputType = .general
    printController.printInfo = printInfo
    printController.printingItem = printingItem

    if let sourceView = presentingViewController?.view {
        return printController.present(
            from: CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0),
            in: sourceView,
            animated: true,
            completionHandler: completionHandler
        )
    }

    return printController.present(animated: true, completionHandler: completionHandler)
}
