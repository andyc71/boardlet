import SwiftUI

struct NewBoardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var rows = 3
    @State private var columns = 3
    @State private var starter = true
    let create: (String, Int, Int, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Board name", text: $title).accessibilityIdentifier("newBoardName")
                Section("Grid") {
                    Stepper("Rows: \(rows)", value: $rows, in: 1...12).accessibilityIdentifier("newBoardRows")
                    Stepper("Columns: \(columns)", value: $columns, in: 1...12).accessibilityIdentifier("newBoardColumns")
                }
                Section {
                    Toggle("Start with common words", isOn: $starter).accessibilityIdentifier("starterWords")
                    Text("Add up to nine editable buttons for Yes, No, I want, More, Help, Stop, Water, Eat and Toilet. Turn this off to start with an empty grid.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New board")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create(title, rows, columns, starter); dismiss() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("createNativeBoard")
                }
            }
        }
    }
}
