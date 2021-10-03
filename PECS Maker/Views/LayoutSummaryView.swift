//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI

struct LayoutSummaryView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    var body: some View {
        VStack {
            
            SelectionHeading(text: "Summary")
            
            VStack(alignment: .leading) {
                //Text("Page measurements: \(pageLayoutState.pageMeasurements.metricAndImperialFormat)")
                //Text("Each PECS card measures: \(pageLayoutState.individualCardMeasurements.metricAndImperialFormat)")
                VStack(alignment: .leading) {
                    Text("Page measurements:").font(.headline)
                    Text("\(pageLayoutState.pageMeasurements.formatAs(measurementType: .mm))")
                    Text("\(pageLayoutState.pageMeasurements.formatAs(measurementType: .inches))")
                }
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading) {
                    Text("Each PECS card measures:").font(.headline)
                    Text("\(pageLayoutState.individualCardMeasurements.formatAs(measurementType: .mm))")
                    Text("\(pageLayoutState.individualCardMeasurements.formatAs(measurementType: .inches))")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                //Text("Each PECS card measures: \(pageLayoutState.individualCardMeasurements.metricAndImperialFormat)")
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(ColorNames.lightBlue))
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            
            Spacer()
            
        }
    }
    
    
}

//struct LayoutView_Previews: PreviewProvider {
//    static var previews: some View {
//        LayoutView(cols: 2, rows: 3, isSelected: false, aspectRatio: 0.7)
//    }
//}
