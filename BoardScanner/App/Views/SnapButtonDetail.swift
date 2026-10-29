import SwiftUI

struct SnapButtonDetail: View {
    @Environment(\.dismiss) private var dismiss
    let button: SnapButton
    let pageSet: SnapPageSet
    let navigate: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Button") {
                    Text(button.label.isEmpty ? "Unlabelled" : button.label)
                    if !button.message.isEmpty { Text(button.message) }
                    if let key = button.assetKey {
                        if let data = pageSet.assets[key]?.previewPNG, let image = UIImage(data: data) {
                            ArtworkImage(image: image).frame(maxHeight: 200)
                        } else { Text("Artwork unavailable. The symbol is missing from the export or uses an unsupported image format.").foregroundStyle(.secondary) }
                    }
                }
                if !button.destinationIDs.isEmpty {
                    Section(SnapCommunicationBehavior.resolve(button) == .destinations ? "Linked pages" : "Original page references") {
                        if SnapCommunicationBehavior.resolve(button) != .destinations {
                            Text("These references are preserved from the source file. This button’s current action does not use them.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(button.destinationIDs, id: \.self) { id in
                            if let page = pageSet.page(id) {
                                Button(page.title) { navigate(id) }
                            } else {
                                Label("Page unavailable: \(id)", systemImage: "exclamationmark.triangle")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Text(SnapCommunicationBehavior.resolve(button) == .unsupported
                         ? "This button uses an unsupported action. In Edit mode you can choose a communication action for it."
                         : "Basic communication actions work in Communicate mode. You can change the label, spoken message and action in Edit mode.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Button details").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
