import SwiftUI
import EngagementCore
import EngagementContent
import SharedSwiftUI

struct WhatsNewFooter<Model: FeaturesViewModelProtocol>: View {
    @ObservedObject var viewModel: Model
    let isVertical: Bool

    var body: some View {
        Group {
            if isVertical {
                VStack(spacing: 36) {
                    WhatsNewFooterText(text: viewModel.footer)
                    WhatsNewContinueButton(viewModel: viewModel)
                }
            } else {
                HStack(spacing: 36) {
                    WhatsNewFooterText(text: viewModel.footer)
                    WhatsNewContinueButton(viewModel: viewModel)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .padding(.bottom, 12)
    }
}
