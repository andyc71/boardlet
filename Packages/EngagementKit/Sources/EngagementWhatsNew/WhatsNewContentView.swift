import SwiftUI
import EngagementCore
import EngagementContent
import SharedSwiftUI

/// One renderer for both the overlay API and the package's legacy FeaturesView route.
struct WhatsNewContentView<Model: FeaturesViewModelProtocol>: View {
    @ObservedObject var viewModel: Model
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var width: CGFloat = 0
    @State private var naturalHeight: CGFloat = 600

    private var isCompact: Bool { verticalSizeClass == .compact }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WhatsNewMainContent(viewModel: viewModel, isCompact: isCompact)
                if dynamicTypeSize.isAccessibilitySize {
                    WhatsNewFooterText(text: viewModel.footer)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
            }
        }
        .accessibilityIdentifier("WhatsNew.featureScroll")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    WhatsNewContinueButton(viewModel: viewModel)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                } else {
                    WhatsNewFooter(viewModel: viewModel, isVertical: !isCompact)
                }
            }
            .background(Color(UIColor.mfAlertBackground))
        }
        .background(Color(UIColor.mfAlertBackground).ignoresSafeArea())
        .modifier(WhatsNewSheetSizing(viewModel: viewModel, isCompact: isCompact,
                                      width: $width, naturalHeight: $naturalHeight))
    }
}
