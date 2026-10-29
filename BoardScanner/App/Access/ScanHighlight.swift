import SwiftUI

struct ScanHighlight: ViewModifier {
  let selected: Bool
  var availableHeight: CGFloat? = nil
  @ScaledMetric(relativeTo: .body) private var markerSize: CGFloat = 20
  func body(content: Content) -> some View {
    content
      .overlay {
        if selected {
          RoundedRectangle(cornerRadius: 12).strokeBorder(.primary, lineWidth: 5)
            .overlay(alignment: .topLeading) {
              Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: indicatorSize, weight: .bold))
                .frame(width: indicatorSize, height: indicatorSize).padding(5)
                .foregroundStyle(.background).background(.primary, in: Circle())
                .padding(5)
            }
            .accessibilityHidden(true).allowsHitTesting(false)
        }
      }
      .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var indicatorSize: CGFloat {
    min(markerSize, max(12, (availableHeight ?? .infinity) - 20))
  }
}
