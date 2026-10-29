import SwiftUI

struct PageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let page: SnapPage?
    let layout: SnapLayout?
    let homePageID: String
    let save: (PageSetEdit) -> String?
    @State private var title: String
    @State private var rows: Int
    @State private var columns: Int
    @State private var makeHome = false
    @State private var showDelete = false
    @State private var error: String?

    init(page: SnapPage?, layout: SnapLayout?, homePageID: String, save: @escaping (PageSetEdit) -> String?) {
        self.page = page; self.layout = layout; self.homePageID = homePageID; self.save = save
        _title = State(initialValue: page?.title ?? "")
        _rows = State(initialValue: layout?.rows ?? 3)
        _columns = State(initialValue: layout?.columns ?? 3)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Page name", text: $title).accessibilityIdentifier("pageName")
                Section("Grid") {
                    Stepper("Rows: \(rows)", value: $rows, in: 1...(page == nil ? 12 : 128))
                    Stepper("Columns: \(columns)", value: $columns, in: 1...(page == nil ? 12 : 128))
                    if page != nil {
                        Text("Existing buttons keep their positions. Buttons beyond the resized grid remain scrollable.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if let page {
                    Section("Home page") {
                        if page.id == homePageID { Text("This is your home page.") }
                        else { Toggle("Use as home page", isOn: $makeHome).accessibilityIdentifier("makeHomePage") }
                    }
                    if page.id != homePageID {
                        Button("Delete page", role: .destructive) { showDelete = true }
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle(page == nil ? "New page" : "Page settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(page == nil ? "Add page" : "Save page", action: savePage)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("savePage")
                }
            }
            .confirmationDialog("Delete this page and its links?", isPresented: $showDelete, titleVisibility: .visible) {
                Button("Delete page", role: .destructive) {
                    if let page { finish(.deletePage(id: page.id)) }
                }
            } message: { Text("Buttons shared with other pages remain available. Links that only opened this page become inactive.") }
        }
    }

    private func savePage() {
        if let page {
            finish(.updatePage(id: page.id, layoutID: layout?.id ?? -1, title: title, rows: rows, columns: columns, home: makeHome))
        } else { finish(.addPage(title: title, rows: rows, columns: columns)) }
    }
    private func finish(_ edit: PageSetEdit) {
        error = save(edit)
        if error == nil { dismiss() }
    }
}
