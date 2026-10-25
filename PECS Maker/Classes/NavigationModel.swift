import SwiftUI

/// Owns the navigation session. Views send intents; only this coordinator mutates
/// history. Routes contain stable IDs, never mutable model objects or view state.
@MainActor
final class NavigationModel: ObservableObject {
    @Published private(set) var path: [AppRoute] = []
    @Published private(set) var pageLayoutState: PageLayoutState?
    private var didRestoreInitialTopic = false
    private var choiceBoardReturnAction: MainMenuAction?

    @Published var selectedPhotoIDs: Set<UUID> = []
    @Published var isPhotoSelectionMode = false
    @Published var selectedBoardPage = 0

    var selectedAction: MainMenuAction? {
        path.compactMap { route in
            if case let .menu(action) = route { return action }
            return nil
        }.last
    }

    var actionBinding: Binding<MainMenuAction?> {
        Binding(get: { self.selectedAction }, set: { action in
            if let action { self.setMainMenuAction(action) }
            else { self.returnToBoard() }
        })
    }

    func prepareTopic(_ topic: PECSRepo) {
        guard pageLayoutState?.topic !== topic else { return }
        if pageLayoutState?.topic.id != topic.id { pageLayoutState?.save() }
        choiceBoardReturnAction = nil
        resetBoardEditorState()
        pageLayoutState = PageLayoutState(topic: topic)
    }

    func restoreInitialTopic(_ topic: PECSRepo?, openBoard: Bool = true) {
        guard !didRestoreInitialTopic else { return }
        didRestoreInitialTopic = true
        if let topic {
            prepareTopic(topic)
            if openBoard { path = [.board(topic.id)] }
        }
    }

    func setTopic(_ topic: PECSRepo) {
        prepareTopic(topic)
        path = [.board(topic.id)]
    }

    func clearTopic() {
        path = []
        pageLayoutState = nil
        resetBoardEditorState()
    }

    func resetBoardEditorState() {
        selectedPhotoIDs.removeAll()
        isPhotoSelectionMode = false
        selectedBoardPage = 0
    }

    func push(_ route: AppRoute) {
        guard path.last != route else { return }
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func showTopics() {
        path = []
    }

    func returnToBoard() {
        if let first = path.first, case .board = first { path = Array(path.prefix(1)) }
        else { path = [] }
    }

    func resetInterfaceNavigation() {
        pageLayoutState?.save()
        choiceBoardReturnAction = nil
        returnToBoard()
    }

    func setMainMenuAction(_ action: MainMenuAction) {
        returnToBoard()
        push(.menu(action))
    }

    func enterChoiceBoard(returningTo action: MainMenuAction?) {
        choiceBoardReturnAction = action
        returnToBoard()
    }

    func takeChoiceBoardReturnAction() -> MainMenuAction? {
        defer { choiceBoardReturnAction = nil }
        return choiceBoardReturnAction
    }

    /// A split column presents a prefix as its root and the remainder as pushes.
    /// Compact and regular layouts therefore share one history, including cards.
    func rootDepth(for scope: NavigationScope) -> Int {
        guard scope != .compact else { return 0 }
        let boardDepth = path.first.map { if case .board = $0 { return 1 }; return 0 } ?? 0
        if scope == .classicDetail, path.count > boardDepth,
           case .menu = path[boardDepth] { return boardDepth + 1 }
        return boardDepth
    }

    func stackPath(for scope: NavigationScope) -> [AppRoute] {
        Array(path.dropFirst(rootDepth(for: scope)))
    }

    func updateStackPath(_ newPath: [AppRoute], for scope: NavigationScope) {
        path = Array(path.prefix(rootDepth(for: scope))) + newPath
    }

    func pathBinding(for scope: NavigationScope) -> Binding<[AppRoute]> {
        Binding(get: { self.stackPath(for: scope) },
                set: { self.updateStackPath($0, for: scope) })
    }

    func revealCard(_ id: UUID) {
        guard let state = pageLayoutState, let index = state.photoBrowserData.photoItems.firstIndex(where: { $0.itemID == id }) else { return }
        selectedPhotoIDs = [id]
        selectedBoardPage = index / max(1, state.topic.layout.width * state.topic.layout.height)
    }

    func openCard(at index: Int) {
        guard let photos = pageLayoutState?.photoBrowserData.photoItems, index >= 0 else { return }
        push(index < photos.count ? .photo(photos[index].itemID) : .emptyCard(index))
    }
}
