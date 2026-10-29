import SwiftUI
import EngagementCore
import EngagementContent
import SharedSwiftUI

struct WhatsNewModifier: ViewModifier {
    @ObservedObject var viewModel: WhatsNewViewModel
    @EnvironmentObject private var currentTheme: SharedUITheme
    let isReady: Bool
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onAppear(perform: presentIfReady)
            .onChange(of: isReady) { _ in presentIfReady() }
            .onChange(of: viewModel.showWhatsNewScreen) { pending in
                if pending { presentIfReady() } else { isPresented = false }
            }
            .sheet(isPresented: $isPresented) {
                WhatsNewContentView(viewModel: viewModel)
                    .environmentObject(currentTheme)
                    .interactiveDismissDisabled()
            }
    }

    private func presentIfReady() {
        guard !isPresented, isReady, viewModel.showWhatsNewScreen, let id = viewModel.releaseID else { return }
        isPresented = viewModel.coordinator.beginEducation(.whatsNew(id),
            context: EngagementContext(isActive: true))
    }
}

public extension View {
    func whatsNewOverlay(viewModel: WhatsNewViewModel, isReady: Bool = true) -> some View {
        modifier(WhatsNewModifier(viewModel: viewModel, isReady: isReady))
    }
}
