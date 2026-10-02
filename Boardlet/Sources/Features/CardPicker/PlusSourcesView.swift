import SwiftUI

struct PlusSourcesView: View {
    @EnvironmentObject private var store: BoardStore
    var add: ((Card) -> Void)?
    @State private var prompt = ""
    @State private var generating = false
    @State private var error: String?
    @State private var work: Task<Void, Never>?
    var body: some View {
        DisclosureGroup("Additional Plus sources") {
            Text("Dynavox libraries require the existing licensed symbol bundle. This development edition can preserve and use imported Dynavox cards; new Dynavox searches are not yet available.").font(.footnote)
            if let endpoint = AISymbolService.configuredEndpoint, let add {
                TextField("Describe a symbol", text: $prompt, axis: .vertical)
                if generating { ProgressView("Creating symbol…"); Button("Cancel") { work?.cancel(); generating = false } }
                else {
                    Button("Create with AI") {
                        generating = true; error = nil
                        let description = prompt
                        work = Task {
                            do {
                                let data = try await AISymbolService(endpoint: endpoint).generate(prompt: description)
                                guard UIImage(data: data) != nil else { throw ImageImportError.invalidImage }
                                let name = try await store.storage.storeAsset(data, extension: "png")
                                try Task.checkCancellation()
                                add(Card(label: description, image: name, originalImage: name, attribution: Attribution(provider: "AI", credit: L("AI-generated image"))))
                                generating = false
                            } catch is CancellationError { generating = false }
                            catch { self.error = error.localizedDescription; generating = false }
                        }
                    }.disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                Text("AI symbol creation requires an application-owned service. No service is configured in this development edition. Existing AI cards can be imported and used offline.").font(.footnote)
            }
            if let error { Text(error).foregroundStyle(.red) }
        }.onDisappear { work?.cancel() }
    }
}
