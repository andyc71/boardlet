import SwiftUI

struct DefaultBoardsSection: View {
    @EnvironmentObject private var navigationModel: NavigationModel
    @ObservedObject private var repoFactory = PECSRepoFactory.shared
    @State private var missingCount = 0
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var addedCount = 0

    private var language: String { Bundle.main.preferredLocalizations.first ?? "en" }
    private var confirmationTitle: String {
        switch missingCount {
        case 0: return L10n.DefaultBoards.alreadyAdded
        case 1: return L10n.DefaultBoards.confirmOne
        default: return L10n.DefaultBoards.confirm(missingCount)
        }
    }

    var body: some View {
        Section {
            Button(action: prepareAddition) {
                Label(L10n.DefaultBoards.action, systemImage: "square.grid.3x3.fill")
            }
            .accessibilityIdentifier("Settings.addDefaultBoards")
        }
        .alert(confirmationTitle, isPresented: $showingConfirmation) {
            if missingCount > 0 {
                Button(L10n.DefaultBoards.cancel, role: .cancel) { }
                Button(L10n.DefaultBoards.add, action: addBoards)
            } else {
                Button(L10n.DefaultBoards.ok, role: .cancel) { }
            }
        } message: {
            if missingCount > 0 { Text(L10n.DefaultBoards.preserveExisting) }
        }
        .alert(L10n.DefaultBoards.failure, isPresented: $showingError) {
            Button(L10n.DefaultBoards.ok, role: .cancel) { }
        } message: {
            Text(L10n.DefaultBoards.retry)
        }
        .alert(addedCount == 1 ? L10n.DefaultBoards.addedOne : L10n.DefaultBoards.added(addedCount),
               isPresented: $showingSuccess) {
            Button(L10n.DefaultBoards.ok) {
                navigationModel.showTopics()
            }
        }
    }

    private func prepareAddition() {
        guard let source = Bundle.main.url(forResource: "StarterBoards", withExtension: nil) else {
            showingError = true
            return
        }
        do {
            missingCount = try StarterBoardInstaller.missingBoards(
                from: source, into: repoFactory.documentsDirectory, language: language).count
            showingConfirmation = true
        } catch {
            showingError = true
        }
    }

    private func addBoards() {
        guard let source = Bundle.main.url(forResource: "StarterBoards", withExtension: nil) else {
            showingError = true
            return
        }
        do {
            addedCount = try repoFactory.restoreDefaultBoards(from: source, language: language)
            showingSuccess = true
        } catch {
            showingError = true
        }
    }
}
