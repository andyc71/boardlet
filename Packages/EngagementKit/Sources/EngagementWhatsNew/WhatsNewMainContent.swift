import SwiftUI
import EngagementCore
import EngagementContent
import SharedSwiftUI

struct WhatsNewMainContent<Model: FeaturesViewModelProtocol>: View {
    @ObservedObject var viewModel: Model
    @EnvironmentObject private var currentTheme: SharedUITheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let isCompact: Bool
    private var columnCount: Int { isCompact && !dynamicTypeSize.isAccessibilitySize ? 2 : 1 }
    private var rowCount: Int { (viewModel.features.count + columnCount - 1) / columnCount }

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 9) {
                Text(viewModel.title)
                    .font(currentTheme.headerStyle.largeFont)
                    .foregroundStyle(Color(currentTheme.headerStyle.textColor))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.title)
                if let header = viewModel.header {
                    Text(header)
                        .font(currentTheme.headerStyle.smallerFont)
                        .foregroundStyle(Color.mfOpal)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.header)
                }
            }
            .padding(.horizontal)
            // Eager rows keep intrinsic height accurate and also support iOS 15.
            VStack(alignment: .leading, spacing: 24) {
                ForEach(0..<rowCount, id: \.self) { row in
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(0..<columnCount, id: \.self) { column in
                            let index = row * columnCount + column
                            if index < viewModel.features.count {
                                FeatureRow(feature: viewModel.features[index], viewModel: viewModel,
                                           imageSize: isCompact ? 32 : 40)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                            } else {
                                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 36)
        }
        .padding(.top, 36)
        .frame(maxWidth: .infinity)
    }
}
