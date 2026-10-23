import SwiftUI

struct ARASAACBoardSuggestionRow: View {
    let item: ARASAACBoardSuggestion
    let isSelected: Bool
    let toggle: () -> Void

    private var canSelect: Bool {
        switch item.status {
        case .loading, .ready: return true
        case .unavailable, .failed: return false
        }
    }

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                if case let .ready(selection) = item.status, let image = UIImage(data: selection.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: item.term).foregroundStyle(.primary)
                    if case .unavailable = item.status {
                        Text("No symbols found.", bundle: .module).font(.caption).foregroundStyle(.secondary)
                    } else if case .failed = item.status {
                        Text("Unable to load symbols", bundle: .module).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if case .loading = item.status {
                    ProgressView().accessibilityLabel(Text("Finding symbols…", bundle: .module))
                }
                if canSelect {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canSelect)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
