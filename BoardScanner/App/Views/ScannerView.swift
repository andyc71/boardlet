import SwiftUI
import UniformTypeIdentifiers

struct ScannerView: View {
  @StateObject private var model = ScannerModel()
  @StateObject private var speech: SpeechController
  @StateObject private var communication: CommunicationSession
  @StateObject private var access: AccessController
  @StateObject private var phrases: PhraseLibrary
  @State private var isEditing = false
  @State private var showCommunicationSettings = false
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var importer = PhotoImportModel()
  @State private var showNewBoard = false
  @State private var showLibrary = false
  @State private var showPhotos = false
  @State private var showFiles = false
  @State private var isSymbolLibraryImport = false
  @State private var showGrid = false
  @State private var showExport = false
  @State private var selectedCard: ScannedCard?
  @State private var showDetection = false
  @State private var availableWidth: CGFloat = 320

  init() {
    let speech = SpeechController()
    _speech = StateObject(wrappedValue: speech)
    let arguments = ProcessInfo.processInfo.arguments
    var suite = "BoardScanner.ui-tests"
    if let index = arguments.firstIndex(of: "--library-id"),
      arguments.indices.contains(index + 1),
      let id = UUID(uuidString: arguments[index + 1])
    {
      suite += "." + id.uuidString
    }
    let defaults =
      arguments.contains("--ui-testing") ? UserDefaults(suiteName: suite)! : .standard
    _access = StateObject(wrappedValue: AccessController(defaults: defaults))
    _phrases = StateObject(wrappedValue: PhraseLibrary(defaults: defaults))
    _communication = StateObject(
      wrappedValue: CommunicationSession(speaker: speech, defaults: defaults))
  }

  private var suspended: Bool {
    isEditing || model.document == nil || model.busy || importer.isLoading || showNewBoard
      || showLibrary || showCommunicationSettings || showPhotos || showFiles
      || showGrid || showExport || selectedCard != nil || model.error != nil
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if isEditing || model.document == nil {
          ImportBar(
            showPhotos: $showPhotos, openFiles: {
              isSymbolLibraryImport = false
              showFiles = true
            },
            disabled: model.busy || importer.isLoading)
        }
        if model.board != nil && !isEditing {
          HStack(spacing: 8) {
            MessageBar(
              session: communication, speech: speech, phrases: phrases, access: access,
              availableWidth: verticalSizeClass == .compact ? availableWidth * 2 / 3 : nil)
              .frame(width: verticalSizeClass == .compact ? availableWidth * 2 / 3 : nil)
            if verticalSizeClass == .compact {
              Text(model.board?.title ?? "").font(.headline).lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .trailing)
              .multilineTextAlignment(.trailing)
                .accessibilityAddTraits(.isHeader)
            }
          }
        }
        if model.busy || importer.isLoading {
          HStack {
            ProgressView()
            Text(importer.isLoading ? "Loading screenshot…" : model.status).font(
              .subheadline)
            Spacer()
            Button("Cancel") {
              importer.cancel()
              model.cancel()
            }
            .disabled(!importer.isLoading && !model.canCancel)
          }
          .padding()
          .accessibilityIdentifier("scanProgress")
        }
        if let pageSet = model.pageSet {
          SnapPageSetView(
            pageSet: pageSet, isEditing: isEditing, communication: communication,
            access: access, speech: speech, phrases: phrases,
            editPageSet: model.editPageSet
          ) {
            isSymbolLibraryImport = true
            showFiles = true
          }
          .id(model.documentID)
          .disabled(model.busy)
          if isEditing {
            Text(model.status + (model.dirty ? " · Unsaved" : ""))
              .font(.caption).foregroundStyle(.primary).lineLimit(1).padding(8)
              .accessibilityIdentifier("boardStatus")
          }
        } else if let board = model.board {
          if isEditing || verticalSizeClass != .compact {
            VStack(alignment: .leading, spacing: 8) {
              Text(board.title).font(.title2.bold())
              if isEditing {
                Text(
                  "\(board.rows) rows × \(board.columns) columns · \(board.cards.filter(\.needsReview).count) to review"
                )
                .font(.subheadline).foregroundStyle(.secondary)
                Picker("View", selection: $showDetection) {
                  Text("Choice board").tag(false)
                  Text("Detection").tag(true)
                }
                .pickerStyle(.segmented)
              }
            }.padding()
          }
          if showDetection && isEditing {
            ScrollView {
              DetectionPreview(
                source: board.sourcePNG,
                cells: board.cards.filter { $0.isEmpty != true }.map(\.bounds),
                pictures: board.cards.filter { $0.isEmpty != true }.map(
                  \.pictureBounds)
              )
              .padding()
              Text(
                "Blue outlines are cards. Green outlines show the extracted picture areas. Open a card in Choice board to correct its label or crop."
              )
              .font(.footnote).foregroundStyle(.secondary).padding()
            }
          } else {
            BoardGrid(
              board: board, isEditing: isEditing, access: access,
              session: communication
            ) {
              card in
              if isEditing { selectedCard = card } else { communication.select(card) }
            }
            .id(model.documentID)
            .disabled(model.busy)
          }
          if isEditing {
            Text(model.status + (model.dirty ? " · Unsaved" : ""))
              .font(.caption).foregroundStyle(.primary).lineLimit(1).padding(8)
              .accessibilityIdentifier("boardStatus")
          }
        } else {
          WelcomeView(
            source: model.source, showGrid: $showGrid, create: { showNewBoard = true }
          ) {
            if let data = SampleBoard.image().pngData() { model.scan(data) }
          }
          .disabled(model.busy || importer.isLoading)
        }
      }
      .background(Color(uiColor: .systemGroupedBackground))
      .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
      .toolbar(!isEditing && model.document != nil && verticalSizeClass == .compact ? .hidden : .visible,
               for: .navigationBar)
      .navigationTitle(isEditing || model.document == nil ? "Board Scanner" : (model.board?.title ?? ""))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if model.document != nil && !isEditing {
          ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
              Button("Edit board") {
                isEditing = true
                speech.stop()
                access.stop()
              }.accessibilityIdentifier("toggleEditing")
              Button("Board library") { showLibrary = true }
                .accessibilityIdentifier("boardLibrary")
              Button("New board") { showNewBoard = true }
              Button("Communication settings") {
                showCommunicationSettings = true
              }.accessibilityIdentifier("communicationSettings")
            } label: {
              Label("Board options", systemImage: "gearshape").labelStyle(.iconOnly)
            }.accessibilityIdentifier("boardOptions")
          }
        } else {
        ToolbarItem(placement: .navigationBarLeading) {
          if model.document != nil {
            Button(isEditing ? "Communicate" : "Edit") {
              isEditing.toggle()
              speech.stop()
              access.stop()
            }
            .foregroundStyle(.primary)
            .accessibilityIdentifier("toggleEditing")
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button("New board") { showNewBoard = true }
            if model.board != nil && isEditing {
              Button("Make editable copy", action: model.makeEditableCopy)
            }
          } label: {
            Label("Create", systemImage: "plus")
          }
          .disabled(model.busy).accessibilityIdentifier("createMenu")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showLibrary = true
          } label: {
            Label("Board library", systemImage: "books.vertical")
          }
          .disabled(model.busy).accessibilityIdentifier("boardLibrary")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showCommunicationSettings = true
          } label: {
            Label("Communication settings", systemImage: "speaker.wave.2.circle")
          }.accessibilityIdentifier("communicationSettings")
        }
        }
        if isEditing {
          ToolbarItemGroup(placement: .bottomBar) {
            Button {
              showGrid = true
            } label: {
              Label("Adjust grid", systemImage: "square.grid.3x3")
            }
            .disabled(model.source == nil || model.busy)
            Spacer()
            Button {
              model.save()
            } label: {
              Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(model.document == nil || model.busy)
            Button {
              showExport = true
            } label: {
              Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(model.document == nil || model.busy)
          }
        }
      }
      // An empty bottom toolbar can remain a full-window hit-test surface after
      // rotation or relaunch. Communication and welcome screens have no bottom bar.
      .toolbar(isEditing ? .visible : .hidden, for: .bottomBar)
    }
    .tint(
      colorScheme == .dark
        ? Color(red: 0.78, green: 0.74, blue: 1)
        : Color(red: 0.22, green: 0.15, blue: 0.55)
    )
    .task { await model.restore() }
    .onAppear { access.suspend("root", while: suspended) }
    .onChange(of: suspended) {
      access.suspend("root", while: $0)
      if $0 { speech.stop() }
    }
    .onChange(of: model.documentID) { _ in
      communication.resetConversation()
      access.resetForDocument()
      isEditing = model.openInEditor
    }
    .onChange(of: scenePhase) { phase in
      access.suspend("inactive", while: phase != .active)
      if phase != .active { speech.stop() }
    }
    .sheet(isPresented: $showNewBoard) { NewBoardView(create: model.createBoard) }
    .sheet(isPresented: $showLibrary) { BoardLibraryView(model: model) }
    .sheet(isPresented: $showCommunicationSettings) {
      CommunicationSettingsView(session: communication, speech: speech, access: access)
    }
    .onOpenURL { model.open($0) }
    .onChange(of: importer.state) { state in
      if case .loaded = state, let photo = importer.photos.first { model.scan(photo.pngData) }
      if case .failed(let message) = state { model.error = message }
    }
    .sheet(isPresented: $showPhotos) {
      SystemPhotoPicker(
        selectionLimit: 1,
        onSelection: { providers in
          showPhotos = false
          importer.importPhotos(from: providers)
        }, onCancel: { showPhotos = false })
    }
    .sheet(isPresented: $showGrid) {
      if let source = model.source {
        GridAdjustmentView(source: source, board: model.board) { grid in
          model.scan(source, grid: grid)
        }
      }
    }
    .sheet(item: $selectedCard) { card in
      if let source = model.board?.sourcePNG {
        CardEditorView(card: card, source: source) { model.update($0) }
      }
    }
    .fileImporter(
      isPresented: $showFiles,
      allowedContentTypes: isSymbolLibraryImport ? [.data] : [
        .image, .scannedBoard, UTType(filenameExtension: "sps") ?? .tdSnapPageSet,
      ]
    ) { result in
      switch result {
      case .success(let url):
        if isSymbolLibraryImport { model.importSymbolLibrary(url) } else { model.open(url) }
      case .failure(let error): model.error = error.localizedDescription
      }
    }
    .fileExporter(
      isPresented: $showExport, document: model.document,
      contentType: .scannedBoard, defaultFilename: model.document?.title ?? "Choice Board"
    ) { result in
      if case .failure(let error) = result { model.error = error.localizedDescription }
    }
    .alert(
      "Board Scanner",
      isPresented: Binding(
        get: { model.error != nil },
        set: { if !$0, model.error != nil { model.error = nil } })
    ) {
      Button("OK") { model.error = nil }
    } message: {
      Text(model.error ?? "")
    }
  }
}
