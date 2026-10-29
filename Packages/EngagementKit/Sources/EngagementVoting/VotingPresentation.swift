import SwiftUI
import EngagementContent
import SharedSwiftUI
import MailFramework

private struct VotingPresentation: ViewModifier {
    @EnvironmentObject private var viewModel: FeaturesViewModel
    @EnvironmentObject private var currentTheme: SharedUITheme
    func body(content: Content) -> some View {
        content
        .sheet(isPresented: $viewModel.showFeaturesView, onDismiss: viewModel.featuresViewDidDismiss) {
            FeaturesView(viewModel: viewModel)
                .autoPresentationHeightIfAvailable()
                .environmentObject(currentTheme)
                // Present above the feature list while its sheet is open.
                .thankYouAlert(isPresented: $viewModel.showThankYouAlert,
                               title: LocalizedFeatureStrings.thankYouTitle,
                               message: LocalizedFeatureStrings.thankYouMessage,
                               theme: currentTheme,
                               completion: viewModel.dismissThankYouAlert)
        }
        .emailComposer(viewModel: viewModel.showSendMailViewModel, theme: currentTheme, onDismiss: { result in
            viewModel.handleSendMailEvent(result: result)
        })
        // Email votes finish after the feature list has been dismissed.
        .thankYouAlert(isPresented: Binding(
            get: { viewModel.showThankYouAlert && !viewModel.showFeaturesView },
            set: { viewModel.showThankYouAlert = $0 }
        ),
                       title: LocalizedFeatureStrings.thankYouTitle,
                       message: LocalizedFeatureStrings.thankYouMessage,
                       theme: currentTheme,
                       completion: viewModel.dismissThankYouAlert)
    }
}
public extension View {
    func votingPresentation() -> some View { modifier(VotingPresentation()) }
}
