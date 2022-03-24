//
//  FormattingView.swift
//  PECS Maker
//
//  Created by Andy on 22/03/2022.
//

import SwiftUI
import SharedSwiftUI

struct FormattingView: View {
    
    @ObservedObject var formattingOptions: CollageFormatting = CollageFormatting.shared

    var body: some View {
        ScrollView {
            
            SimpleCard(title: "Gridlines") {
                Toggle(isOn: $formattingOptions.thickerGridlines ) {
                    Text("Thicker gridlines")
                }
                ColorPicker("Grid colour", selection: $formattingOptions.gridlineColor)
            }
            .padding()
            
            SimpleCard(title: "Titles") {
                ColorPicker("Text colour", selection: $formattingOptions.titleColor)
                Toggle(isOn: $formattingOptions.titleBoldFont ) {
                    Text("Bold font")
                }
            }
            .padding()

//            SimpleCard(title: "Margins") {
//            }
//            .padding()

            Spacer()

        }
        .navigationBarTitle(Text("Layout"), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))
        .onDisappear {
            formattingOptions.saveChanges()
        }

    }
}


