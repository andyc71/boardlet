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
    
    var defaultTopicCopyName: String = "Copy of New Design"
    
    var defaultTopicIcon: UIImage = UIImage(systemName: "squareshape.split.3x3")!
    
    var topicDirectoryNamesInAppBundle: [String] = []
    
    var allowRootRepo: Bool = false
    
    var jpegSaveQuality: CGFloat = 0.8
    
    var appHasAudioQuestions: Bool = false
    
}
