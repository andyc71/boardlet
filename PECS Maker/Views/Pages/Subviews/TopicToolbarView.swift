//
//  PageLayoutTitleView.swift
//  PECS Maker
//
//  Created by Andy on 12/10/2022.
//

import SwiftUI
import SharedSwiftUI

struct TopicToolbarView : View {
    
    @EnvironmentObject var currentTheme: SharedUITheme
    
    @Binding var title: String
    var confirmAction: ()->()
    var deleteAction: ()->()

    @State var isEditing: Bool = false
    
    var body : some View {
        
        HStack(alignment: .center, spacing: 4) {
                Text(title)
                    .font(.title3, weight: .regular)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.titleField)

            Button(action: {
                self.isEditing.toggle()
            })
            {
                Image(systemName: "pencil")
                    .font(.title3, weight: .bold)
                    .foregroundColor(.mfBrightBlue)
                    
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.renameButton)
            .renameItemAlert(isPresented: $isEditing, itemName: $title, placeholder: L10n.RenameTopicAlert.placeholder, title: L10n.RenameTopicAlert.title, message: nil, theme: currentTheme, saveAction: confirmAction)
            
            /*
            if !isEditing {
                
                Button(action: { deleteAction() }, label: {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                        .foregroundColor(.systemRed)
                })
            }*/
            
        }
    }
}

struct PageLayoutTitleView_Previews: PreviewProvider {

    @State static var title: String = "My Title"
    
    static var previews: some View {
        TopicToolbarView(title: $title, confirmAction: {} , deleteAction: {})
    }
}


