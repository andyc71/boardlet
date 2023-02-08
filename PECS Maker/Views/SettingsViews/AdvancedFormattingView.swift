//
//  AdvancedSettingsView.swift
//  PECS Maker
//
//  Created by Andy on 05/02/2023.
//

import SwiftUI
import SharedSwiftUI

class AdvancedSettingsViewModel : ObservableObject {

    enum SaveFormat: String { case pdf, image }
    
    @Published public  var saveFormat: SaveFormat = .pdf
    
    private (set) static var shared = AdvancedSettingsViewModel()
    
    private init() {
    }

}

struct AdvancedSettingsView: View {
    
    @ObservedObject var settingsViewModel = AdvancedSettingsViewModel.shared
    
    var body: some View {
        ScrollView {
            SimpleCard {
                Text("Export file type")
                Picker("Format", selection: $settingsViewModel.saveFormat) {
                    Text("PDF").tag(AdvancedSettingsViewModel.SaveFormat.pdf)
                    //.accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Titles.TextPosition.top)
                    Text("Image").tag(AdvancedSettingsViewModel.SaveFormat.image)
                    //.accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Titles.TextPosition.bottom)
                }
                .pickerStyle(.segmented)
                Text("PDFs are great for printing and sharing. Images are best for saving to your photo library")
                    .foregroundColor(.secondaryLabel)
            }
            .padding()
        }
        .navigationBarTitle(L10n.SettingsPage.title, displayMode: .inline)
        //.navigationBarItems(leading: closeButtonIfNeeded)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))

        
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettingsView()
    }
}
