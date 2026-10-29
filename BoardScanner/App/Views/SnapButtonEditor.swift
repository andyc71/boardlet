import SwiftUI

struct SnapButtonEditor: View {
    @Environment(\.dismiss) private var dismiss
    let pageSet: SnapPageSet
    let draft: ButtonEditDraft
    let save: (PageSetEdit) -> String?
    @State private var button: SnapButton
    @State private var placement: SnapPlacement
    @State private var action: CommunicationAction
    @State private var destination: String
    @State private var artwork: ArtworkChange = .unchanged
    @State private var showArtwork = false
    @State private var showDestinations = false
    @State private var showDelete = false
    @State private var error: String?

    init(draft: ButtonEditDraft, pageSet: SnapPageSet, save: @escaping (PageSetEdit) -> String?) {
        self.draft = draft; self.pageSet = pageSet; self.save = save
        _button = State(initialValue: draft.button)
        _placement = State(initialValue: draft.placement)
        _action = State(initialValue: draft.button.communicationAction ?? .automatic)
        _destination = State(initialValue: draft.button.destinationIDs.first ?? "")
    }

    private var preview: Data? {
        switch artwork {
        case .unchanged: button.assetKey.flatMap { pageSet.assets[$0]?.previewPNG }
        case .remove: nil
        case .replace(let data): data
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Words") {
                    TextField("Label", text: $button.label, axis: .vertical).accessibilityIdentifier("snapEditLabel")
                    TextField("Spoken message (uses label when empty)", text: $button.message, axis: .vertical)
                        .accessibilityIdentifier("snapEditMessage")
                }
                Section("Picture") {
                    if let preview, let image = UIImage(data: preview) {
                        ArtworkImage(image: image).frame(maxHeight: 140)
                            .accessibilityLabel("Button picture").accessibilityIdentifier("buttonArtworkPreview")
                    }
                    Button("Choose picture") { showArtwork = true }.accessibilityIdentifier("chooseButtonArtwork")
                    if button.assetKey != nil || preview != nil {
                        Button("Remove picture", role: .destructive) { artwork = .remove }
                    }
                }
                Section("When selected") {
                    Picker("Action", selection: $action) {
                        ForEach(CommunicationAction.allCases) { item in Text(item.title).tag(item) }
                    }.accessibilityIdentifier("buttonAction")
                    if action == .openPage {
                        Button { showDestinations = true } label: {
                            LabeledContent("Destination", value: pageSet.page(destination)?.title ?? "Choose a page")
                        }.accessibilityIdentifier("buttonDestination")
                    }
                    Text("Default behavior follows this button’s page links or supported imported action. An explicit action replaces that behavior.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Position in this layout") {
                    Stepper("Row: \(placement.row + 1)", value: $placement.row, in: 0...255)
                    Stepper("Column: \(placement.column + 1)", value: $placement.column, in: 0...255)
                    Stepper("Rows tall: \(placement.rowSpan)", value: $placement.rowSpan, in: 1...128)
                    Stepper("Columns wide: \(placement.columnSpan)", value: $placement.columnSpan, in: 1...128)
                    Toggle("Show this button", isOn: $placement.visible)
                    Text("Words, picture and action update everywhere this button is shared. Position and visibility apply to this layout only.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if !draft.isNew {
                    Button("Remove from this layout", role: .destructive) { showDelete = true }
                        .accessibilityIdentifier("removeButton")
                }
                if let error { Text(error).foregroundStyle(.red).accessibilityIdentifier("buttonEditError") }
            }
            .navigationTitle(draft.isNew ? "New button" : "Edit button")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save button", action: saveButton).accessibilityIdentifier("saveSnapButton")
                        .disabled(action == .openPage && pageSet.page(destination) == nil)
                }
            }
            .sheet(isPresented: $showArtwork) { ArtworkChooser { artwork = .replace($0) } }
            .sheet(isPresented: $showDestinations) {
                SnapPageBrowser(pageSet: pageSet) { destination = $0; showDestinations = false }
            }
            .confirmationDialog("Remove this button?", isPresented: $showDelete, titleVisibility: .visible) {
                Button("Remove button", role: .destructive) {
                    finish(.removeButton(pageID: draft.pageID, layoutID: draft.layoutID, placementID: placement.id))
                }
            } message: { Text("Other pages and layouts that share this button are kept.") }
        }
    }

    private func saveButton() {
        button.communicationAction = action == .automatic ? nil : action
        if action == .openPage { button.destinationIDs = [destination] }
        finish(.upsertButton(pageID: draft.pageID, layoutID: draft.layoutID, button: button, placement: placement, artwork: artwork))
    }
    private func finish(_ edit: PageSetEdit) {
        error = save(edit)
        if error == nil { dismiss() }
    }
}
