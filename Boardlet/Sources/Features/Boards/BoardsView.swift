import SwiftUI

struct BoardsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selection: UUID?
    @State private var query = ""
    @State private var showNew = false
    @State private var showSettings = false
    @State private var rename: Board?
    @State private var showTrash = false
    @State private var showControls = false
    var body: some View {
        NavigationSplitView {
            Group {
                if store.loadFailed {
                    VStack(spacing: 20) {
                        Label("Your library needs attention", systemImage: "exclamationmark.triangle").font(.title2)
                        Text(store.error ?? L("The library could not be read."))
                        Button("Retry") { Task { await store.load() } }
                        Button("Restore previous save") { Task { await store.restore() } }
                    }.padding()
                } else if !store.loaded {
                    ProgressView("Opening your boards…")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            if store.boards.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Image(systemName: "square.grid.2x2").font(.largeTitle).foregroundStyle(.blue)
                                    Text("A place for your words").font(.title2).bold()
                                    Text("Create a board with pictures, labels and a voice. Your boards stay on this device.").foregroundStyle(.secondary)
                                    Button { showNew = true } label: { Label("New board", systemImage: "plus") }.buttonStyle(.borderedProminent)
                                }.padding(.vertical)
                            }
                            ForEach([true, false], id: \.self) { pinned in
                                let boards = store.boards.filter { $0.pinned == pinned && (query.isEmpty || $0.name.localizedStandardContains(query)) }
                                if !boards.isEmpty {
                                    Text(pinned ? "Pinned" : "All boards").font(.headline).foregroundStyle(.secondary)
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 260 : 180))], spacing: 16) {
                                        ForEach(boards) { board in
                                            BoardPreview(board: board, selected: selection == board.id, open: { selection = board.id }, rename: { rename = board })
                                        }
                                    }
                                }
                            }
                            if !query.isEmpty && !store.boards.contains(where: { $0.name.localizedStandardContains(query) }) { Text("No matching boards").foregroundStyle(.secondary) }
                        }.padding()
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 400, max: 520)
            .navigationTitle("Boards")
            .searchable(text: $query, prompt: "Search boards")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { showSettings = true } label: { Label("Settings", systemImage: "gearshape") } }
                ToolbarItem(placement: .topBarTrailing) { Button { showTrash = true } label: { Label("Recently deleted", systemImage: "trash") } }
                ToolbarItem(placement: .bottomBar) { Button { showNew = true } label: { Label("New board", systemImage: "plus") }.disabled(!store.loaded).accessibilityIdentifier("newBoard") }
            }
            .navigationDestination(isPresented: Binding(get: { selection != nil && sizeClass == .compact }, set: { if !$0 && sizeClass == .compact { selection = nil } })) { if let selection { BoardEditorView(boardID: selection, controls: $showControls) } }
        } detail: {
            NavigationStack {
                if let selection { BoardEditorView(boardID: selection, controls: $showControls).id(selection) }
                else { VStack(spacing: 16) { Image(systemName: "square.grid.2x2").font(.largeTitle).foregroundStyle(.blue); Text("Choose a board").font(.title2); Text("Or create a new one to get started.").foregroundStyle(.secondary) } }
            }
        }
        .boardInspector(isPresented: $showControls) { NavigationStack { if let selection { BoardControlsView(boardID: selection) { showControls = false } } } }
        .sheet(isPresented: $showNew) { NewBoardView { selection = $0 } }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(item: $rename) { RenameBoardView(board: $0) }
        .sheet(isPresented: $showTrash) { DeletedBoardsView() }
        .alert("Boardlet", isPresented: Binding(get: { store.error != nil && !store.loadFailed }, set: { if !$0 { store.error = nil } })) {
            Button("Retry save") { store.retrySave() }
            Button("Close", role: .cancel) { }
        } message: { Text(store.error ?? "") }
    }
}

struct BoardPreview: View {
    @EnvironmentObject private var store: BoardStore
    let board: Board
    let selected: Bool
    let open: () -> Void
    let rename: () -> Void
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: open) {
                VStack(alignment: .leading) {
                    if let cover = board.cover {
                        CardArtwork(card: Card(label: board.name, image: cover), mediaURL: store.mediaURL).frame(height: 110).frame(maxWidth: .infinity)
                    } else {
                        HStack { ForEach(board.cards.prefix(3)) { card in CardArtwork(card: card, mediaURL: store.mediaURL).frame(height: 84) } }
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .overlay { if board.cards.isEmpty { Image(systemName: "square.dashed").font(.largeTitle).foregroundStyle(.secondary) } }
                    }
                    Text(board.name).font(.headline).multilineTextAlignment(.leading)
                    Text("\(board.cards.count) cards").font(.subheadline).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityIdentifier("board-" + board.name)
            Menu {
                Button("Open", action: open)
                Button("Rename", action: rename)
                Button(board.pinned ? "Unpin" : "Pin") { store.edit(board.id) { $0.pinned.toggle() } }
                Button("Move earlier") { store.moveBoard(board.id, offset: -1) }
                Button("Move later") { store.moveBoard(board.id, offset: 1) }
                Button("Duplicate") { store.duplicate(board.id) }
                Button("Move to Recently deleted", role: .destructive) { store.edit(board.id) { $0.deletedAt = Date() } }
            } label: { Label("Board actions", systemImage: "ellipsis.circle").font(.subheadline).frame(minHeight: 44) }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(selected ? Color.blue : .secondary.opacity(0.2), lineWidth: selected ? 2 : 1) }
    }
}
