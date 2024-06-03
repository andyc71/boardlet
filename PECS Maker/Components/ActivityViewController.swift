//
//  ActivityViewController.swift
//  PECS Maker
//
//  Created by Andy on 27/09/2021.
//

import SwiftUI
import LogFramework
import LogFrameworkFirebase
import FeatureFramework

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
            featuresViewModel.logEvent()
        }

        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.excludedActivityTypes = excludedActivities
        
        vc.completionWithItemsHandler = completionHandler

        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

}
