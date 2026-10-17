//
//  AdaptiveToolbarLabel.swift
//  PECS Maker
//
//  Created by Andy on 15/10/2026.
//
import SwiftUI

struct AdaptiveToolbarLabel: View {

    let title: String
    let systemImage: String
    let verticalLayout: Bool

    var body: some View {
        let layout = verticalLayout
            ? AnyLayout(VStackLayout())
            : AnyLayout(HStackLayout())

        layout {
            /*
            Capsule()
                .frame(width: 24, height: width)
            Text("\(width, format: .number) pt")
             */
            Image(systemName: systemImage)
            Text(title)
                .font(.caption)
        }
    }
}
