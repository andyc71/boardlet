//
//  ConditionalStack.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI

struct ConditionalStack<Content>: View where Content: View {
    
    init(alignment: HorizontalAlignment = .center,
         verticalAlignment: VerticalAlignment = .center,
         spacing: CGFloat = 10,
         verticalSpacing: CGFloat = 10,
         isHorizonalStack: Bool,
         name: String = "Default",
         @ViewBuilder content: @escaping () -> Content) {
        
        print("Conditional Stack named: \(name) is horizontal: \(isHorizonalStack)")
        
        self.isHorizonalStack = isHorizonalStack
        self.content = content
        self.alignment = alignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.verticalSpacing = verticalSpacing
    }
    
    var content: () -> Content
    var isHorizonalStack: Bool
    
    var alignment: HorizontalAlignment
    var verticalAlignment: VerticalAlignment
    var spacing: CGFloat
    var verticalSpacing: CGFloat
  
    var body: some View {
        
        Group {
            if isHorizonalStack {
                HStack(alignment: verticalAlignment, spacing: spacing,
                       content: self.content)
                
            }else {
                VStack(alignment: alignment, spacing: verticalSpacing,
                       content: self.content)
                
            }
        }
    }
}

struct ConditionalStack_Previews: PreviewProvider {
    static var previews: some View {
        ConditionalStack(isHorizonalStack: true) {
            Text("first")
            Text("second")
        }
    }
}

