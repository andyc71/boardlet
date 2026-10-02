import SwiftUI

struct NewBoardView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool
    @State private var name = ""
    @State private var template: BoardTemplate = .blank
    let created: (UUID) -> Void
    var body: some View {
        NavigationStack {
            Form {
                Section("Board name") { TextField("New board", text: $name).accessibilityIdentifier("boardName").focused($nameFocused).submitLabel(.done).onSubmit { nameFocused = false } }
                Section("Start with") {
                    ForEach(BoardTemplate.allCases) { item in
                        Button { nameFocused = false; template = item } label: {
                            HStack { Label(L(item.rawValue), systemImage: item.symbol); Spacer(); if template == item { Image(systemName: "checkmark.circle.fill") } }.frame(minHeight: 44)
                        }.foregroundStyle(.primary).buttonStyle(.plain).accessibilityAddTraits(template == item ? .isSelected : []).accessibilityIdentifier("template-" + item.id).accessibilityValue(template == item ? L("Selected") : "")
                    }
                }
                Section { Text("You can change the pictures, labels and layout at any time.").foregroundStyle(.secondary) }
            }.navigationTitle("New board")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") { let id = store.create(name: name, template: template); dismiss(); created(id) }.accessibilityIdentifier("createBoard")
                    }
                }
        }
    }
}

struct RenameBoardView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    let board: Board
    @State private var name: String
    init(board: Board) { self.board = board; self.name = board.name }
    var body: some View {
        NavigationStack {
            Form { TextField("Board name", text: $name) }.navigationTitle("Rename")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { store.edit(board.id) { $0.name = name }; dismiss() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                }
        }
    }
}

struct DeletedBoardsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section { Text("Deleted boards stay here until you restore them. Their pictures and recordings are kept.") }
                ForEach(store.library.boards.filter { $0.deletedAt != nil }) { board in
                    HStack { Text(board.name); Spacer(); Button("Restore") { store.edit(board.id) { $0.deletedAt = nil } } }
                }
            }.navigationTitle("Recently deleted").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
