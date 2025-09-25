//
//  Settings+OpenAI.swift
//  PECS Maker
//
//  Created by Andy on 07/03/2025.
//
import Foundation

#if EasyPECSPlus
import OpenAIKit

extension AppSettings {
    var openAIConfig: OpenAIKit.Configuration? {
        
        guard let path = Bundle.main.path(forResource: "OpenAI-Info", ofType: "plist") else {
            print("Cannot find OpenAI-Info.plist.")
            return nil
        }
               
        guard let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Cannot load OpenAI-Info.plist into a dictionary.")
            return nil
        }
        
        guard let orgID = plist["OPEN_AI_ORG_ID"] as? String else {
            print("Open AI Org ID not found.")
            return nil
        }
        guard let apiKey = plist["OPEN_AI_API_KEY"] as? String else {
            print("Open AI API Key not found.")
            return nil
        }
        
        return Configuration(
            organizationId: orgID,
            apiKey: apiKey
        )
    }
}
#endif
