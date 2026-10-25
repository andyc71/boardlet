//
//  ContentView.swift
//  PECS Maker
//

import SwiftUI
import SharedSwiftUI
import MediaFramework

struct ContentView: View {
    @EnvironmentObject var currentTheme: SharedUITheme
    @StateObject private var navigationModel = NavigationModel()
    @Binding var topicToEdit: PECSRepo?
    @AppStorage("appMode") var appMode: PECSAppMode = .pecsMaker
    @State private var selectedItems: [PhotoItem] = []
    @State private var didLoadInitialTopic = false

    private var topicSelection: Binding<PECSRepo?> {
        Binding(get: { navigationModel.selectedTopic }, set: { topic in
            navigationModel.selectTopic(topic)
            topicToEdit = topic
        })
    }

    private var destination: Binding<MainMenuAction?> {
        Binding(get: { navigationModel.mainMenuAction }, set: {
            navigationModel.setMainMenuAction($0)
        })
    }

    var body: some View {
        AdaptiveBoardNavigation(topicToEdit: topicSelection, appMode: $appMode,
                                mainMenuAction: destination, selectedItems: $selectedItems)
        .accentColor(.mfVeryBrightBlue)
        .if(appMode == .choiceBoard) { view in
            view.mutePrompt(foregroundColor: Color.mfVeryBrightBlue, backgroundColor: Color.mfLightYellow)
        }
        .environmentObject(navigationModel)
        .onAppear {
            guard !didLoadInitialTopic else { return }
            didLoadInitialTopic = true
            navigationModel.selectTopic(topicToEdit)
        }
        .onChange(of: topicToEdit) { topic in
            // The repository also publishes our own selections asynchronously.
            // An echo must not replace the editor or navigate away from it.
            navigationModel.synchronizeTopic(topic)
        }
    }
}
