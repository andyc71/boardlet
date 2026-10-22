import SwiftUI

struct ARASAACSearchField: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(text: $query, prompt: Text("Search ARASAAC", bundle: .module)) {
                Text("Search ARASAAC", bundle: .module)
            }
            .submitLabel(.search)
            .autocorrectionDisabled()
            .accessibilityIdentifier("arasaacSearchField")
            if !query.isEmpty {
                Button { query = "" } label: {
                    Label { Text("Clear search", bundle: .module) } icon: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .frame(minHeight: 54)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08)) }
    }
}
