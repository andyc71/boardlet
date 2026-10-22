import SwiftUI

/// Appearance supplied by the host app, keeping the picker independent of app assets.
public struct ARASAACPickerStyle {
    public var accent: Color
    public var background: Color
    public var selection: Color
    public var heading: Font

    public init(accent: Color = .accentColor,
                background: Color = Color(uiColor: .systemGroupedBackground),
                selection: Color = Color.accentColor.opacity(0.12),
                heading: Font = .system(.title, design: .rounded).bold()) {
        self.accent = accent
        self.background = background
        self.selection = selection
        self.heading = heading
    }
}
