import SwiftUI

struct ARASAACStatusCard: View {
    let icon: String
    let title: LocalizedStringKey
    let message: String
    let style: ARASAACPickerStyle

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(style.accent)
                .accessibilityHidden(true)
            Text(title, bundle: .module).font(.title2.bold())
            Text(message).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 480)
        .padding(32)
    }
}
