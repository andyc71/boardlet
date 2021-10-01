//
//  CopyrightRow.swift
//  SwiftUI Settings Screen
//
//  Created by Andrew Clynes on 09/09/20.
//  Copyright © 2020 Andrew Riyam. All rights reserved.
//

import SwiftUI

struct CopyrightRow: View {

    var text: String

    var body: some View {

        Text( text )
            .bold()
            .foregroundColor(.primary)
            .padding(.vertical, 10)
        
    }

}

struct CopyrightRow_Previews: PreviewProvider {
    static var previews: some View {
        CopyrightRow(text: "Copyright 2020 Andrew Clynes")
    }
}
