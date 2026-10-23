import Foundation

struct ARASAACBoardSuggestion: Identifiable {
    enum Status {
        case loading
        case ready(ARASAACSelection)
        case unavailable
        case failed
    }

    var id: String { term }
    let term: String
    var status: Status = .loading
}
