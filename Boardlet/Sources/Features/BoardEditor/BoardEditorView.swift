import SwiftUI

struct BoardEditorView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dynamicTypeSize) private var typeSize
    let boardID: UUID
    @Binding var controls: Bool
    @State private var add = false
    @State private var labels = false
    @State private var use = false
    @State private var printBoard = false
    @State private var selecting = false
    @State private var selected = Set<UUID>()
    @State private var cardID: UUID?
    @State private var copyTo = false
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
                                Text("Choose a symbol, a photo or your camera. You can add labels and recordings later.").foregroundStyle(.secondary)
                                Button { add = true } label: { Label("Add cards", systemImage: "plus") }.buttonStyle(.borderedProminent)
                            }.padding(.vertical)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 260 : 155))], spacing: 16) {
                            ForEach(board.cards) { card in
                                VStack(spacing: 0) {
                                    Button {
                                        if selecting { if selected.contains(card.id) { selected.remove(card.id) } else { selected.insert(card.id) } }
                                        else { cardID = card.id }
                                    } label: { CardTile(card: card, mediaURL: store.mediaURL, selected: selected.contains(card.id), labelsAbove: board.print.labelsAbove) }
                                        .buttonStyle(.plain).accessibilityIdentifier("editCard-" + card.id.uuidString)
                                    if !selecting {
                                        Menu {
                                            Button("Edit card") { cardID = card.id }
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
                        Button { use = true } label: { Label("Use", systemImage: "speaker.wave.2") }.accessibilityIdentifier("useBoard")
                        Button { printBoard = true } label: { Label("Print and share", systemImage: "printer") }.accessibilityIdentifier("printBoard")
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button { add = true } label: { Label("Add", systemImage: "plus") }.accessibilityIdentifier("addCards")
                        Spacer()
                        Menu {
                            Button("Board controls") { controls = true }
                            Button("Edit all labels") { labels = true }
                            Button(selecting ? "Done selecting" : "Select cards") { selecting.toggle(); selected = [] }
                            if selecting {
                                Button("Select all") { selected = Set(board.cards.map(\.id)) }
                                Button("Duplicate selection") { store.edit(boardID) { $0.cards.append(contentsOf: board.cards.filter { selected.contains($0.id) }.map { $0.duplicate() }) }; selected = [] }
                                Button("Copy to another board") { copyTo = true }.disabled(selected.isEmpty)
                                Button("Remove selection", role: .destructive) { store.edit(boardID) { $0.cards.removeAll { selected.contains($0.id) } }; selected = [] }
                            }
                        } label: { Label(selecting ? "\(selected.count) selected" : L("Board"), systemImage: "slider.horizontal.3") }.accessibilityIdentifier("boardControls")
                        Spacer()
                        Button { store.undo(boardID) } label: { Label("Undo", systemImage: "arrow.uturn.backward") }.disabled(!store.canUndo(boardID))
                        Button { store.redo(boardID) } label: { Label("Redo", systemImage: "arrow.uturn.forward") }.disabled(!store.canRedo(boardID))
                    }
                }
                .sheet(isPresented: $add) { AddCardsView { cards in store.edit(boardID) { $0.cards.append(contentsOf: cards) } } }
                .sheet(isPresented: $labels) { BulkLabelsView(boardID: boardID) }
                .sheet(isPresented: $copyTo) { CopyCardsView(source: boardID, selection: selected) }
                .fullScreenCover(isPresented: $use) { CommunicationView(board: board, mediaURL: store.mediaURL) }
                .sheet(isPresented: $printBoard) { PrintExportView(boardID: boardID) }
                .navigationDestination(isPresented: Binding(get: { cardID != nil }, set: { if !$0 { cardID = nil } })) {
                    if let cardID { CardDetailsView(boardID: boardID, cardID: cardID) }
                }
            } else { Text("Choose a board").foregroundStyle(.secondary) }
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
