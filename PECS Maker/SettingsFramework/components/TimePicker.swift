//
//  TimePicker.swift
//
//  Created by Andy Clynes on 4/11/2020.
//
import SwiftUI
import Combine

struct TimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    let hourScale: Int = 15
    let minuteScale: Int = 6
    
    var body: some View {

        // Pickers
        HStack() {
            // Hour
            Picker("", selection: $hour) {
                ForEach(0..<24) {
                    Text(String(format: "%02d", $0))
                        .font(.title3)
                }
            }
            //.labelsHidden()
            .pickerStyle(WheelPickerStyle())
            //.frame(maxWidth:40, maxHeight: 40)

            // Separator
            Text(":")
                .font(.title3)
                .padding(.bottom, 5)

            // Minute
            Picker("", selection: $minute) {
                ForEach(0..<60) {
                    Text(String(format: "%02d", $0))
                        .font(.title3)
                }
            }
            .labelsHidden()
            .pickerStyle(WheelPickerStyle())
            //.frame(maxWidth: 40, maxHeight: 40)
        }
    }
}

#if DEBUG
struct TimePicker_PreviewHelper: View {
    @State private var hour: Int = 9
    @State private var minute: Int = 41

    var body: some View {
        TimePicker(hour: $hour, minute: $minute)
    }
}

struct TimePicker_Previews: PreviewProvider {
    static var previews: some View {
        TimePicker_PreviewHelper()
    }
}
#endif
