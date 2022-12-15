//
//  PECSPersistenceSettings.swift
//  PECS Maker
//
//  Created by Andy on 09/10/2022.
//

import Foundation
import PersistenceFramework
import UIKit

class PECSPersistenceSettings : PersistenceSettingsProtocol {
    var defaultTopicName: String = "Untitled Design"
    
    var newTopicName: String = "New Design"
    
    //Needs to return a localized version of:
    //Copy of Original Name
    //Copy 2 of Original Name
    func makeTopicCopyName(originalName: String, copyNumber: Int) -> String {
        if copyNumber < 2 {
            return "Copy of \(originalName)"
        }
        else {
            return "Copy \(copyNumber) of \(originalName)"
        }
    }
    
    var defaultTopicIcon: UIImage = UIImage(systemName: "squareshape.split.3x3")!
    
    var topicDirectoryNamesInAppBundle: [String] = []
    
    var allowRootRepo: Bool = false
    
    var jpegSaveQuality: CGFloat = 0.8
    
    var appHasAudioQuestions: Bool = false
    
    var allowDuplicateNames: Bool = true
    
}
