import SwiftUI

struct ARASAACSelectionFooter: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let count: Int
    let isDownloading: Bool
    let add: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 16))
            layout {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected: \(count)", bundle: .module)
                        .font(.headline)
                    Text("Tap symbols to select them", bundle: .module)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                Button(action: add) {
                    HStack {
                        if isDownloading { ProgressView().tint(.white) }
                        Text(isDownloading ? "Adding…" : "Add", bundle: .module)
                            .bold()
                        if !isDownloading { Image(systemName: "plus") }
                    }
                    .frame(minWidth: 70, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(count == 0 || isDownloading)
                .accessibilityIdentifier("arasaacAddButton")
            }
            Link(destination: URL(string: "https://arasaac.org/terms-of-use")!) {
                Text("Pictograms: Sergio Palao / ARASAAC · © Government of Aragón · CC BY-NC-SA", bundle: .module)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }
}
