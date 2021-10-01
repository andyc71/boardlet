//
//  Card.swift
//  PECS Maker
//
//  Created by Andy on 01/10/2021.
//
import SwiftUI


struct SimpleCard<Content>: View where Content: View {
    
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill((Theme.cardBackgroundColor))
            )
    }
}
