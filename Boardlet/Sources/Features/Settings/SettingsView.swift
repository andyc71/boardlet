import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    @State private var importing = false
    @State private var importingArchive = false
    @State private var busy = false
    @State private var share = false
    @State private var archiveURL: URL?
    @State private var message: String?
    func binding<T>(_ path: WritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(get: { store.library.defaults[keyPath: path] }, set: { value in store.preferences { $0[keyPath: path] = value } })
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Communication defaults") {
                    Picker("Tap behaviour", selection: binding(\.communication.tap)) { Text("Speak the card").tag(TapBehavior.speak); Text("Add to message").tag(TapBehavior.message); Text("Speak and add to message").tag(TapBehavior.both) }
                    VoiceSettingsView(language: binding(\.communication.language), voiceID: binding(\.communication.voiceID))
                    Toggle("Confirm before leaving Use mode", isOn: binding(\.communication.protectEditing))
                    Text("A message belongs to one Use session. Leaving Use mode clears it. Rotation and changing pages keep it.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Print defaults") {
                    Picker("Paper size", selection: binding(\.print.paper)) { ForEach(Paper.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    Toggle("Landscape", isOn: binding(\.print.landscape))
                    Text("Defaults apply to new boards. Existing boards keep their own settings.").font(.footnote)
                }
                Section("Your data") {
                    Button("Import legacy boards folder") { importing = true }.disabled(busy)
                    Button("Import Boardlet backup") { importingArchive = true }.disabled(busy)
                    Button("Export complete backup") { export() }.disabled(busy)
                    Text("Choose a copy of the old app’s Documents folder, or a single board folder containing index.json and its media. Originals are never changed. Reimporting the same legacy board skips it.").font(.footnote).foregroundStyle(.secondary)
                    if busy { ProgressView("Importing and validating…") }
                    if let message { Text(message) }
                    if let notice = store.notice { Text(notice) }
                }
                Section("Help") {
                    Text("Add pictures in the editor, then tap a card to edit its label or voice. Board controls set what happens when a card is tapped in Use mode. Card actions offer accessible move and duplicate controls. Undo and Redo restore recent edits, including removed cards.")
                    Text("Use mode keeps card positions stable. Swipe to scroll dense boards; use Previous page and Next page for more cards. Use Guided Access in iOS Settings for stronger session protection.")
                    Link("Contact support", destination: URL(string: "mailto:choiceboard.app@outlook.com")!)
                }
                Section("Credits") {
                    Text("ARASAAC pictograms: Sergio Palao, Government of Aragón. Licensed under CC BY-NC-SA. Attribution is saved with each card and included in exported pages. Respect the licence when sharing.")
                    Link("ARASAAC", destination: URL(string: "https://arasaac.org")!)
                    Text("Starter boards use Apple SF Symbols. Photos and recordings stay on your device. Symbol searches require an internet connection.")
                    #if BOARDLET_PLUS
                    PlusSourcesView()
                    #endif
                }
                Section("About") { Text("Boardlet · Development edition"); Text("This edition uses a separate library from PECS Maker and Easy PECS Plus.").font(.footnote) }
            }.navigationTitle("Settings").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.folder]) { result in
                    switch result { case .success(let url): importFolder(url); case .failure(let error): message = error.localizedDescription }
                }
                .fileImporter(isPresented: $importingArchive, allowedContentTypes: [.json, .data]) { result in
                    switch result { case .success(let url): importBackup(url); case .failure(let error): message = error.localizedDescription }
                }
                .sheet(isPresented: $share) { if let archiveURL { ShareSheet(items: [archiveURL]) } }
        }
    }
    func importFolder(_ url: URL) {
        busy = true
        Task {
            let accessed = url.startAccessingSecurityScopedResource(); defer { if accessed { url.stopAccessingSecurityScopedResource() }; busy = false }
            await store.importLegacy(url)
        }
    }
    func importBackup(_ url: URL) {
        busy = true
        Task {
            let accessed = url.startAccessingSecurityScopedResource(); defer { if accessed { url.stopAccessingSecurityScopedResource() }; busy = false }
            do { let archive = try JSONDecoder().decode(LibraryArchive.self, from: Data(contentsOf: url)); let library = try await archive.validatedImport(storage: store.storage); store.mergeArchive(library); await store.flush(); message = L("Backup imported.") }
            catch { message = error.localizedDescription }
        }
    }
    func export() {
        do { let data = try LibraryArchive.export(store: store); let url = URL.temporaryDirectory.appendingPathComponent("Boardlet-backup-\(UUID().uuidString).json"); try data.write(to: url, options: .atomic); archiveURL = url; share = true }
        catch { message = error.localizedDescription }
    }
}
