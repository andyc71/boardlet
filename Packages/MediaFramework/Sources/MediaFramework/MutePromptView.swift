//
//  MutePromptView.swift
//
//  Created by Andy on 24/08/2024.
//

#if canImport(SwiftUI)
import SwiftUI
#endif
//import SharedSwiftUI

@available(iOS 13.0, *)
struct MutePromptView: View {
    
    @EnvironmentObject private var viewModel: MuteViewModel
    //@EnvironmentObject var currentTheme: SharedUITheme
    var foregroundColor: Color
    var backgroundColor: Color
    
    var body: some View {
        
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                
                Text("Sound is muted", bundle: .module)
                //Text("Sound is muted")
                    .multilineTextAlignment(.leading)
                    .font(.headline)
                    .foregroundColor(foregroundColor)
                //.accessibilityIdentifier(AccessibilityIdentifiersFF.votePromptVoteButton)
                Text("Turn up the volume to hear the Choice Board.", bundle: .module)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(foregroundColor)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.dismissPrompt()
            }) {
                Image(systemName: "xmark")
                    .padding(6)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            //.accessibilityIdentifier(AccessibilityIdentifiersFF.votePromptDismissButton)
            
        }
        .padding(12)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 8)
        .frame(maxWidth: 350)
        
    }
}
