import SwiftUI
import PDFKit
import Photos

struct PrintExportView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    let boardID: UUID
    @State private var pdf: Data?
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var showPrint = false
    @State private var options = false
    @State private var exporting = false
    @State private var message: String?
    var body: some View {
        NavigationStack {
            VStack {
                if let board = store.board(boardID) {
                    let renderer = BoardRenderer(board: board, mediaURL: store.mediaURL)
                    Text("\(renderer.pageCount) pages").font(.subheadline)
                    Text("\(board.print.paper.rawValue) · \(L(board.print.landscape ? "Landscape" : "Portrait"))").font(.subheadline)
                    Text("\(Int(renderer.cellSizeMM.width)) × \(Int(renderer.cellSizeMM.height)) mm per card").font(.caption).foregroundStyle(.secondary)
                    if let pdf { PDFPreview(data: pdf).accessibilityLabel(L("Print preview")) }
                    else { ProgressView("Preparing pages…") }
                    if let message { Text(message).font(.footnote).padding(.horizontal) }
                    if exporting { ProgressView("Saving pages…") }
                }
            }.navigationTitle("Print and share").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("closePrint") }
                    ToolbarItem(placement: .topBarTrailing) { Button { options = true } label: { Label("Paper and layout", systemImage: "slider.horizontal.3") } }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button { showPrint = true } label: { Label("Print", systemImage: "printer") }.disabled(pdf == nil)
                        Spacer()
                        Button { Task { await share() } } label: { Label("Share PDF", systemImage: "square.and.arrow.up") }.disabled(pdf == nil)
                        Spacer()
                        Button { Task { await saveImages() } } label: { Label("Save images", systemImage: "photo.badge.arrow.down") }.disabled(pdf == nil || exporting)
                    }
                }
                .task(id: store.board(boardID)?.modifiedAt) { if let board = store.board(boardID) { pdf = BoardRenderer(board: board, mediaURL: store.mediaURL).pdf() } }
                .sheet(isPresented: $options) { PrintOptionsView(boardID: boardID) }
                .sheet(isPresented: $showShare) { if let shareURL { ShareSheet(items: [shareURL]) } }
                .sheet(isPresented: $showPrint) { if let pdf { PrintSheet(data: pdf, name: store.board(boardID)?.name ?? "Boardlet") { error in showPrint = false; if let error { message = error } } } }
        }
    }
    func share() async {
        guard let pdf else { return }
        do { let url = URL.temporaryDirectory.appendingPathComponent("Boardlet-\(UUID().uuidString).pdf"); try pdf.write(to: url, options: .atomic); shareURL = url; showShare = true }
        catch { message = error.localizedDescription }
    }
    func saveImages() async {
        guard let pdf, let document = PDFDocument(data: pdf) else { return }
        exporting = true; defer { exporting = false }
        let permission = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard permission == .authorized || permission == .limited else { message = L("Allow Photos access in Settings to save pages."); return }
        do {
            // Rasterize each PDF page, including credits, from the same source as Print/Share.
            for index in 0..<document.pageCount {
                guard let page = document.page(at: index) else { continue }
                let bounds = page.bounds(for: .mediaBox)
                let image = page.thumbnail(of: CGSize(width: bounds.width * 2, height: bounds.height * 2), for: .mediaBox)
                guard let png = image.pngData() else { throw ImageImportError.invalidImage }
                try await PHPhotoLibrary.shared().performChanges { PHAssetCreationRequest.forAsset().addResource(with: .photo, data: png, options: nil) }
            }
            message = L("All pages saved to Photos.")
        } catch { message = error.localizedDescription }
    }
}

struct PDFPreview: UIViewRepresentable {
    let data: Data
    func makeUIView(context: Context) -> PDFView { let view = PDFView(); view.autoScales = true; view.displayMode = .singlePageContinuous; return view }
    func updateUIView(_ view: PDFView, context: Context) { if context.coordinator.data != data { context.coordinator.data = data; view.document = PDFDocument(data: data) } }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var data: Data? }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}

struct PrintSheet: UIViewControllerRepresentable {
    let data: Data
    let name: String
    let completion: (String?) -> Void
    func makeUIViewController(context: Context) -> PrintPresenter { PrintPresenter(data: data, name: name, completion: completion) }
    func updateUIViewController(_ controller: PrintPresenter, context: Context) { }
}

final class PrintPresenter: UIViewController {
    let data: Data
    let jobName: String
    let completion: (String?) -> Void
    private var presented = false
    init(data: Data, name: String, completion: @escaping (String?) -> Void) { self.data = data; self.jobName = name; self.completion = completion; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { nil }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !presented else { return }; presented = true
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil); info.jobName = jobName; info.outputType = .general
        controller.printInfo = info; controller.printingItem = data
        controller.present(from: view.bounds, in: view, animated: true) { [weak self] _, _, error in self?.completion(error?.localizedDescription) }
    }
}
