import SwiftUI

struct DetectionPreview: View {
    let source: Data
    let cells: [CGRect]
    let pictures: [CGRect]

    var body: some View {
        if let image = UIImage(data: source) {
            Image(uiImage: image).resizable().scaledToFit()
                .overlay {
                    Canvas { context, size in
                        for (rectangles, color) in [(cells, Color.blue), (pictures, Color.green)] {
                            for rect in rectangles {
                                let displayed = CGRect(x: rect.minX * size.width, y: rect.minY * size.height,
                                                       width: rect.width * size.width, height: rect.height * size.height)
                                context.stroke(Path(displayed), with: .color(color), lineWidth: 2)
                            }
                        }
                    }
                }
                .accessibilityLabel("Source screenshot with \(cells.count) detected card boundaries and \(pictures.count) picture crops")
                .accessibilityIdentifier("detectionPreview")
        }
    }
}
