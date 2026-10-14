import SwiftUI

struct BoardEditorView: View {
    struct EditorState {
        var add = false
        var labels = false
        var use = false
        var printBoard = false
        var selecting = false
        var selected = Set<UUID>()
        var cardID: UUID?
        var copyTo = false
    }

    @EnvironmentObject private var store: BoardStore
    @Environment(\.dynamicTypeSize) private var typeSize
    let boardID: UUID
    @Binding var controls: Bool
    @Binding var state: EditorState
    var body: some View {
        Group {
            if let board = store.board(boardID), board.deletedAt == nil {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        BoardSaveStatus(name: board.name, count: board.cards.count, saving: store.saving, failed: store.error != nil)
                        if board.cards.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled").font(.largeTitle).foregroundStyle(.blue)
                                Text("Add your first card").font(.title2).bold()
                                #if BOARDLET_PLUS
                                Text("Choose a symbol, a photo or your camera. You can add labels and recordings later.").foregroundStyle(.secondary)
                                #else
                                Text("Choose a symbol, a photo or your camera. You can add labels later.").foregroundStyle(.secondary)
                                #endif
                                Button { state.add = true } label: { Label("Add cards", systemImage: "plus") }.buttonStyle(.borderedProminent)
                            }.padding(.vertical)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 260 : 155))], spacing: 16) {
                            ForEach(board.cards) { card in
                                VStack(spacing: 0) {
                                    Button {
                                        if state.selecting { if state.selected.contains(card.id) { state.selected.remove(card.id) } else { state.selected.insert(card.id) } }
                                        else { state.cardID = card.id }
                                    } label: { CardTile(card: card, mediaURL: store.mediaURL, selected: state.selected.contains(card.id), labelsAbove: board.print.labelsAbove) }
                                        .buttonStyle(.plain).accessibilityIdentifier("editCard-" + card.id.uuidString)
                                    if !state.selecting {
                                        Menu {
                                            Button("Edit card") { state.cardID = card.id }
                                            Button("Move earlier") { store.moveCard(card.id, board: boardID, offset: -1) }
                                            Button("Move later") { store.moveCard(card.id, board: boardID, offset: 1) }
                                            Button("Duplicate") { store.edit(boardID) { $0.cards.append(card.duplicate()) } }
                                            Button("Use as cover") { store.edit(boardID) { $0.cover = card.image; $0.coverAttribution = card.attribution } }
                                            Button("Remove", role: .destructive) { store.edit(boardID) { $0.cards.removeAll { $0.id == card.id } } }
                                        } label: { Label("Card actions", systemImage: "ellipsis.circle").font(.caption).frame(minHeight: 44) }
                                    }
                                }
                            }
                        }
                    }.padding()
                }
                .navigationTitle(board.name).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        #if BOARDLET_PLUS
                        Button { state.use = true } label: { Label("Use", systemImage: "speaker.wave.2") }.accessibilityIdentifier("useBoard")
                        #endif
                        Button { state.printBoard = true } label: { Label("Print and share", systemImage: "printer") }.accessibilityIdentifier("printBoard")
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button { state.add = true } label: { Label("Add", systemImage: "plus") }.accessibilityIdentifier("addCards")
                        Button { store.undo(boardID) } label: { Label("Undo", systemImage: "arrow.uturn.backward") }.disabled(!store.canUndo(boardID))
                        Button { store.redo(boardID) } label: { Label("Redo", systemImage: "arrow.uturn.forward") }.disabled(!store.canRedo(boardID))
                    }
                    if #available(iOS 27.0, *) {
                        ToolbarOverflowMenu {
                            boardControlActions(board)
                        }
                    } else {
                        ToolbarItem(placement: .bottomBar) {
                        Menu {
                            boardControlActions(board)
                        } label: { Label(state.selecting ? "\(state.selected.count) selected" : L("Board"), systemImage: "slider.horizontal.3") }.accessibilityIdentifier("boardControls")
                        }
                    }
                }
                .sheet(isPresented: $state.add) { AddCardsView { cards in store.edit(boardID) { $0.cards.append(contentsOf: cards) } } }
                .sheet(isPresented: $state.labels) { BulkLabelsView(boardID: boardID) }
                .sheet(isPresented: $state.copyTo) { CopyCardsView(source: boardID, selection: state.selected) }
                #if BOARDLET_PLUS
                .fullScreenCover(isPresented: $state.use) { CommunicationView(board: board, mediaURL: store.mediaURL) }
                #endif
                .sheet(isPresented: $state.printBoard) { PrintExportView(boardID: boardID) }
                .navigationDestination(isPresented: Binding(get: { state.cardID != nil }, set: { if !$0 { state.cardID = nil } })) {
                    if let cardID = state.cardID { CardDetailsView(boardID: boardID, cardID: cardID) }
                }
            } else { Text("Choose a board").foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder
    private func boardControlActions(_ board: Board) -> some View {
        Button("Board controls", systemImage: "slider.horizontal.3") { controls = true }
        Button("Edit all labels", systemImage: "textformat") { state.labels = true }
        Button(state.selecting ? "Done" : "Select") {
            state.selecting.toggle()
            state.selected = []
        }
        if state.selecting {
            let allSelected = !board.cards.isEmpty && board.cards.allSatisfy { state.selected.contains($0.id) }
            Button(allSelected ? "Deselect all" : "Select all") {
                state.selected = allSelected ? [] : Set(board.cards.map(\.id))
            }
            Button("Duplicate selection", systemImage: "plus.square.on.square") {
                store.edit(boardID) {
                    $0.cards.append(contentsOf: board.cards.filter { state.selected.contains($0.id) }
                        .map { $0.duplicate() })
                }
                state.selected = []
            }
            Button("Copy to another board", systemImage: "rectangle.on.rectangle") {
                state.copyTo = true
            }
            .disabled(state.selected.isEmpty)
            Button("Remove selection", systemImage: "trash", role: .destructive) {
                store.edit(boardID) { $0.cards.removeAll { state.selected.contains($0.id) } }
                state.selected = []
            }
        }
    }
}

struct BoardSaveStatus: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let name: String
    let count: Int
    let saving: Bool
    let failed: Bool
    var body: some View {
        VStack(alignment: .leading) {
            if typeSize.isAccessibilitySize { Text(name).font(.title2).bold() }
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading) { Text("\(count) cards").foregroundStyle(.secondary); SaveStatusLabel(saving: saving, failed: failed) }
            } else {
                HStack { Text("\(count) cards").foregroundStyle(.secondary); Spacer(); SaveStatusLabel(saving: saving, failed: failed) }
            }
        }
    }
}
struct SaveStatusLabel: View {
    let saving: Bool
    let failed: Bool
    var body: some View {
        Label(saving ? L("Saving…") : failed ? L("Not saved") : L("Saved"), systemImage: saving ? "arrow.triangle.2.circlepath" : failed ? "exclamationmark.triangle" : "checkmark.circle").font(.caption)
    }
}
