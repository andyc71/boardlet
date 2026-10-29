import SwiftUI

struct MessageTokenEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    let token: CommunicationToken
    let save: (UUID, String) -> Void

    init(token: CommunicationToken, save: @escaping (UUID, String) -> Void) {
        self.token = token
        self.save = save
        _text = State(initialValue: token.text)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let data = token.imagePNG, let image = UIImage(data: data) {
                    ArtworkImage(image: image).frame(maxHeight: 100).accessibilityHidden(true)
                }
                TextField("Words", text: $text, axis: .vertical)
                    .lineLimit(2...8).accessibilityIdentifier("correctedWords")
                Button("Clear words") { text = "" }.accessibilityIdentifier("clearCorrectedWords")
                Text("This changes the current message. The board button stays the same.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Edit words")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { save(token.id, text); dismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("applyCorrectedWords")
                }
            }
        }
    }
}
