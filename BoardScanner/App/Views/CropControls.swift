import SwiftUI

struct CropControls: View {
    @Binding var left: Double
    @Binding var top: Double
    @Binding var right: Double
    @Binding var bottom: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text("Left: \(left, format: .percent.precision(.fractionLength(0)))")
            Slider(value: $left, in: 0...max(0.01, 0.95 - right)).accessibilityLabel("Crop left")
            Text("Right: \(right, format: .percent.precision(.fractionLength(0)))")
            Slider(value: $right, in: 0...max(0.01, 0.95 - left)).accessibilityLabel("Crop right")
            Text("Top: \(top, format: .percent.precision(.fractionLength(0)))")
            Slider(value: $top, in: 0...max(0.01, 0.95 - bottom)).accessibilityLabel("Crop top")
            Text("Bottom: \(bottom, format: .percent.precision(.fractionLength(0)))")
            Slider(value: $bottom, in: 0...max(0.01, 0.95 - top)).accessibilityLabel("Crop bottom")
        }.font(.subheadline)
    }
}
