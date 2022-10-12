//
//  PageLayoutTitleView.swift
//  PECS Maker
//
//  Created by Andy on 12/10/2022.
//

import SwiftUI

struct PageLayoutTitleView : View {
    
    @Binding var title: String
    var confirmAction: ()->()

    @State var isEditing: Bool = false
    
    var body : some View {
        
        HStack(alignment: .center, spacing: 4) {
            if isEditing {
                TextField("Title", text: $title)
                    .font(.title3, weight: .regular)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(AccessibilityIdentifiers.PageLayoutTitleView.titleField)
            }
            else {
                Text(title)
                    .font(.title3, weight: .regular)
                    .accessibilityIdentifier(AccessibilityIdentifiers.PageLayoutTitleView.titleField)
            }
            
            Button(action: {
                if isEditing {
                    confirmAction()
                }
                withAnimation {
                    self.isEditing.toggle()
                }
            }) {
                Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                    .font(.title3, weight: .bold)
                    .foregroundColor(.mfBrightBlue)
                    
            }
            .accessibilityIdentifier(isEditing ? AccessibilityIdentifiers.PageLayoutTitleView.confirmButton : AccessibilityIdentifiers.PageLayoutTitleView.editButton)
        }
    }
}

struct PageLayoutTitleView_Previews: PreviewProvider {

    @State static var title: String = "My Title"
    
    static var previews: some View {
        PageLayoutTitleView(title: $title, confirmAction: {} )
    }
}


