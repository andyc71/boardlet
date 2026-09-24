import Combine

@MainActor
final class HarnessModel: ObservableObject {
    @Published var showingPicker = false
    @Published var selectionLimit = 0
}
