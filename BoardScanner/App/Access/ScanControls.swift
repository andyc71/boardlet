import SwiftUI

struct ScanControls: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ObservedObject var access: AccessController
  @ObservedObject var session: CommunicationSession
  var pageTitle: String? = nil
  var showPages: (() -> Void)? = nil
  var pageID: String? = nil
  var pageFocus: AccessibilityFocusState<String?>.Binding? = nil
  let select: (String) -> Void
  private var compactLabels: Bool {
    dynamicTypeSize.isAccessibilitySize
  }
  private var selectionLabel: String {
    access.isScanning ? "Select: \(access.focusedLabel ?? "choice")" : "Start scan"
  }
  private var compactSelectionLabel: String {
    guard access.isScanning else { return "Start" }
    switch access.focusedID {
    case "command:back": return "Back"
    case "command:home": return "Home"
    case "command:stop": return "Stop"
    case "command:speak": return "Speak"
    case "command:undo": return "Undo"
    case "command:clear": return "Clear"
    default: return access.focusedLabel ?? "Select"
    }
  }

  var body: some View {
    if access.settings.mode != .direct {
      HStack(spacing: 8) {
        if let pageTitle, !compactLabels {
          Text(pageTitle).font(.headline).lineLimit(1).frame(maxWidth: 160)
            .accessibilityIdentifier("snapPageTitle")
            .accessibilityAddTraits(.isHeader)
            .modifier(PageAccessibilityFocus(focus: pageFocus, pageID: pageID))
        }
        Button {
          access.step(backward: true)
        } label: {
          Label("Previous choice", systemImage: "backward.end.fill")
            .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
        }
        .keyboardShortcut(.leftArrow, modifiers: .command)
        .accessibilityIdentifier("scanPrevious")
        Button {
          if let id = access.select() {
            switch id {
            case "command:stop": session.stopSpeaking()
            case "command:speak": session.speak()
            case "command:undo": session.undo()
            case "command:clear": session.clear()
            default: select(id)
            }
          }
        } label: {
          Text(
            compactLabels ? compactSelectionLabel : selectionLabel
          )
          .lineLimit(compactLabels ? 1 : 2).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
        .keyboardShortcut(.space, modifiers: [])
        .accessibilityIdentifier("scanSelect")
        .accessibilityLabel(selectionLabel)
        .accessibilityValue(compactLabels ? (pageTitle ?? "") : "")
        .accessibilityInputLabels(
          access.isScanning ? [Text("Select"), Text("Choose")] : [Text("Start scan")]
        )
        .accessibilityHint(
          access.isScanning
            ? "Select this choice and pause scanning" : "Highlight the first choice"
        )
        Button {
          access.step()
        } label: {
          Label("Next choice", systemImage: "forward.end.fill")
            .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
        }
        .keyboardShortcut(.rightArrow, modifiers: .command)
        .accessibilityIdentifier("scanNext")
        if let showPages {
          Button(action: showPages) {
            Label("Pages", systemImage: "list.bullet").labelStyle(.iconOnly)
              .frame(minWidth: 44, minHeight: 44)
          }
          .accessibilityIdentifier("allPages")
          .accessibilityValue(compactLabels ? (pageTitle ?? "") : "")
          .modifier(PageAccessibilityFocus(focus: compactLabels ? pageFocus : nil, pageID: pageID))
        }
      }
      .buttonStyle(.bordered)
      .disabled(!access.available || access.items.isEmpty)
      .padding(.horizontal)
      .task(id: access.runID) { await access.runAutomaticScan() }
    }
  }
}
