import Foundation

/// Every pushed destination in the app's board workflow.
enum AppRoute: Hashable {
    case board(UUID)
    case menu(MainMenuAction)
    case photo(UUID)
    case emptyCard(Int)
    case boardDetails
    case allLayouts
    case credits
    case diagnostics
}

enum NavigationScope {
    case compact
    case modernDetail
    case classicDetail
}
