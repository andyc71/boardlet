//
//  TopicFactory.swift
//  PECS Maker
//
//  Created by Andy on 07/10/2022.
//

import LogFramework

typealias FamilyRepo = Topic

class TopicFactory {
    
    private static var _availableTopics: [FamilyRepo]?
    
    static func findTopic(in directory: URL)  -> FamilyRepo? {

        #if NumberMatching
            return NumberMatchingRepo(directory: directory)
        #elseif MyName
            return NameMatchingRepo.findTopic(directory: directory)
        #else
            return FamilyRepo.findTopic(directory: directory)
        #endif
    }

    static func findTopic(withName name: String)  -> FamilyRepo? {
        let topics = availableTopics
        return topics.first(where: { $0.topicName.uppercased().contains(name.uppercased()) } )
    }

    static func findTopic(minItemCount: Int)  -> FamilyRepo? {
        let topics = availableTopics
        return topics.first(where: {$0.familyMembers.count >= minItemCount})
    }
    
    static func upgradeDirectoryStructure() {

        //See if there's a default topic in the root folder
        let directoryURL = FamilyRepo.getDocumentsDirectory()
        if findTopic(in: directoryURL) != nil {
            
            let sourceDirectoryURL = directoryURL
            
            let topicDir = makeDirectoryNameForTopic(Settings.defaultTopicName)
            let targetDirectoryURL = makeLocalDirectoryURLForTopic(topicDirectory: topicDir )

            do {
                try copyOrMoveFilesInDirectory(sourceDirectoryURL, to: targetDirectoryURL, move: true)

                //Load the repo, which will force it to upgrade.
                let _ = try FamilyRepo(directory: targetDirectoryURL)
            }
            catch {
                logger.logError(.repo, "Failed to upgrade repo in default documents folder")
            }

        }
    }
    
    
    static var topicDirectoryBase: URL {
        FamilyRepo.getDocumentsDirectory().appendingPathComponent(RepoFactory.topicDirectoryName, isDirectory: true)
    }
    
    static var iCloudContainerTopicBaseURL: URL? {
        iCloudContainerRootURL?.appendingPathComponent("Documents", isDirectory: true).appendingPathComponent(RepoFactory.topicDirectoryName, isDirectory: true)
    }
    
    static var availableTopics: [FamilyRepo] {
        get {
            if let topics = _availableTopics {
                return topics
            }
            
            var topics = [FamilyRepo]()
            
            upgradeDirectoryStructure()
            
            //Look for themes in the Themes subdirectory within the iCloud container
            if let iCloudContainerTopicBaseURL = iCloudContainerTopicBaseURL {
                if let themeDirectoryNames = FileUtils.getDirectoryContents(iCloudContainerTopicBaseURL) {
                    for directoryName in themeDirectoryNames {
                        let directoryURL = iCloudContainerTopicBaseURL.appendingPathComponent(directoryName, isDirectory: true)
                        if let topic = findTopic(in: directoryURL) {
                            topics.append(topic)
                        }
                    }
                }
            }
            
            //Look for themes in the Themes subdirectory within the Documents dir
            if let themeDirectoryNames = FileUtils.getDirectoryContents(topicDirectoryBase) {
                
                for directoryName in themeDirectoryNames {
                    
                    let directoryURL = topicDirectoryBase.appendingPathComponent(directoryName, isDirectory: true)
                    
                    if let topic = findTopic(in: directoryURL) {
                        
                        if topics.contains(where: { $0.topicName == topic.topicName}) {
                            logger.logDebug(.repo, "Ignoring duplicate topic \(topic.topicName) in local documents folder")
                            continue
                        }
                        
                        topics.append(topic)
                    }
                }
            }
            
            //Look for themes in the app bundle
            if let themeDirectory = topicDirectoryBaseInBundle {
                let themeDirectoryNames = getTopicDirectoryNamesInBundle()
                
                for directoryName in themeDirectoryNames {
                    
                    let directoryURL = themeDirectory.appendingPathComponent(directoryName, isDirectory: true)
                    
                    if let topic = findTopic(in: directoryURL) {
                        
                        if topics.contains(where: { $0.topicName == topic.topicName}) {
                            logger.logDebug(.repo, "Ignoring duplicate topic \(topic.topicName) in bundle")
                            continue
                        }
                        
                        topics.append(topic)
                        
                    }
                }
            }
            
            
            let sortedTopics = sortTopics(topics)
            self._availableTopics = sortedTopics
            
            return sortedTopics
            
        }
        
    }
    
    static func sortTopics(_ unsortedTopics: [FamilyRepo]) -> [FamilyRepo] {
        
        //        for topic in unsortedTopics {
        //            if topic.topicName.uppercased().contains("DEFAULT")
        //        }
        
        //returns true when the first element should be ordered before the second.
        let sortedTopics = unsortedTopics.sorted(by: {
            
            if $0.topicName.contains(Settings.defaultTopicName) {
                return true
            }
            if $1.topicName.contains(Settings.defaultTopicName) {
                return false
            }
            return $0.topicName < $1.topicName
        } )
        
        return sortedTopics
        
    }
    
}
