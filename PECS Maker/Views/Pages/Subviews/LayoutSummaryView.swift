//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct LayoutSummaryView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    var body: some View {
        
        SimpleCard(title: L10n.LayoutSummaryView.title) {
            
            VStack(alignment: .leading) {
                Text(L10n.LayoutSummaryView.pageMeasurements).font(.headline)
                Text("\(pageLayoutState.pageMeasurements2.formatAs(measurementType: .mm))")
                Text("\(pageLayoutState.pageMeasurements2.formatAs(measurementType: .inches))")
            }
            .padding(.bottom)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(L10n.LayoutSummaryView.cardCount).font(.headline)
                    Text("\(pageLayoutState.pageLayout.total)")
                }
                HStack {
                    Text(L10n.LayoutSummaryView.cardsAcrossAndDown(pageLayoutState.pageLayout.width, pageLayoutState.pageLayout.height))
                }
                #if DEBUG
                    HStack {
                        Text(L10n.LayoutSummaryView.aspectRatio)
                        Text("\(pageLayoutState.individualCardMeasurements.formatAs(measurementType: .aspectRatio))")
                    }
                #endif

            }
            .padding(.bottom)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading) {
                Text(L10n.LayoutSummaryView.cardSizeTitle).font(.headline)
                Text("\(pageLayoutState.individualCardMeasurements.formatAs(measurementType: .mm))")
                Text("\(pageLayoutState.individualCardMeasurements.formatAs(measurementType: .inches))")
                //Text("\(pageLayoutState.pageMeasurements2.formatAs(measurementType: .inches))")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            //Text("Each PECS card measures: \(pageLayoutState.individualCardMeasurements.metricAndImperialFormat)")
        }
    }
}

//struct LayoutView_Previews: PreviewProvider {
//    static var previews: some View {
//        LayoutView(cols: 2, rows: 3, isSelected: false, aspectRatio: 0.7)
//    }
//}
