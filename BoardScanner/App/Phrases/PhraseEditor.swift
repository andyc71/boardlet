import SwiftUI

struct PhraseEditor: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var phrase: SavedPhrase
  @State private var error: String?
  let save: (SavedPhrase) -> String?

  init(phrase: SavedPhrase, save: @escaping (SavedPhrase) -> String?) {
    _phrase = State(initialValue: phrase)
    self.save = save
  }

  var body: some View {
    NavigationStack {
      Form {
        TextField("Name (optional)", text: $phrase.title).accessibilityIdentifier("phraseTitle")
        TextField("Message", text: $phrase.text, axis: .vertical)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2...3 : 3...10)
          .accessibilityIdentifier("phraseText")
        Text("Phrases save as text and are available from every board on this device.")
          .font(.footnote).foregroundStyle(.secondary)
        if let error { Text(error).foregroundStyle(.red) }
      }
      .navigationTitle("Save phrase")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            error = save(phrase)
            if error == nil { dismiss() }
          }
          .disabled(phrase.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          .accessibilityIdentifier("savePhrase")
        }
      }
    }
  }
}
