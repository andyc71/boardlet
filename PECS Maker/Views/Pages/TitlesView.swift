//
//  TitlesView.swift
//  PECS Maker
//
//  Created by Andy on 8/11/2021.
//

import SwiftUI
import PhotosUI
import LogFramework

struct TitlesView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState

    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
        MFAnalytics.logScreenView(screenName: "Titles")
    }
    
    var body: some View {
        ScrollView {
            
            ForEach(pageLayoutState.photos.enumerated().map { ($0, $1) }, id: \.0) { i, photo in

                HStack {
                    Image(uiImage: photo)
                        .resizable()
                        //.frame(maxWidth: 50, maxHeight: AppSettings.labelRowHeight)
                        //.frame(maxWidth: AppSettings.labelRowHeight, maxHeight: AppSettings.labelRowHeight)
                        .aspectRatio(contentMode: ContentMode.fit)
                        .frame(width: AppSettings.labelRowHeight, height: AppSettings.labelRowHeight)
                        .clipped()
                        .cornerRadius(5)
                        //.padding(SwiftUI.Edge.Set.trailing, 10
                        .padding(SwiftUI.Edge.Set.trailing, 4)
                        //.padding(SwiftUI.Edge.Set.bottom, 5)
                        //.padding()
                        .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.image(for: i))
                    TextField(text: $pageLayoutState.titles[i])
                        .padding(4)
                        .background(Color.tertiarySystemFill)
                        .cornerRadius(4)
                        .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.titleText(for: i))

                    Spacer()
                }
                .padding(4)
            
            }
            
            StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: "Done", isHorizontal: true)
                .padding()
                .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.doneButton)

                Spacer()

        }
        .navigationBarTitle(Text("Titles"), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))
        .onDisappear { dismissAction() }
        
    }
}

struct TitlesView_Previews: PreviewProvider {
    
    @ObservedObject static var pageLayoutState = PageLayoutState()

    static var previews: some View {
        TitlesView(pageLayoutState: pageLayoutState, dismissAction: {})
    }
}
