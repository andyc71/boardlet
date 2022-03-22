//
//  FormattingView.swift
//  PECS Maker
//
//  Created by Andy on 22/03/2022.
//

import SwiftUI
import SharedSwiftUI

struct FormattingView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState

    var body: some View {
        ScrollView {
            
            SimpleCard {
                
                Text("Gridlines")
                
                Toggle(isOn: $pageLayoutState.formattingOptions.thickerGridlines ) {
                    Text("Thicker gridlines")
                }
//                Toggle(isOn: $pageLayoutState.darkGridlines ) {
//                    Text("Dark gridlines")
//                }
                
                ColorPicker("Colour", selection: $pageLayoutState.formattingOptions.gridlineColor)
                
            }

            
            Spacer()
        }
        .navigationBarTitle(Text("Layout"), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))

    }
}


