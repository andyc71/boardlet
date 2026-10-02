import UIKit
import PDFKit

@MainActor
struct BoardRenderer {
    let board: Board
    let mediaURL: URL
    var credits: [String] {
        Array(Set((board.cards.compactMap(\.attribution) + [board.coverAttribution].compactMap { $0 }).map(\.exportCredit))).sorted()
    }
    var pageCount: Int { board.print.pageIndices(cardCount: board.cards.count).count + creditPages.count }
    var creditPages: [[String]] { stride(from: 0, to: credits.count, by: 8).map { Array(credits[$0..<min($0 + 8, credits.count)]) } }
    var cellSizeMM: CGSize {
        let rect = contentRect
        return CGSize(width: rect.width / Double(board.print.columns) * 25.4 / 72, height: rect.height / Double(board.print.rows) * 25.4 / 72)
    }
    private var contentRect: CGRect {
        let size = board.print.sizePoints
        let margin = 14.0
        let title = board.print.showTitle ? size.height * board.print.titleFraction : 0
        return CGRect(x: margin, y: margin + title, width: size.width - margin * 2, height: max(1, size.height - margin * 2 - title - 18))
    }
    func pdf() -> Data {
        let size = board.print.sizePoints
        let bounds = CGRect(origin: .zero, size: size)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextTitle as String: board.name, kCGPDFContextCreator as String: "Boardlet", kCGPDFContextSubject as String: credits.joined(separator: "\n")]
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        return renderer.pdfData { context in
            for (page, indices) in board.print.pageIndices(cardCount: board.cards.count).enumerated() {
                context.beginPage()
                drawPage(indices, page: page + 1, bounds: bounds)
            }
            for (page, lines) in creditPages.enumerated() {
                context.beginPage(); UIColor.white.setFill(); context.fill(bounds)
                drawText(L("Source credits"), rect: CGRect(x: 24, y: 24, width: size.width - 48, height: 50), size: 26, color: .black, bold: true)
                for (index, credit) in lines.enumerated() {
                    drawText(credit, rect: CGRect(x: 24, y: 90 + Double(index) * (size.height - 140) / 8, width: size.width - 48, height: (size.height - 140) / 8 - 8), size: 13, color: .black, bold: false)
                }
                footer(page: board.print.pageIndices(cardCount: board.cards.count).count + page + 1, bounds: bounds)
            }
        }
    }
    private func drawPage(_ indices: [Int], page: Int, bounds: CGRect) {
        let p = board.print
        UIColor.white.setFill(); UIRectFill(bounds)
        if p.showTitle {
            drawText(board.name, rect: CGRect(x: 14, y: 10, width: bounds.width - 28, height: max(1, contentRect.minY - 20)), size: 28, color: UIColor(hex: p.titleColor), bold: p.titleBold)
        }
        let size = CGSize(width: contentRect.width / Double(p.columns), height: contentRect.height / Double(p.rows))
        for (position, index) in indices.enumerated() {
            let card = board.cards[index]
            var cell = CGRect(x: contentRect.minX + Double(position % p.columns) * size.width, y: contentRect.minY + Double(position / p.columns) * size.height, width: size.width, height: size.height)
            if let ratio = p.fixedCardAspectRatio, ratio > 0 {
                let h = min(cell.height, cell.width / ratio); let w = min(cell.width, cell.height * ratio)
                cell = CGRect(x: cell.midX - w / 2, y: cell.midY - h / 2, width: w, height: h)
            }
            UIColor(hex: p.background).setFill(); UIRectFill(cell)
            let line = UIBezierPath(rect: cell.insetBy(dx: p.borderWidth / 2, dy: p.borderWidth / 2)); line.lineWidth = p.borderWidth
            UIColor(hex: p.borderColor).setStroke(); line.stroke()
            let inset = cell.width * p.marginFraction + p.borderWidth
            var picture = cell.insetBy(dx: inset, dy: inset)
            if p.showLabels {
                let labelHeight = cell.height * p.labelFraction
                let label = CGRect(x: picture.minX, y: p.labelsAbove ? picture.minY : picture.maxY - labelHeight, width: picture.width, height: labelHeight)
                drawText(card.label, rect: label, size: max(10, labelHeight * 0.6), color: UIColor(hex: p.labelColor), bold: p.labelBold)
                picture.size.height = max(1, picture.height - labelHeight - 4)
                if p.labelsAbove { picture.origin.y += labelHeight + 4 }
            }
            if let name = card.image, let image = UIImage(contentsOfFile: mediaURL.appendingPathComponent(name).path) { drawImage(image, in: picture) }
            else if let symbol = card.systemSymbol, let image = UIImage(systemName: symbol)?.withTintColor(.darkGray, renderingMode: .alwaysOriginal) { let rasterSize = CGSize(width: 512, height: 512 * image.size.height / max(1, image.size.width))
                let format = UIGraphicsImageRendererFormat(); format.scale = 1
                let raster = UIGraphicsImageRenderer(size: rasterSize, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: rasterSize)) }
                drawImage(raster, in: picture.insetBy(dx: 8, dy: 8)) }
            if p.categoryBorders, card.category != "none" {
                let line = UIBezierPath(rect: cell.insetBy(dx: p.borderWidth + p.categoryBorderWidth / 2, dy: p.borderWidth + p.categoryBorderWidth / 2))
                line.lineWidth = p.categoryBorderWidth; Self.categoryColor(card.category).setStroke(); line.stroke()
            }
        }
        footer(page: page, bounds: bounds)
    }
    private func footer(page: Int, bounds: CGRect) {
        let text = "\(page) / \(pageCount)" + (credits.isEmpty ? "" : " · " + L("Source credits included"))
        drawText(text, rect: CGRect(x: 14, y: bounds.height - 26, width: bounds.width - 28, height: 18), size: 9, color: .darkGray, bold: false)
    }
    private func drawImage(_ image: UIImage, in rect: CGRect) {
        guard image.size.width > 0, image.size.height > 0 else { return }
        let scale = min(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height))
    }
    private func drawText(_ string: String, rect: CGRect, size: Double, color: UIColor, bold: Bool) {
        guard !string.isEmpty, rect.width > 0, rect.height > 0 else { return }
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center; paragraph.lineBreakMode = .byWordWrapping
        var fontSize = size
        var attributes: [NSAttributedString.Key: Any] = [:]
        while fontSize >= 2 {
            attributes = [.font: bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize), .foregroundColor: color, .paragraphStyle: paragraph]
            let fit = (string as NSString).boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
            if fit.height <= rect.height { break }; fontSize -= 0.5
        }
        (string as NSString).draw(in: rect, withAttributes: attributes)
    }
    static func categoryColor(_ key: String) -> UIColor {
        switch key { case "noun": .orange; case "pronoun": .yellow; case "adjective": .blue; case "verb": .green; case "conjunction": .white; case "preposition": .systemPink; case "question": .purple; case "adverb": .brown; case "important": .red; case "determiner": .gray; default: .clear }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0; Scanner(string: clean).scanHexInt64(&value)
        if clean.count == 8 { self.init(red: Double((value >> 24) & 255) / 255, green: Double((value >> 16) & 255) / 255, blue: Double((value >> 8) & 255) / 255, alpha: Double(value & 255) / 255) }
        else { self.init(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, alpha: 1) }
    }
}
