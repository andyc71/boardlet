import SwiftUI

struct BoardGrid: View {
  var board: ScannedBoard
  var isEditing = true
  @ObservedObject var access: AccessController
  @ObservedObject var session: CommunicationSession
  var edit: (ScannedCard) -> Void
  @State private var width: CGFloat = 320
  @State private var viewportHeight: CGFloat = 0
  @State private var containerHeight: CGFloat = 0
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  @ScaledMetric(relativeTo: .body) private var minimumCellWidth: CGFloat = 100
  @ScaledMetric(relativeTo: .headline) private var labelHeight: CGFloat = 64
  private var scanItems: [ScanItem] { ScanItem.cards(in: board) + ScanItem.messageActions }
  private var gridWidth: CGFloat {
    cellWidth * CGFloat(board.columns) + CGFloat(board.columns - 1) * 12
  }
  private var cellWidth: CGFloat {
    let preferredWidth = max(
      width - 32,
      CGFloat(board.columns) * minimumCellWidth * access.settings.validated.buttonScale)
    let preferred = (preferredWidth - CGFloat(board.columns - 1) * 12) / CGFloat(board.columns)
    return isEditing ? preferred : min(preferred, max(44, width - 32))
  }
  private var tileHeight: CGFloat? {
    guard !isEditing, viewportHeight > 0 else { return nil }
    return min(cellWidth + labelHeight, max(44, viewportHeight - 16))
  }

  private var scrollAxes: Axis.Set {
    var axes: Axis.Set = []
    if gridWidth + 32 > width + 0.5 { axes.insert(.horizontal) }
    let height = CGFloat(board.rows) * ((tileHeight ?? cellWidth / 0.8) + 12) + 4
    if height > viewportHeight + 0.5 { axes.insert(.vertical) }
    return axes
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
          access: access, session: session,
          pageTitle: verticalSizeClass == .compact ? board.title : nil
        ) { id in
          if let card = board.cards.first(where: { $0.id.uuidString == id }) {
            edit(card)
          }
        }
      }
      ScrollViewReader { proxy in
        ScrollView(scrollAxes) {
          Group {
            if let tileHeight {
              SourceGridLayout(
                size: CGSize(
                  width: gridWidth,
                  height: CGFloat(board.rows) * (tileHeight + 12) - 12
                )
              ) {
                ForEach(board.cards.filter { $0.isEmpty != true && $0.included }) { card in
                  cardButton(card, height: tileHeight)
                    .frame(width: cellWidth, height: tileHeight)
                    .offset(
                        x: CGFloat(card.column) * (cellWidth + 12),
                        y: CGFloat(card.row) * (tileHeight + 12))
                }
              }
            } else {
              LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: board.columns),
                spacing: 12
              ) {
                ForEach(board.cards) { card in
                  if card.isEmpty == true || (!isEditing && !card.included) {
                    Color.clear.aspectRatio(0.8, contentMode: .fit).accessibilityHidden(true)
                  } else {
                    cardButton(card, height: nil)
                  }
                }
              }
              .frame(width: gridWidth)
            }
          }
          .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .frame(width: width)
        .clipped()
        .accessibilityIdentifier("cardGrid")
        .frame(maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }

        .onChange(of: access.focusedID) { id in
          if let id { proxy.scrollTo(id, anchor: .center) }
        }
        .onChange(of: viewportHeight) { _ in
          if let id = access.focusedID { proxy.scrollTo(id, anchor: .center) }
        }
        .onChange(of: width) { _ in
          if let id = access.focusedID { proxy.scrollTo(id, anchor: .center) }
        }
      }
    }
    .onAppear { access.setItems(scanItems, context: "cards") }
    .onChange(of: scanItems) { access.setItems($0, context: "cards") }
    .frame(maxWidth: .infinity)

  }
  private func cardButton(_ card: ScannedCard, height: CGFloat?) -> some View {
    Button {
      if isEditing || access.acceptSelection(card.id.uuidString) { edit(card) }
    } label: {
      CardTile(card: card, height: height)
    }
    .buttonStyle(.plain)
    .modifier(ScanHighlight(selected: access.focusedID == card.id.uuidString && !isEditing))
    .id(card.id.uuidString)
    .accessibilityLabel(card.label.isEmpty ? "Unlabelled card" : card.label)
    .accessibilityValue(
      "Row \(card.row + 1), column \(card.column + 1)\(card.needsReview ? ", needs review" : "")\(card.included ? "" : ", hidden")"
    )
    .accessibilityHint(isEditing ? "Edit label and image crop" : "Add to message")
    .accessibilityIdentifier("card_\(card.row)_\(card.column)")
  }

}
