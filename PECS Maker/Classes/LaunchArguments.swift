//
//  LaunchArguments.swift
//  My Family
//
//  Created by Andy on 09/07/2021.
//  Copyright © 2021 Andy Clynes. All rights reserved.
//

import Foundation

public struct LaunchArguments {
    
    public static let noRatings: String = "-mfNoRatings"
    //public static let noTours: String = "-mfNoTours"
    //public static let resetRepo: String = "-mfResetRepo"
    //public static let screenshots: String = "-mfScreenshots"
    public static let darkMode: String = "-mfDarkMode"
    public static let lightMode: String = "-mfLightMode"
    //public static let extraTopics: String = "-mfExtraTopics"
    //public static let noExtraTopics: String = "-mfNoExtraTopics"
    public static let noAnalytics: String = "-mfNoAnalytics"
    public static let keepPDFs: String = "-mfKeepPDFs"
    public static let autoFill: String = "-mfAutoFill"
    public static let autoFillSingle: String = "-mfAutoFillSingle"
    
    //Enables you to specify a temp directory for storage of documents
    //so it can be deleted at the end of unit tests.
    public static let docDir: String = "-mfDocDoc"
    
    public static let noFeatureVoting: String = "-mfNoFeatureVoting"
    public static let noWhatsNew: String = "-mfNoWhatsNew"
    
    //Resets the Feature Framework so we always get prompted to vote.
    public static let resetFeatureVoting: String = "-mfResetFeatureVoting"
    
    //Resets the Feature Framework so we always get prompted to vote.
    public static let resetWhatsNew: String = "-mfResetWhatsNew"

}
