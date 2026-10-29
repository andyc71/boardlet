import SwiftUI

struct ImportBar: View {
    @Binding var showPhotos: Bool
    var openFiles: () -> Void
    var disabled: Bool

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                Button { showPhotos = true } label: { Label("Photos", systemImage: "photo.on.rectangle") }
                Button(action: openFiles) { Label("Files", systemImage: "folder") }
                Label("On device", systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary)
            }
            .labelStyle(.titleAndIcon)
            .fixedSize(horizontal: true, vertical: false)
            .padding()
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("importActions")
        .buttonStyle(.bordered)
        .disabled(disabled)
    }
}
