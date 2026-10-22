import SwiftUI

struct ARASAACSearchWelcome: View {
    let style: ARASAACPickerStyle
    let suggestions: [String]
    let search: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.largeTitle)
                    .foregroundStyle(style.accent)
                    .padding(20)
                    .background(style.selection, in: RoundedRectangle(cornerRadius: 24))
                    .accessibilityHidden(true)
                Text("A picture for every word", bundle: .module)
                    .font(style.heading)
                    .accessibilityAddTraits(.isHeader)
                Text("Find symbols for everyday moments, feelings and activities.", bundle: .module)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 440)
            .padding(.top, 20)

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested for your board", bundle: .module)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                        ForEach(suggestions, id: \.self) { word in
                            Button { search(word) } label: {
                                Label(word, systemImage: "magnifyingglass")
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .padding(.horizontal, 8)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(style.accent)
                        }
                    }
                }
                .frame(maxWidth: 560)
            }
        }
        .padding(.bottom)
    }
}
