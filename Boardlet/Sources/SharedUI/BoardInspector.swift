import SwiftUI

extension View {
    func boardInspector<Inspector: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Inspector) -> some View {
        modifier(BoardInspectorModifier(isPresented: isPresented, inspector: content))
    }
}

private struct BoardInspectorModifier<Inspector: View>: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Binding var isPresented: Bool
    let inspector: () -> Inspector
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            // Reserve useful space for the library, canvas and inspector. Smaller
            // containers and accessibility type use a sheet without replacing the canvas.
            let inline = sizeClass == .regular && !typeSize.isAccessibilitySize && geometry.size.width >= 280 + 360 + 320
            HStack(spacing: 0) {
                content.frame(width: max(0, geometry.size.width - (inline && isPresented ? 320 : 0)), height: geometry.size.height)
                if inline && isPresented {
                    inspector().frame(width: 320).background(.background)
                        .overlay(alignment: .leading) { Divider() }
                }
            }
                .sheet(isPresented: Binding(get: { isPresented && !inline }, set: { if !$0 { isPresented = false } })) { inspector() }
        }
    }
}
