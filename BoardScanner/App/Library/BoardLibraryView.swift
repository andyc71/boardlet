import SwiftUI

struct BoardLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: ScannerModel
    @State private var search = ""
    @State private var renaming: LibraryEntry?
    @State private var newName = ""
    @State private var deleting: LibraryEntry?

    private var filtered: [LibraryEntry] {
        model.libraryEntries.filter { search.isEmpty || $0.title.localizedStandardContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                if model.busy { ProgressView(model.status) }
                if let error = model.error { Text(error).foregroundStyle(.red).accessibilityIdentifier("libraryError") }
                Section("Your boards") {
                    if model.libraryEntries.isEmpty {
                        Text("Import a screenshot or page set to add your first board. Boards and edits save automatically on this device.")
                            .foregroundStyle(.secondary)
                    } else if filtered.isEmpty {
                        Text("No matching boards").foregroundStyle(.secondary)
                    }
                    ForEach(filtered) { entry in
                        HStack {
                            Button {
                                if model.libraryID != entry.id { model.openSaved(entry.id) }
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title).font(.headline)
                                    Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                                    if entry.id == model.libraryID { Text("Current board").font(.caption) }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("libraryBoard_\(entry.title)")
                            Menu {
                                Button("Rename") { newName = entry.title; renaming = entry }
                                Button("Duplicate") { model.duplicate(entry) }
                                Button("Delete", role: .destructive) { deleting = entry }
                            } label: { Label("Manage \(entry.title)", systemImage: "ellipsis.circle").labelStyle(.iconOnly) }
                            .accessibilityIdentifier("manageBoard_\(entry.title)")
                        }
                    }
                }
                if !model.deletedEntries.isEmpty {
                    Section("Recently deleted") {
                        ForEach(model.deletedEntries) { entry in
                            HStack {
                                Text(entry.title)
                                Spacer()
                                Button("Restore") { model.restoreDeleted(entry) }
                                    .accessibilityIdentifier("restoreBoard_\(entry.title)")
                            }
                        }
                    }
                }
            }
            .disabled(model.busy)
            .searchable(text: $search, prompt: "Find a board")
            .navigationTitle("Board library")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { await model.refreshLibrary() }
            .alert("Rename board", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
                TextField("Board name", text: $newName).accessibilityIdentifier("libraryBoardName")
                Button("Cancel", role: .cancel) { renaming = nil }
                Button("Rename") {
                    if let entry = renaming { model.rename(entry, title: newName) }
                    renaming = nil
                }.disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .confirmationDialog("Delete this board?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                Button("Delete board", role: .destructive) {
                    if let entry = deleting { model.delete(entry) }
                    deleting = nil
                }
                Button("Cancel", role: .cancel) { deleting = nil }
            } message: { Text("You can restore it from Recently deleted.") }
        }
    }
}
