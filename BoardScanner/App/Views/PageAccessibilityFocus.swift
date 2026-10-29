import SwiftUI

/// Connects page-transition focus to the header used by the current layout.
struct PageAccessibilityFocus: ViewModifier {
  var focus: AccessibilityFocusState<String?>.Binding?
  var pageID: String?

  @ViewBuilder func body(content: Content) -> some View {
    if let focus, let pageID {
      content.accessibilityFocused(focus, equals: pageID)
    } else {
      content
    }
  }
}
