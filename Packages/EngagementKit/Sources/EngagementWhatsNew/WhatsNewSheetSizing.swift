import SwiftUI
import EngagementCore
import EngagementContent

/// iOS 15 uses the same content in a standard sheet. iOS 16 adds fitted detents.
struct WhatsNewSheetSizing<Model: FeaturesViewModelProtocol>: ViewModifier {
    @ObservedObject var viewModel: Model
    let isCompact: Bool
    @Binding var width: CGFloat
    @Binding var naturalHeight: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
                .background {
                    if width > 0 && !isCompact {
                        VStack(spacing: 0) {
                            WhatsNewMainContent(viewModel: viewModel, isCompact: false)
                            WhatsNewFooter(viewModel: viewModel, isVertical: true)
                        }
                        .frame(width: width)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                            if height > 0 && abs(naturalHeight - height) > 1 { naturalHeight = height }
                        }
                        .frame(height: 0, alignment: .top)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                    }
                }
                .presentationDetents(isCompact ? [.large] : [.height(max(1, naturalHeight))])
        } else {
            content
        }
    }
}
