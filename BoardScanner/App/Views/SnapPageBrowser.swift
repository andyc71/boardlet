import SwiftUI

struct SnapPageBrowser: View {
    @Environment(\.dismiss) private var dismiss
    let pageSet: SnapPageSet
    let select: (String) -> Void
    @State private var search = ""

    private var pages: [SnapPage] {
        pageSet.pages.filter { search.isEmpty || $0.title.localizedStandardContains(search) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List(pages) { page in
                Button { select(page.id) } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(page.title.isEmpty ? "Untitled page" : page.title).foregroundStyle(.primary)
                            Text("\(page.layouts.count) layouts").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if page.id == pageSet.homePageID { Image(systemName: "house").accessibilityLabel("Home page") }
                    }
                }.accessibilityIdentifier("snapPage_\(page.id)")
            }
            .searchable(text: $search, prompt: "Search all pages")
            .navigationTitle("All \(pageSet.pages.count) pages")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
