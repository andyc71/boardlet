import SwiftUI

struct CardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var card: ScannedCard
    @State private var message: String
    @State private var left: Double
    @State private var top: Double
    @State private var right: Double
    @State private var bottom: Double
    let source: Data
    let save: (ScannedCard) -> Void

    init(card: ScannedCard, source: Data, save: @escaping (ScannedCard) -> Void) {
        _card = State(initialValue: card)
        _message = State(initialValue: card.message ?? "")
        _left = State(initialValue: (card.pictureBounds.minX - card.bounds.minX) / card.bounds.width)
        _right = State(initialValue: (card.bounds.maxX - card.pictureBounds.maxX) / card.bounds.width)
        _top = State(initialValue: (card.pictureBounds.minY - card.bounds.minY) / card.bounds.height)
        _bottom = State(initialValue: (card.bounds.maxY - card.pictureBounds.maxY) / card.bounds.height)
        self.source = source
        self.save = save
    }

    private var picture: CGRect {
        CGRect(x: card.bounds.minX + left * card.bounds.width, y: card.bounds.minY + top * card.bounds.height,
               width: card.bounds.width * (1 - left - right), height: card.bounds.height * (1 - top - bottom))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card label") {
                    HStack {
                        TextField("Label", text: $card.label, axis: .vertical).accessibilityIdentifier("cardLabel")
                        Button { card.label = "" } label: { Label("Clear label", systemImage: "xmark.circle.fill").labelStyle(.iconOnly) }
                            .buttonStyle(.borderless)
                    }
                    TextField("Spoken message (uses label when empty)", text: $message, axis: .vertical)
                        .accessibilityIdentifier("cardMessage")
                    Text("OCR confidence: \(Double(card.confidence), format: .percent.precision(.fractionLength(0)))")
                        .font(.caption).foregroundStyle(.secondary)
                    Toggle("Include this card", isOn: $card.included)
                }
                Section("Picture crop") {
                    DetectionPreview(source: source, cells: [card.bounds], pictures: [picture])
                    Text("Keep the green area around the picture only. Remove the original printed label using the crop controls.")
                        .font(.footnote).foregroundStyle(.secondary)
                    CropControls(left: $left, top: $top, right: $right, bottom: $bottom)
                }
            }
            .navigationTitle("Review card").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        card.pictureBounds = picture
                        card.message = message.isEmpty ? nil : message
                        save(card)
                        dismiss()
                    }.accessibilityIdentifier("saveCard")
                }
            }
        }
    }
}
