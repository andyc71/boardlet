import UIKit

/// A deliberately synthetic, locally generated screenshot; also exercises the real Vision pipeline.
@MainActor
enum SampleBoard {
    static let labels = ["Water", "Apple", "Play", "Book", "Music", "Help"]

    static func image(topLabels: Bool = false, gaps: Bool = false) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 900, height: 760), format: format).image { renderer in
            UIColor.white.setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: 900, height: 760))
            ("My choices" as NSString).draw(at: CGPoint(x: 45, y: 20), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 36), .foregroundColor: UIColor.black
            ])
            let symbols = ["drop.fill", "apple.logo", "figure.play", "book.fill", "music.note", "hand.raised.fill"]
            let colors: [UIColor] = [.systemBlue, .systemRed, .systemGreen, .systemOrange, .systemPurple, .systemTeal]
            for index in 0..<6 {
                let rect = CGRect(x: 45 + (index % 3) * 270, y: 100 + (index / 3) * 300, width: 270, height: 300)
                    .insetBy(dx: gaps ? 9 : 0, dy: gaps ? 9 : 0)
                UIColor.black.setStroke()
                let path = UIBezierPath(rect: rect)
                path.lineWidth = 4
                path.stroke()
                let symbolY = topLabels ? rect.minY + 95 : rect.minY + 35
                UIImage(systemName: symbols[index])?.withTintColor(colors[index], renderingMode: .alwaysOriginal)
                    .draw(in: CGRect(x: rect.midX - 65, y: symbolY, width: 130, height: 130))
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                (labels[index] as NSString).draw(in: CGRect(x: rect.minX + 8, y: topLabels ? rect.minY + 20 : rect.maxY - 65,
                                                          width: rect.width - 16, height: 50), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 32), .foregroundColor: UIColor.black, .paragraphStyle: style
                ])
            }
        }
    }
}
