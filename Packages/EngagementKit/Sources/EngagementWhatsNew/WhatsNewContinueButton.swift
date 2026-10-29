import SwiftUI
import EngagementCore
import EngagementContent
import SharedSwiftUI

struct WhatsNewContinueButton<Model: FeaturesViewModelProtocol>: View {
    @ObservedObject var viewModel: Model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        CapsuleButton(viewModel.buttonTitle, role: .primary, action: viewModel.dismissFeaturesView)
            .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 200)
            .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.closeButton)
    }
}
