import SwiftUI

struct CropView: View {
    @Environment(\.dismiss) private var dismiss
    let data: Data
    let completion: (Data) -> Void
    @State private var x = 0.0
    @State private var y = 0.0
    @State private var width = 1.0
    @State private var height = 1.0
    @State private var preview: Data?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                if let image = UIImage(data: preview ?? data) { Image(uiImage: image).resizable().scaledToFit().frame(height: 240).frame(maxWidth: .infinity) }
                Section("Crop area") {
                    Slider(value: $x, in: 0...0.8) { Text("Left") }; Text("Left: \(Int(x * 100))%")
                    Slider(value: $y, in: 0...0.8) { Text("Top") }; Text("Top: \(Int(y * 100))%")
                    Slider(value: $width, in: 0.2...1) { Text("Width") }; Text("Width: \(Int(width * 100))%")
                    Slider(value: $height, in: 0.2...1) { Text("Height") }; Text("Height: \(Int(height * 100))%")
                }
                Text("The original picture is kept. Use Restore original picture to undo image changes.").font(.footnote)
                if let error { Text(error).foregroundStyle(.red) }
            }.navigationTitle("Crop picture")
                .task(id: [x, y, width, height]) {
                    do { preview = try await ImageEditor().crop(data, x: x, y: y, width: width, height: height) } catch { self.error = error.localizedDescription }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Apply") { completion(preview ?? data); dismiss() } }
                }
        }
    }
}
