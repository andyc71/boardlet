//
//  PageSizeSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Photos
import PhotosUI
import StoreKit
import SharedSwiftUI
import LazyViewSwiftUI
import SwiftUIX
import LogFramework
import LogFrameworkFirebase
import SettingsFramework
import EngagementKit
import AVFoundation
import MediaFramework
import VoicePickerUI
import UIKit

enum MainMenuAction : String, Codable { case changeTopicIcon, selectPhoto, selectLayout, titles, changeSelections, print, settings }

enum ChoiceBoardVoicePreference {
    static let storageKey = "choiceBoardVoiceIdentifier"
    static let localeStorageKey = "choiceBoardVoiceLocale"

    static func normalizedLocale(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "_", with: "-")
    }

    static func languageCode(for locale: String) -> String {
        normalizedLocale(locale).split(separator: "-").first.map(String.init) ?? locale
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue()) // set the `max` value (from both buttons)
    }
}

struct ChoiceBoardVoicePicker: View {
    @AppStorage(ChoiceBoardVoicePreference.storageKey) private var voiceIdentifier = ""
    @AppStorage(ChoiceBoardVoicePreference.localeStorageKey) private var voiceLocale = ""
    @State private var audio = AudioHelper()

    var body: some View {
        VoicePicker(voiceIdentifier: $voiceIdentifier, voiceLocale: $voiceLocale,
                    defaultVoice: { AudioHelper.defaultVoice(for: $0) },
                    preview: { audio.speak("1, 2, 3.", canBeMuted: true, voiceIdentifier: $0.identifier) },
                    stopPreview: { audio.cancelSpeech() })
    }
}

extension View {
    @ViewBuilder
    func selectionAndPadding(isSelected: Bool, isForSplitView: Bool) -> some View {
        modifier(SelectionPaddingModifier())
    }
}

private struct SelectionPaddingModifier: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    func body(content: Content) -> some View {
        content.padding(verticalSizeClass == .compact ? 6 : 12)
    }
}

extension View {
    @ViewBuilder
    func toolbarButtonStyle() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self
        } else {
            self
                //.menuStyle(.button)
                .buttonStyle(.bordered)
                //.clipShape(.circle)
                //.imageScale(.medium)
        }
        #else
        self
#endif
    }
}



//struct MainMenuView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        MainMenuView(photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>)
//    }
//}
