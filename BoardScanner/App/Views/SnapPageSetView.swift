import SwiftUI

struct SnapPageSetView: View {
  let pageSet: SnapPageSet
  let isEditing: Bool
  @ObservedObject var communication: CommunicationSession
  @ObservedObject var access: AccessController
  @ObservedObject var speech: SpeechController
  @ObservedObject var phrases: PhraseLibrary
  @State private var availableSize = CGSize(width: 320, height: 480)
  @ScaledMetric(relativeTo: .body) private var minimumCellWidth: CGFloat = 64
  @ScaledMetric(relativeTo: .body) private var minimumCellHeight: CGFloat = 72

  private func communicationPitch(for layout: SnapLayout) -> CGSize {
    // Measure the whole container, independent of the message strip's height.
    let placements = layout.placements.filter(\.visible)
    let speechRowScale: CGFloat = verticalSizeClass == .compact ? 2.0 / 3 : 1
    let verticalInsets = 24 - 8 * speechRowScale
    let widthMinimum = verticalSizeClass == .compact ? minimumCellWidth * 52 / 64 : minimumCellWidth
    let preferredWidth = max(widthMinimum * access.settings.validated.buttonScale,
                             (availableSize.width - 8) / CGFloat(layout.columns))
    let preferredHeight = max(minimumCellHeight * access.settings.validated.buttonScale,
                              (availableSize.height - verticalInsets) / (CGFloat(layout.rows) + speechRowScale))
    let maximumColumnSpan = placements.map(\.columnSpan).max() ?? 1
    let maximumRowSpan = placements.map(\.rowSpan).max() ?? 1
    return CGSize(
      width: min(preferredWidth, max(52, (availableSize.width - 8) / CGFloat(maximumColumnSpan))),
      height: min(preferredHeight, max(52, (availableSize.height - verticalInsets) / (CGFloat(maximumRowSpan) + speechRowScale))))
  }
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  let editPageSet: (PageSetEdit) -> String?
  var importSymbolLibrary: () -> Void
  @State private var path: [String] = []
  @AccessibilityFocusState(for: .voiceOver) private var focusedPage: String?
  @State private var pageFocusRequestID: UUID?
  @State private var showPages = false
  @State private var showDetails = false
  @State private var editingButton: ButtonEditDraft?
  @State private var showNewPage = false
  @State private var showPageSettings = false
  @State private var authoringError: String?
  @State private var selectedButton: SnapButton?
  @State private var selectedLayoutID: Int?
  @State private var showHidden = false

  private var page: SnapPage? { pageSet.page(path.last ?? pageSet.homePageID) }
  private var layout: SnapLayout? {
    page?.layouts.first { $0.id == selectedLayoutID } ?? page?.preferredLayout
  }

  private var compactChrome: Bool {
    verticalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
  }
  private var hasModal: Bool {
    showPages || showDetails || editingButton != nil || showNewPage || showPageSettings
      || selectedButton != nil || authoringError != nil
  }

  var body: some View {
    Color.clear
      .onGeometryChange(for: CGSize.self) { $0.size } action: { availableSize = $0 }
      .overlay(alignment: .topLeading) {
        pageContent.frame(width: availableSize.width, height: availableSize.height)
      }
  }

  private var pageContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !isEditing, let layout {
        let pitch = communicationPitch(for: layout)
        HStack(spacing: 8) {
          MessageBar(session: communication, speech: speech, phrases: phrases, access: access,
                     cardSize: CGSize(width: pitch.width - 8, height: pitch.height - 8),
                     gridColumns: layout.columns,
                     availableWidth: verticalSizeClass == .compact ? availableSize.width * 2 / 3 : nil)
            .frame(width: verticalSizeClass == .compact ? availableSize.width * 2 / 3 : nil)
          if verticalSizeClass == .compact, let page {
            Text(page.title).font(.headline).lineLimit(2)
              .frame(maxWidth: .infinity, alignment: .trailing)
              .multilineTextAlignment(.trailing)
              .accessibilityIdentifier("snapPageTitle").accessibilityAddTraits(.isHeader)
              .accessibilityFocused($focusedPage, equals: page.id)
          }
        }
      }
      if isEditing {
        HStack {
          Button(action: goBack) {
            navigationLabel("Back", symbol: "chevron.backward")
          }.disabled(path.isEmpty).accessibilityIdentifier("pageBack")
          Button(action: goHome) {
            navigationLabel("Home", symbol: "house")
          }
          .accessibilityIdentifier("pageHome")
          if compactChrome, let page {
            Text(page.title).font(.headline).lineLimit(1).accessibilityIdentifier(
              "snapPageTitle"
            )
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($focusedPage, equals: page.id)
          }
          Spacer()
          Button {
            showPages = true
          } label: {
            navigationLabel("Pages", symbol: "list.bullet")
          }
          .accessibilityIdentifier("allPages")
        }
        .buttonStyle(.bordered)
        .padding(.horizontal)
      }
      if let page {
        if isEditing && !compactChrome {
          Text(page.title).font(.title2.bold()).padding(.horizontal)
            .accessibilityIdentifier(
              "snapPageTitle"
            )
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($focusedPage, equals: page.id)
        }
        if isEditing {
          HStack {
            Text("\(pageSet.pages.count) pages · \(pageSet.title)")
              .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            Spacer()
            Menu {
              Button("Add page") { showNewPage = true }
              Button("Page settings") { showPageSettings = true }
              if let layout {
                Button("Add button") {
                  if let cell = PageSetAuthoring.freeCells(in: layout, limit: 1)
                    .first
                  {
                    addButton(
                      row: cell / layout.columns,
                      column: cell % layout.columns)
                  } else {
                    addButton(row: layout.contentRows, column: 0)
                  }
                }
              }
              Toggle("Show hidden buttons", isOn: $showHidden)
              ForEach(page.layouts) { item in
                Button("\(item.columns) × \(item.rows) · Layout \(item.id)") {
                  selectedLayoutID = item.id
                }
              }
              Button("Import symbol library…", action: importSymbolLibrary)
                .accessibilityIdentifier("importSymbolLibrary")
              Button("Import details") { showDetails = true }
            } label: {
              Label("Options", systemImage: "ellipsis.circle")
            }
            .accessibilityIdentifier("pageOptions")
          }.padding(.horizontal)
          if pageSet.unavailableNavigationLinkCount > 0 || pageSet.unavailableImageCount > 0 {
            Button {
              showDetails = true
            } label: {
              Label(
                importWarning,
                systemImage: "info.circle"
              )
              .font(.caption).multilineTextAlignment(.leading)
            }.padding(.horizontal)
              .accessibilityIdentifier("snapImportWarning")
          }
        }
        if let layout {
          SnapPageGrid(
            layout: layout, pageSet: pageSet, showHidden: isEditing && showHidden,
            isEditing: isEditing, pageID: page.id, access: access,
            session: communication,
            communicationPitch: isEditing ? nil : communicationPitch(for: layout),
            pageFocus: nil,
            scanPageTitle: nil,
            showPages: nil,
            back: goBack, home: goHome, activate: activate, add: addButton
          ) { selectedButton = $0 }
          .id(layout.id)
        } else {
          Text("This page has no grid layout.").padding()
          Spacer()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .toolbar {
      if !isEditing {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button(action: goBack) {
            Label("Back", systemImage: "chevron.backward").labelStyle(.iconOnly)
          }.disabled(path.isEmpty).accessibilityIdentifier("pageBack")
          Button(action: goHome) {
            Label("Home", systemImage: "house").labelStyle(.iconOnly)
          }.accessibilityIdentifier("pageHome")
        }
        ToolbarItem(placement: .principal) {
          if let page {
            Text(page.title).font(.headline).lineLimit(1)
              .accessibilityIdentifier("snapPageTitle").accessibilityAddTraits(.isHeader)
              .accessibilityFocused($focusedPage, equals: page.id)
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button { showPages = true } label: {
            Label("Pages", systemImage: "list.bullet").labelStyle(.iconOnly)
          }.accessibilityIdentifier("allPages")
        }
      }
    }
    .onChange(of: page?.id) { _ in pageFocusRequestID = UUID() }
    .task(id: hasModal ? nil : pageFocusRequestID) {
      guard !hasModal, pageFocusRequestID != nil, let requestedPage = page?.id else { return }
      // Let the activation gesture finish before moving VoiceOver focus.
      // The view-scoped task cancels when navigation replaces this request.
      do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
      guard page?.id == requestedPage, !hasModal else { return }
      focusedPage = requestedPage
    }
    .onChange(of: hasModal) {
      access.suspend("page-modal", while: $0)
      if $0 { communication.stopSpeaking() }
    }
    .onDisappear {
      access.suspend("page-modal", while: false)
    }
    .sheet(isPresented: $showPages, onDismiss: { pageFocusRequestID = UUID() }) {
      SnapPageBrowser(pageSet: pageSet) {
        navigate($0)
        showPages = false
      }
    }
    .sheet(item: $editingButton) { button in
      SnapButtonEditor(draft: button, pageSet: pageSet, save: editPageSet)
    }
    .sheet(isPresented: $showNewPage) {
      PageSettingsView(page: nil, layout: nil, homePageID: pageSet.homePageID) { edit in
        let failure = editPageSet(edit)
        if failure == nil, case .addPage(_, _, _, let id) = edit {
          access.stop()
          path.append(id)
          selectedLayoutID = nil
        }
        return failure
      }
    }
    .sheet(isPresented: $showPageSettings) {
      PageSettingsView(
        page: page, layout: layout, homePageID: pageSet.homePageID, save: editPageSet)
    }
    .onChange(of: pageSet.pages.map(\.id)) { ids in
      path.removeAll { !ids.contains($0) }
    }
    .alert(
      "Could not add button",
      isPresented: Binding(
        get: { authoringError != nil }, set: { if !$0 { authoringError = nil } })
    ) {
      Button("OK") { authoringError = nil }
    } message: {
      Text(authoringError ?? "")
    }
    .sheet(item: $selectedButton, onDismiss: { pageFocusRequestID = UUID() }) { button in
      SnapButtonDetail(button: button, pageSet: pageSet) { target in
        selectedButton = nil
        navigate(target)
      }
    }
    .sheet(isPresented: $showDetails) {
      NavigationStack {
        List {
          Section("Imported page set") {
            Text("\(pageSet.pages.count) pages, including disconnected pages")
            Text("\(pageSet.pages.reduce(0) { $0 + $1.layouts.count }) layouts")
            Text("\(pageSet.buttons.count) buttons · \(pageSet.linkCount) page links")
          }
          Section("Import notes") {
            Text(
              "\(pageSet.unavailableNavigationLinkCount) page links have unavailable destinations."
            )
            .accessibilityIdentifier("snapNavigationSummary")
            if pageSet.missingLinkCount > pageSet.unavailableNavigationLinkCount {
              Text("\(pageSet.missingLinkCount - pageSet.unavailableNavigationLinkCount) additional references point to pages absent from this file, but are not used by the buttons’ current actions. Home returns to this board’s home page; Keyboard opens Type a message. Original references are preserved when saving and exporting.")
            }
            Text(
              "\(pageSet.renderedAssetCount) embedded assets rendered; \(pageSet.unavailableAssetCount) unavailable embedded assets; \(pageSet.missingAssetReferenceCount) buttons reference absent assets."
            )
            .accessibilityIdentifier("snapArtworkSummary")
            Text(
              "\(pageSet.unavailableImageCount) buttons have artwork that cannot be displayed. Embedded original assets are retained. Supported WMF/EMF symbols render locally. Unsupported artwork and symbols missing from the export show a placeholder."
            )
            Text(
              "Page links, labels, messages, hidden buttons and grid spans are imported. Conditional destinations are offered as choices. Communication mode supports messages and basic Speak, Clear, Delete, Stop, Home, Back and Keyboard actions. Other commands and dynamic content remain available for inspection."
            )
          }
        }
        .navigationTitle("Import details")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { showDetails = false }
          }
        }
      }
    }
  }

  @ViewBuilder private func navigationLabel(_ title: String, symbol: String) -> some View {
    if compactChrome {
      Label(title, systemImage: symbol).labelStyle(.iconOnly).frame(
        minWidth: 44, minHeight: 44)
    } else {
      Label(title, systemImage: symbol).frame(minHeight: 44)
    }
  }

  private func addButton(row: Int, column: Int) {
    guard let page, let layout else { return }
    do {
      editingButton = try PageSetAuthoring.draft(
        in: pageSet, pageID: page.id, layoutID: layout.id, row: row, column: column)
    } catch { authoringError = error.localizedDescription }
  }

  private var importWarning: String {
    var notes: [String] = []
    if pageSet.unavailableNavigationLinkCount > 0 {
      notes.append("\(pageSet.unavailableNavigationLinkCount) unavailable page links")
    }
    if pageSet.unavailableImageCount > 0 {
      notes.append("\(pageSet.unavailableImageCount) unavailable image\(pageSet.unavailableImageCount == 1 ? "" : "s")")
    }
    return notes.joined(separator: " · ")
  }

  private func activate(_ button: SnapButton, placement: SnapPlacement) {
    if isEditing {
      guard let page, let layout else { return }
      editingButton = ButtonEditDraft(
        button: button, placement: placement, pageID: page.id, layoutID: layout.id)
      return
    }
    switch SnapCommunicationBehavior.resolve(button) {
    case .action(.home):
      path = []
      selectedLayoutID = nil
    case .action(.back):
      if !path.isEmpty {
        path.removeLast()
        selectedLayoutID = nil
      }
    case .action: communication.select(button, in: pageSet)
    case .destinations:
      if button.destinationIDs.count == 1, let target = button.destinationIDs.first,
        pageSet.page(target) != nil
      {
        navigate(target)
      } else {
        selectedButton = button
      }
    case .unsupported: selectedButton = button
    }
  }

  private func goBack() {
    access.stop()
    if !path.isEmpty {
      path.removeLast()
      selectedLayoutID = nil
    }
  }

  private func goHome() {
    access.stop()
    path = []
    selectedLayoutID = nil
  }

  private func navigate(_ id: String) {
    guard pageSet.page(id) != nil else { return }
    access.stop()
    path.append(id)
    selectedLayoutID = nil
  }
}
