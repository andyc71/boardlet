import SwiftUI
import BoardLibrary
import PersistenceFramework
import ImageIO
import UniformTypeIdentifiers

struct BoardSummaryCell: View {
    let summary: BoardSummary
    var size: CGSize?
    var isSelected = false
    @State private var cover: UIImage?
    var body: some View {
        ImageTitleCard(image: cover ?? UIImage(systemName: "square.grid.2x2")!, title: summary.title,
                       squareImage: size == nil, size: size, isSelected: isSelected)
            .task(id: summary.relativePath + "|" + summary.fingerprint + "|" + (summary.cover ?? "")) {
                cover = nil
                guard let path = summary.cover else { return }
                let root = RepoHelper.documentsDirectory.appendingPathComponent("topics").appendingPathComponent(summary.relativePath)
                cover = await BoardCoverCache.shared.image(root: root, path: path, revision: summary.fingerprint)
            }
    }
}

struct BoardSearchView: View {
    @ObservedObject var factory = PECSRepoFactory.shared
    var scope: UUID?
    var onOpen: (PECSRepo, UUID?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var allLanguages = false
    @State private var subtree = true
    @State private var results: [LibrarySearchResult] = []
    @State private var error: String?
    @State private var more = false
    @State private var isSearching = false
    private var request: String { query + "|\(allLanguages)|\(subtree)" }
    var body: some View {
        NavigationStack {
            List {
                if factory.isIndexing { Label("Indexing — results may be incomplete", systemImage: "clock") }
                else if !factory.isIndexComplete { Label("Index incomplete — some boards are unavailable", systemImage: "exclamationmark.triangle") }
                if let error { Text(error) }
                Toggle("All languages", isOn: $allLanguages)
                if scope != nil { Toggle("This board and children", isOn: $subtree) }
                ForEach(results) { result in
                    Button {
                        do {
                            guard let summary = factory.allBoards.first(where: { $0.id == result.boardID }) else { throw LibraryError.invalid("Board is no longer available") }
                            let repo = try factory.open(summary)
                            if let card = result.cardID, !repo.photos.photoItems.contains(where: { $0.itemID == card }) { factory.refresh(); throw LibraryError.invalid("Card is no longer available") }
                            onOpen(repo,result.cardID); dismiss()
                        } catch { self.error = error.localizedDescription }
                    } label: {
                        BoardSearchResultLabel(result: result)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("BoardSearch.result." + result.id)
                }
                if more { Button("More results") { Task { await search(append: true) } }.disabled(isSearching) }
            }
            .searchable(text: $query)
            .navigationTitle("Search boards and cards")
            .safeAreaInset(edge: .bottom) { Button(L10n.doneButton) { dismiss() }.accessibilityIdentifier("BoardSearch.done").buttonStyle(.borderedProminent).padding(8) }
            .task(id: request + "|\(factory.isIndexing)") {
                do { try await Task.sleep(nanoseconds: 150_000_000); await search(append: false) } catch { }
            }
        }
    }
    @MainActor private func search(append: Bool) async {
        guard !append || !isSearching else { return }
        let generation = request
        isSearching = true
        defer { if generation == request { isSearching = false } }
        do {
            guard let store = factory.store else { return }
            let page = try await store.search(query, scope: subtree ? scope : nil, allLanguages: allLanguages, offset: append ? results.count : 0)
            guard !Task.isCancelled, generation == request else { return }
            if append { results += page } else { results = page }
            more = page.count == 40; error = nil
        } catch is CancellationError { }
        catch { if generation == request && !Task.isCancelled { self.error = error.localizedDescription } }
    }
}

private struct BoardSearchResultLabel: View {
    let result: LibrarySearchResult
    @State private var thumbnail: UIImage?
    var body: some View {
        HStack {
            Group {
                if let thumbnail { Image(uiImage: thumbnail).resizable().scaledToFit() }
                else { Image(systemName: result.cardID == nil ? "folder" : "rectangle") }
            }
            .frame(width: 48, height: 48)
            .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Label(result.title, systemImage: result.cardID == nil ? "folder" : "rectangle")
                Text(result.breadcrumb).font(.caption).foregroundStyle(.secondary)
                if result.matchedText != result.title { Text("\(result.matchedText) (\(result.language))").font(.caption) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .task(id: result.relativePath + "|" + result.fingerprint + "|" + (result.image ?? "")) {
            thumbnail = nil
            guard let path = result.image else { return }
            let root = RepoHelper.documentsDirectory.appendingPathComponent("topics").appendingPathComponent(result.relativePath)
            let image = await BoardCoverCache.shared.image(root: root, path: path, revision: result.fingerprint)
            guard !Task.isCancelled else { return }
            thumbnail = image
        }
    }
}

struct BoardHierarchyContainer<Content: View>: View {
    @ObservedObject var topic: PECSRepo
    @ObservedObject private var factory = PECSRepoFactory.shared
    @EnvironmentObject private var navigation: NavigationModel
    @State private var leading = false
    @State private var compactHeight = false
    @State private var showSearch = false
    @State private var showMove = false
    @State private var showDelete = false
    @State private var showImport = false
    @State private var showExport = false
    @State private var exportDocument: EditableBoardDocument?
    let showsLibraryActions: Bool
    let content: Content
    init(topic: PECSRepo, showsLibraryActions: Bool = true, @ViewBuilder content: () -> Content) {
        self.topic = topic
        self.showsLibraryActions = showsLibraryActions
        self.content = content()
    }
    private var children: [BoardSummary] { factory.allBoards.filter { $0.parentID == topic.id } }
    private var parent: BoardSummary? {
        guard let id = factory.allBoards.first(where: { $0.id == topic.id })?.parentID else { return nil }
        return factory.allBoards.first { $0.id == id }
    }
    var body: some View {
        let layout = compactHeight
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 8))
            : AnyLayout(VStackLayout(spacing: 0))
        layout {
            if showsLibraryActions || parent != nil {
                navigationControls
            }
            boardArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: Bool.self) { geometry in
            // Measure the stable container, not the controls or their chosen layout.
            geometry.size.width > 600 && geometry.size.height < 350
        } action: { compactHeight = $0 }
        .sheet(isPresented: $showSearch) {
            BoardSearchView(scope: topic.id) { repo, card in
                // Clear the presenting state before navigation can replace this board view.
                showSearch = false
                factory.currentTopic = repo; navigation.setTopic(repo)
                if let card { navigation.revealCard(card) }
            }
        }
        .sheet(isPresented: $showMove) {
            NavigationStack {
                List {
                    Button("Move to Home") { factory.move(topic.id,parent: nil); showMove = false }
                    ForEach(factory.allBoards.filter { $0.id != topic.id }) { destination in
                        Button(destination.title) { factory.move(topic.id,parent: destination.id); showMove = false }
                    }
                }.navigationTitle("Move board")
                .toolbar { Button(L10n.DefaultBoards.cancel) { showMove = false } }
            }
        }
        .fileImporter(isPresented: $showImport, allowedContentTypes: [.folder, .package]) { result in
            Task {
                do {
                    let url = try result.get()
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    guard let store = factory.store else { return }
                    _ = try await store.importSubtree(from:url,parent:topic.id); factory.refresh()
                } catch { ErrorHandler.shared.setLastError(error) }
            }
        }
        .fileExporter(isPresented: $showExport, document: exportDocument, contentType: .package, defaultFilename: topic.topicName) { result in
            if case .failure(let error) = result { ErrorHandler.shared.setLastError(error) }
        }
        .confirmationDialog("Delete this board and all its children?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete board and children", role: .destructive) { factory.deleteTopic(topic); navigation.showTopics() }
        }
    }
    @ViewBuilder private var navigationControls: some View {
        if compactHeight {
            VStack(alignment: .leading, spacing: 6) {
                parentAndHome
                if showsLibraryActions { boardActions }
                Spacer(minLength: 0)
            }
            .buttonStyle(.bordered)
            .padding(6)
            .frame(width: 144)
        } else {
            ViewThatFits(in: .horizontal) {
                HStack { parentAndHome; Spacer(); if showsLibraryActions { boardActions } }
                VStack(alignment: .leading, spacing: 0) {
                    HStack { parentAndHome; Spacer() }
                    if showsLibraryActions { HStack { boardActions; Spacer() } }
                }
            }.buttonStyle(.bordered).padding(6)
        }
    }
    private var boardArea: some View {
        Group {
            if children.isEmpty { content }
            else if !topic.photos.photoItems.contains(where: { !$0.isPlaceholder }) { links(horizontal: false) }
            else if leading {
                HStack(spacing: 8) { links(horizontal: false).frame(width: 144); content }
            } else {
                VStack(spacing: 8) { links(horizontal: true).frame(height: 132); content }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { newSize in
            // Compare remaining board area; retain the previous placement in a 40pt deadband.
            let sideWidth = newSize.width - 152
            let topHeight = newSize.height - 140
            let sideCard = min(sideWidth / CGFloat(max(1,topic.layout.width)), newSize.height / CGFloat(max(1,topic.layout.height)))
            let topCard = min(newSize.width / CGFloat(max(1,topic.layout.width)), topHeight / CGFloat(max(1,topic.layout.height)))
            if newSize.width > 600 && sideCard > topCard + (leading ? -10 : 10) { leading = true }
            else if newSize.width < 560 || topCard > sideCard + 10 { leading = false }
        }
    }
    @ViewBuilder private var parentAndHome: some View {
        if let parent {
            Button { open(parent) } label: { BoardParentLabel(summary: parent) }
                .accessibilityIdentifier("BoardHierarchy.parent")
        }
        if showsLibraryActions {
            Button { navigation.showTopics() } label: { Label("Home", systemImage: "house") }
                .accessibilityIdentifier("BoardHierarchy.home")
        }
    }
    @ViewBuilder private var boardActions: some View {
                Button { showSearch = true } label: { Label("Search", systemImage: "magnifyingglass") }.accessibilityIdentifier("BoardHierarchy.search")
                Menu {
                    Button("Create child board", systemImage: "folder.badge.plus") {
                        do { let child = try factory.createChild(of: topic); factory.currentTopic = child; navigation.setTopic(child) }
                        catch { ErrorHandler.shared.setLastError(error) }
                    }
                    Button("Import child board", systemImage: "square.and.arrow.down") { showImport = true }
                    Button("Export editable board", systemImage: "square.and.arrow.up") {
                        Task {
                            do {
                                try topic.saveToFile()
                                guard let store = factory.store else { return }
                                _ = try await store.reconcile()
                                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("BoardExport-\(UUID().uuidString)")
                                try await store.export(topic.id,to:directory)
                                exportDocument = try EditableBoardDocument(directory:directory)
                                try? FileManager.default.removeItem(at:directory)
                                showExport = true
                            } catch { ErrorHandler.shared.setLastError(error) }
                        }
                    }
                    Button("Move board", systemImage: "folder") { showMove = true }
                    Button("Duplicate board and children", systemImage: "doc.on.doc") { Task { do { try await factory.duplicateTopic(repo: topic) } catch { ErrorHandler.shared.setLastError(error) } } }
                    Button("Delete board and children", role: .destructive) { showDelete = true }
                } label: { Label("Organize", systemImage: "folder.badge.gearshape") }.accessibilityIdentifier("BoardHierarchy.organize")
    }
    private func open(_ summary: BoardSummary) {
        do { let repo = try factory.open(summary); factory.currentTopic = repo; navigation.setTopic(repo) }
        catch { ErrorHandler.shared.setLastError(error) }
    }
    private func links(horizontal: Bool) -> some View {
        ScrollView(horizontal ? .horizontal : .vertical) {
            Group {
                if horizontal { LazyHStack(spacing: 8) { childLinks } }
                else { LazyVStack(spacing: 8) { childLinks } }
            }.padding(4)
        }
    }
    private var childLinks: some View {
                ForEach(children) { child in
                    Button { open(child) } label: {
                        VStack {
                            BoardSummaryCell(summary: child, size: CGSize(width: 120, height: 88))
                            Image(systemName: "folder.fill.badge.plus").accessibilityHidden(true)
                        }
                        .frame(width: 120).frame(minHeight: 88)
                        .padding(8)
                        .foregroundStyle(.primary)
                        .background(Color.cyan.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.teal, lineWidth: 2))
                    }.buttonStyle(.plain)
                    .accessibilityLabel(Text("Open child board:") + Text(verbatim: " " + child.title))
                    .accessibilityIdentifier("BoardHierarchy.child.\(child.id.uuidString)")
                    .contextMenu {
                        Button("Move earlier") {
                            guard let index = children.firstIndex(where: { $0.id == child.id }), index > 0 else { return }
                            var ids = children.map(\.id); ids.swapAt(index,index-1)
                            topic.hierarchy.childOrder = ids
                            do { try topic.saveToFile() } catch { ErrorHandler.shared.setLastError(error) }
                        }
                    }
                }
    }
}

private struct BoardParentLabel: View {
    let summary: BoardSummary
    @State private var cover: UIImage?
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.up.left")
            if let cover { Image(uiImage: cover).resizable().scaledToFit().frame(width: 28, height: 28).accessibilityHidden(true) }
            Text(summary.title).lineLimit(2)
        }
        .task(id: summary.relativePath + "|" + summary.fingerprint) {
            cover = nil
            guard let path = summary.cover else { return }
            let root = RepoHelper.documentsDirectory.appendingPathComponent("topics").appendingPathComponent(summary.relativePath)
            cover = await BoardCoverCache.shared.image(root: root, path: path, revision: summary.fingerprint)
        }
    }
}

/// One background decoder with a bounded cache shared by visible navigation/list cells.
private actor BoardCoverCache {
    static let shared = BoardCoverCache()
    private let cache = NSCache<NSString, UIImage>()
    init() { cache.totalCostLimit = 16 * 1024 * 1024; cache.countLimit = 100 }
    func image(root: URL, path: String, revision: String) -> UIImage? {
        guard let url = try? DocumentPaths.owned(path, by: root) else { return nil }
        let key = (url.path + "|" + revision) as NSString
        if let image = cache.object(forKey: key) { return image }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 320, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cgImage)
        cache.setObject(image, forKey: key, cost: cgImage.bytesPerRow * cgImage.height)
        return image
    }
}

struct EditableBoardDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.package, .folder] }
    // FileDocument crosses executors. Keep an immutable value snapshot rather
    // than sharing Foundation's mutable, non-Sendable FileWrapper instance.
    private let archive: Data
    init(directory: URL) throws {
        let wrapper = try FileWrapper(url: directory, options: .immediate)
        guard let archive = wrapper.serializedRepresentation else { throw CocoaError(.fileReadCorruptFile) }
        self.archive = archive
    }
    init(configuration: ReadConfiguration) throws {
        guard let archive = configuration.file.serializedRepresentation else { throw CocoaError(.fileReadCorruptFile) }
        self.archive = archive
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { try snapshotWrapper() }
    func snapshotWrapper() throws -> FileWrapper {
        guard let wrapper = FileWrapper(serializedRepresentation: archive) else { throw CocoaError(.fileReadCorruptFile) }
        return wrapper
    }
}
