//
//  NewiItemCell.swift
//  PECS Maker
//
//  Created by Andy on 29/01/2023.
//

import SwiftUI
import SharedSwiftUI

struct NewItemCell2 : View {
    
    var systemImageName: String = "plus.circle"
    var text: String
    var action: ()->()
    
    
    var body: some View {
        Button(action: { action() } ) {
            HStack {
                Image(systemName: systemImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: AppSettings.gridAddItemCellImageWidth)
                    .foregroundColor(Color(currentTheme.linkTextColor))
                
                Text(text)
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .foregroundColor(Color(currentTheme.linkTextColor))
                
                Spacer()
            }
        }
        .buttonStyle(RoundedButtonStyle( purpose: ButtonPurpose.secondary, cornerRadius:8))
    }

}

struct NewItemCell2_Previews: PreviewProvider {
    
    static var previews: some View {
        
        //We want this view to show that the
        //Add Item cell is top aligned even
        //when the surrounding cells are taller.
        HStack(alignment: .center) {
            NewItemCell2(text: "New Item", action: {})
            Color.blue
                .frame(height: 200)
        }
        .frame(height: 200)
    }
}



