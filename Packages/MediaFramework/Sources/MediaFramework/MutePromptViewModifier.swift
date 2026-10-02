//
//  MutePromptViewModifier.swift
//
//  Created by Andy on 24/08/2024.
//

#if canImport(SwiftUI)
import SwiftUI
#endif
//import SharedSwiftUI

@available(iOS 14.0, *)
struct MutePromptModifier: ViewModifier {
    //@EnvironmentObject var viewModel: MuteViewModel
    @StateObject var viewModel = MuteViewModel()
    @State var offset: CGFloat = -200
    
    var foregroundColor: Color
    var backgroundColor: Color
    
    var overlayView: some View {
        VStack {
            MutePromptView(foregroundColor: foregroundColor, backgroundColor: backgroundColor)
                .environmentObject(viewModel)
                .offset(y: offset)
                .onAppear {
                    withAnimation(.easeOut) {
                        offset = 0
                    }
                }
            Spacer()
        }
    }
    
    func body(content: Content) -> some View {
        if viewModel.showMutePrompt {
            content.overlay(overlayView)
        }
        else {
            content
        }
            
    }
}

@available(iOS 14.0, *)
public extension View {
    func mutePrompt(foregroundColor: Color, backgroundColor: Color) -> some View {
        self.modifier(MutePromptModifier(foregroundColor: foregroundColor, backgroundColor: backgroundColor))
    }
}


