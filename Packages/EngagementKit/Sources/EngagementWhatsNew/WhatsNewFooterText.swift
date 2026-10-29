import SwiftUI
import EngagementCore
import EngagementContent
import SharedSwiftUI

struct WhatsNewFooterText: View {
    let text: String?
    var body: some View {
        if let text {
            Text(text)
                .font(.footnote)
                .foregroundStyle(Color.mfOpal)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.footer)
        }
    }
}
