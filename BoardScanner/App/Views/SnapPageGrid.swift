import SwiftUI

/// Explicit source positions preserve sparse cells and merged row/column spans.
struct SnapPageGrid: View {
  let layout: SnapLayout
  let pageSet: SnapPageSet
  let showHidden: Bool
  let isEditing: Bool
  let pageID: String
  @ObservedObject var access: AccessController
  @ObservedObject var session: CommunicationSession
  var communicationPitch: CGSize? = nil
  var pageFocus: AccessibilityFocusState<String?>.Binding? = nil
  var scanPageTitle: String? = nil
  var showPages: (() -> Void)? = nil
  let back: () -> Void
  let home: () -> Void
  let activate: (SnapButton, SnapPlacement) -> Void
  let add: (Int, Int) -> Void
  let inspect: (SnapButton) -> Void
  @State private var width: CGFloat = 320
  @State private var viewportHeight: CGFloat = 0
  @State private var containerHeight: CGFloat = 0
  @ScaledMetric(relativeTo: .body) private var minimumCellWidth: CGFloat = 64
  @ScaledMetric(relativeTo: .body) private var cellHeight: CGFloat = 72

  private var focusedRect: CGRect? {
    guard let id = access.focusedID,
          let placement = displayedPlacements.first(where: { String($0.id) == id }) else { return nil }
    return CGRect(x: CGFloat(placement.column) * cellWidth + 4,
                  y: CGFloat(placement.row) * rowHeight + 4,
                  width: CGFloat(placement.columnSpan) * cellWidth - 8,
                  height: CGFloat(placement.rowSpan) * rowHeight - 8)
  }

  private var displayedPlacements: [SnapPlacement] {
    layout.placements.filter { $0.visible || showHidden }
  }

  private var cellWidth: CGFloat {
    if let communicationPitch { return communicationPitch.width }
    let preferred = max(minimumCellWidth * access.settings.validated.buttonScale,
                        (width - 8) / CGFloat(layout.columns))
    let spans = displayedPlacements.map(\.columnSpan)
    return min(preferred, max(52 / CGFloat(spans.min() ?? 1),
                              (width - 8) / CGFloat(spans.max() ?? 1)))
  }

  private var rowHeight: CGFloat {
    if let communicationPitch {
      guard viewportHeight > 0 else { return communicationPitch.height }
      let spans = displayedPlacements.map(\.rowSpan)
      return min(communicationPitch.height,
                 max(52 / CGFloat(spans.min() ?? 1),
                     (viewportHeight - 8) / CGFloat(spans.max() ?? 1)))
    }
    let minimum = cellHeight * access.settings.validated.buttonScale
    guard !isEditing, viewportHeight > 0 else { return max(130, minimum) }
    // The export defines a viewport grid, not device-specific pixel sizes.
    // Larger text/buttons retain scrolling instead of shrinking below their minimum.
    let preferred = max(minimum, (viewportHeight - 8) / CGFloat(layout.rows))
    let spans = displayedPlacements.map(\.rowSpan)
    return min(preferred, max(52 / CGFloat(spans.min() ?? 1),
                              (viewportHeight - 8) / CGFloat(spans.max() ?? 1)))
  }
  private var scanItems: [ScanItem] {
    ScanItem.placements(in: layout, pageSet: pageSet) + ScanItem.navigationActions
      + ScanItem.messageActions
  }
  private var context: String { "page:\(pageID):layout:\(layout.id)" }

  private func communicationHint(_ button: SnapButton) -> String {
    switch SnapCommunicationBehavior.resolve(button) {
    case .action(let action): action.title
    case .destinations: "Open linked page"
    case .unsupported: "Show unsupported action details"
    }
  }

  var body: some View {
    Color.clear
      .onGeometryChange(for: CGSize.self) { $0.size } action: {
        width = $0.width
        containerHeight = $0.height
      }
      .overlay(alignment: .topLeading) {
        gridContent.frame(width: width, height: containerHeight)
      }
  }

  private var gridContent: some View {
    VStack(spacing: 4) {
      if !isEditing {
        ScanControls(
          access: access, session: session, pageTitle: scanPageTitle, showPages: showPages,
          pageID: pageID, pageFocus: pageFocus
        ) { id in
          if id == "command:back" {
            back()
          } else if id == "command:home" {
            home()
          } else if let placement = layout.placements.first(where: { String($0.id) == id }
          ),
            let button = pageSet.buttons[placement.elementID]
          {
            activate(button, placement)
          }
        }
      }
      Group {
        Color.clear
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
          .overlay(alignment: .topLeading) {
            GridViewport(contentSize: CGSize(width: cellWidth * CGFloat(layout.contentColumns) + 8,
                                             height: rowHeight * CGFloat(layout.contentRows) + 8),
                         focusRect: focusedRect) {
              SourceGridLayout(
                size: CGSize(
                  width: cellWidth * CGFloat(layout.contentColumns),
                  height: rowHeight * CGFloat(layout.contentRows))
              ) {
                if isEditing && layout.rows * layout.columns <= 144 {
                  ForEach(PageSetAuthoring.freeCells(in: layout), id: \.self) { cell in
                    Button {
                      add(cell / layout.columns, cell % layout.columns)
                    } label: {
                      Label("Add button", systemImage: "plus")
                        .font(.caption)
                        .frame(width: cellWidth - 8, height: rowHeight - 8)
                        .background(
                          .background, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(
                      "emptyCell_\(cell / layout.columns)_\(cell % layout.columns)"
                    )
                    .offset(
                        x: CGFloat(cell % layout.columns) * cellWidth,
                        y: CGFloat(cell / layout.columns) * rowHeight)
                  }
                }
                ForEach(displayedPlacements) {
                  placement in
                  if let button = pageSet.buttons[placement.elementID] {
                    Button {
                      if isEditing || access.acceptSelection(String(placement.id)) {
                        activate(button, placement)
                      }
                    } label: {
                      SnapButtonTile(
                        button: button,
                        asset: button.assetKey.flatMap { pageSet.assets[$0] },
                        height: rowHeight * CGFloat(placement.rowSpan) - 8,
                        hidden: !placement.visible
                      )
                      .frame(
                        width: cellWidth * CGFloat(placement.columnSpan) - 8,
                        height: rowHeight * CGFloat(placement.rowSpan) - 8)
                    }
                    .buttonStyle(.plain)
                    .modifier(
                      ScanHighlight(
                        selected: access.focusedID == String(placement.id)
                          && !isEditing,
                        availableHeight: rowHeight * CGFloat(placement.rowSpan) - 8)
                    )
                    .id(String(placement.id))
                    .accessibilityLabel(
                      button.label.isEmpty ? "Unlabelled button" : button.label
                    )
                    .accessibilityValue(
                      "Row \(placement.row + 1), column \(placement.column + 1)\(placement.visible ? "" : ", hidden")"
                    )
                    .accessibilityHint(
                      isEditing ? "Edit button" : communicationHint(button)
                    )
                    .accessibilityIdentifier("snapButton_\(button.id)")
                    .contextMenu {
                      if isEditing { Button("Button details") { inspect(button) } }
                    }
                    .offset(
                        x: CGFloat(placement.column) * cellWidth,
                        y: CGFloat(placement.row) * rowHeight)
                  } else {
                    Text("Message window").font(.caption).foregroundStyle(.secondary)
                      .frame(
                        width: cellWidth * CGFloat(placement.columnSpan) - 8,
                        height: rowHeight * CGFloat(placement.rowSpan) - 8
                      )
                      .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                      .offset(
                          x: CGFloat(placement.column) * cellWidth,
                          y: CGFloat(placement.row) * rowHeight)
                  }
                }
              }
              .frame(
                width: cellWidth * CGFloat(layout.contentColumns),
                height: rowHeight * CGFloat(layout.contentRows), alignment: .topLeading
              )
              .padding(4)

            }
            .background((pageSet.page(pageID)?.backgroundARGB ?? pageSet.backgroundARGB).map { Color(snapARGB: $0) } ?? Color.clear)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .frame(width: width, height: viewportHeight)
            .clipped()
            .accessibilityIdentifier("snapGrid")
            .frame(maxHeight: .infinity)


          }
      }
    }
    .onAppear { access.setItems(scanItems, context: context) }
    .onChange(of: scanItems) { access.setItems($0, context: context) }
    .onChange(of: context) { access.setItems(scanItems, context: $0) }
    .frame(maxWidth: .infinity)

  }
}
