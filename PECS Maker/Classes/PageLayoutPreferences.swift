import Foundation

/// Layout defaults are independent of the choice of app interface.
enum PageLayoutMedium: String {
    case paper, screen

    static let storageKey = "pageLayout.medium"
    static let automaticKey = "pageLayout.screenAutomatic"
    static let screenLayoutKey = "pageLayout.screenLayout"
    static let screenCardSizeKey = "pageLayout.screenCardSize"

    static func fixedCardSize(data: Data) -> CGSize? {
        guard let size = try? JSONDecoder().decode(CGSize.self, from: data),
              size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return nil }
        return size
    }

    static func cardSizeData(for layout: PageLayoutType, viewport: CGSize) -> Data {
        guard viewport.width > 1, viewport.height > 1 else { return Data() }
        return (try? JSONEncoder().encode(ScreenCardGridGeometry.screenPreset(layout, in: viewport).cardSize)) ?? Data()
    }

    static func preferred(in defaults: UserDefaults = .standard) -> Self {
        if let value = defaults.string(forKey: storageKey), let medium = Self(rawValue: value) {
            return medium
        }
        let style = defaults.string(forKey: InterfaceStyle.storageKey)
            .flatMap(InterfaceStyle.init(rawValue:)) ?? InterfaceStyle.defaultValue
        return style == .classic ? .paper : .screen
    }

    static func predefinedLayout(data: Data, viewport: CGSize) -> PageLayoutType {
        if let layout = try? JSONDecoder().decode(PageLayoutType.self, from: data),
           (1...PageLayoutType.maxColumns).contains(layout.width),
           (1...PageLayoutType.maxRows).contains(layout.height) { return layout }
        return PageLayoutSection.forScreen(in: viewport).first?.layouts
            .first(where: { $0.preset == .medium })?.layout ?? PageLayoutType(width: 2, height: 3)
    }

    static func automaticLayout(in viewport: CGSize) -> PageLayoutType {
        PageLayoutType(width: max(1, Int((viewport.width - 8) / 108)),
                       height: max(1, Int((viewport.height - 32) / 108)))
    }
}

extension PageLayoutSection {
    /// Use the paper catalogue's minimum size and nearest-size ranking, converting
    /// points to nominal millimetres solely for scoring (not physical screen size).
    static func forScreen(in viewport: CGSize, horizontalInset: CGFloat = 8,
                          verticalInset: CGFloat = 20, spacing: CGFloat = 8,
                          minimumCardWidth: CGFloat = 0) -> [Self] {
        make { layout in
            let width = (viewport.width - 2 * horizontalInset - CGFloat(layout.width - 1) * spacing) / CGFloat(layout.width)
            let height = (viewport.height - 2 * verticalInset - CGFloat(layout.height - 1) * spacing) / CGFloat(layout.height)
            guard width > 0, height > 0 else { return nil }
            let size = layout.fixedCardAspectRatio == nil
                ? CGSize(width: width, height: height)
                : CGSize(width: min(width, height), height: min(width, height))
            guard size.width >= minimumCardWidth else { return nil }
            return Measurements(CGSize(width: size.width * 25.4 / 72, height: size.height * 25.4 / 72))
        }
    }
}
