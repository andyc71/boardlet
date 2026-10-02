//
//  MainMenuButton.swift
//  PECS Maker
//
//  Created by Andy on 29/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct MainMenuButton: View {
    
    var action: ()->()
    var systemIconName: String? = nil
    var text: String
    var showCheckMark: Bool = false
    var isHorizontal: Bool = false
    var isSecondary: Bool = false
    var isSelected: Bool = false
    var isLarge: Bool = false

    //let buttonFontTitle = Font.title2
    //let buttonFontWeight = FontVariation.semibold
    //let buttonFontImage = Font.title2
    let buttonFontImage = Font.title
    //let buttonFontCheckmark = Font.largeTitle
    //let buttonFontCheckmark = Font.title2
    let innerPadding = CGFloat(16)
    
    func calcMaxHeight() -> CGFloat {
        var height = CGFloat(0)
        if systemIconName != nil {
            height += calcIconHeight()
            height += calcInternalPadding() * 4
        }
        height += calcTextHeight()
        //height += (2 * innerPadding)
        return height * 2
    }
    
    func calcIconHeight() -> CGFloat {
        var height: CGFloat = 20
        do {
            let h = try buttonFontImage.toAppKitOrUIKitFont().pointSize
            height = h
        }
        catch {
        }
        if isLarge {
            return height * 1.5
        }
        else {
            return height
        }
    }
    
    func calcTextHeight() -> CGFloat {
//        var height: CGFloat = 20
//        if let h = buttonFontTitle.toUIFont()?.pointSize {
//            height = h
//        }
//        if isLarge {
//            return height * 1.5
//        }
//        else {
//            return height
//        }
        return calcIconHeight() * 0.75
    }
    
    func makeTextFont() -> Font {
        return .system(size: calcTextHeight())
    }
    
    func makeCheckMarkFont() -> Font {
        return makeTextFont()
    }

    func calcMaxWidth() -> CGFloat {
        var width = AppSettings.maxButtonWidth
        if isLarge {
            width *= 2
        }
        return width
    }
    
    func calcInternalPadding() -> CGFloat {
        if isLarge {
            return calcTextHeight() * 0.1
        }
        else {
            return 0
        }
    }
    
    
    private var checkMarkView: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(makeCheckMarkFont())
            .foregroundColor(.white)
            //.frame(maxWidth: .infinity, alignment: .trailing)
    }

    var body: some View {
     
        Button(action: { action() }) {
            ConditionalStack(isHorizonalStack: isHorizontal) {
                //Spacer()
                    //.frame(minHeight: 0, idealHeight: 0)
                if let systemIconName = systemIconName {
                    Image(systemName: systemIconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        //.height(calcIconHeight())
                        //.font(buttonFontImage)
                        .padding(calcInternalPadding())
                        .frame(height: calcIconHeight())
                }
                ZStack {
                    Text(text)
                        .lineLimit(2)
                        .font(makeTextFont())
                        .padding(calcInternalPadding())
                }
                //Causes the ZStack to be full width, which
                //enables us to have the tickbox overlay
                //fully right-aligned.
                .frame(maxWidth: .infinity)
            }
            .if(showCheckMark) { view in
                view.overlay(alignment: .bottomTrailing) {
                    //No real reason to have this visible to
                    //accessibility, but if we did unhide it we
                    //would need to be careful because somehow is
                    //causes the entire button to show as selected!
                    checkMarkView
                        .padding(.vertical, calcInternalPadding())
                        .accessibilityHidden(true)
                }
            }
        }
        .if(isLarge) { view in
            view.frame(maxHeight: calcMaxHeight())
        }
        .buttonStyle(RoundedButtonStyle( purpose: isSecondary ? ButtonPurpose.secondary : ButtonPurpose.primary, cornerRadius: 25, padding: innerPadding, isSelected: isSelected ))
    }
}

struct MainMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MainMenuButton(action: {}, systemIconName: "printer", text: "Big Button", showCheckMark: true, isSecondary: false, isSelected: true, isLarge: true)
            
            Divider()
                .padding()

            MainMenuButton(action: {}, systemIconName: "photo", text: "Select Photos", isSecondary: false, isSelected: true)
            MainMenuButton(action: {}, systemIconName: "square.grid.2x2", text: "Layout", isSecondary: false, isSelected: false)
            MainMenuButton(action: {}, systemIconName: "printer", text: "Preview and Print", isSecondary: true, isSelected: false)


        }
        .maxWidth(350)

    }
}

// Shared surfaces and controls for the board creation screen.
private enum BoardPalette {
    static let filled = Color.mfVeryBrightBlue
    static let accent = Color.mfVeryBrightBlue
}

private struct BoardFilledSurface: View {
    private let cornerRadius: CGFloat = 16
    let color: Color

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape.fill(color)
    }
}

private struct BoardCardIcon: View {
    let icon: String
    var isOnFilledCard = false

    var body: some View {
        Image(systemName: icon)
            .font(.title3.weight(.semibold))
            .foregroundColor(isOnFilledCard ? .white : BoardPalette.accent)
            .frame(width: 46, height: 46)
            .background(isOnFilledCard ? Color.white.opacity(0.17) : Color.mfPaleBlue,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct BoardActionButton: View {
    enum Emphasis {
        case standard
        case output
    }

    let action: () -> Void
    let icon: String
    let title: String
    var subtitle: String? = nil
    var showsDisclosure = true
    var emphasis: Emphasis = .standard
    var isSelected = false
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil

    private let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                BoardCardIcon(icon: icon, isOnFilledCard: isSelected || emphasis == .output)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected || emphasis == .output ? .white : .primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(isSelected || emphasis == .output ? .white.opacity(0.92) : .secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isSelected || emphasis == .output ? .white : BoardPalette.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background {
                if isSelected || emphasis == .output {
                    BoardFilledSurface(color: BoardPalette.accent)
                } else {
                    BoardFilledSurface(color: Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            .overlay(shape.strokeBorder(BoardPalette.accent.opacity(isSelected ? 0.7 : 0.10),
                                        lineWidth: isSelected ? 2 : 1))
            .shadow(color: Color.mfVeryBrightBlue.opacity(0.07), radius: 8, y: 3)

        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityValue(subtitle ?? "")
        .accessibilityHint(accessibilityHint ?? "")
    }
}

struct BoardCompactButton: View {
    enum Role {
        case primary
        case secondary
        case utility
    }

    let action: () -> Void
    let icon: String
    let title: String
    let role: Role

    private let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                Text(title)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(minHeight: 50)
                .padding(.horizontal, 12)
                .foregroundColor(role == .primary ? .white : BoardPalette.accent)
                .background {
                    if role == .primary {
                        BoardFilledSurface(color: BoardPalette.accent)
                    } else {
                        BoardFilledSurface(color: Color(uiColor: .secondarySystemGroupedBackground))
                    }
                }
                .overlay(shape.strokeBorder(BoardPalette.accent.opacity(role == .primary ? 0 : 0.18)))
        }
        .buttonStyle(.plain)
    }
}

struct BoardPhotoCard: View {
    @ObservedObject var pageLayoutState: PageLayoutState
    let photos: [PhotoItem]
    let status: String
    let changeSelections: () -> Void

    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 64

    private let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            if photos.isEmpty {
                NoPhotosTipView(pageLayoutState: pageLayoutState,
                                source: .mainMenu,
                                presentation: .card)
                .padding(.small)
            } else {

                HStack(alignment: .top, spacing: 12) {
                    BoardCardIcon(icon: "photo.on.rectangle")
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.MainMenu.photosCardTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(status)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(photos, id: \.id) { photo in
                            Image(uiImage: photo.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: thumbnailSize, height: thumbnailSize)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(BoardPalette.accent.opacity(0.12))
                                }
                        }
                    }
                }
                .accessibilityHidden(true)
            }

            if !photos.isEmpty {
                CapsuleButton(L10n.MainMenu.changeSelectionsButton,
                              role: .secondary,
                              action: changeSelections)
                    .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
                    .accessibilityHint(L10n.MainMenu.changeSelectionsHint)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: shape)
        //.background(Color(UIColor.mfLighterBlue), in: shape)
        //.overlay(shape.strokeBorder(BoardPalette.accent.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.mfVeryBrightBlue.opacity(0.07), radius: 8, y: 3)
    }

}

struct BoardNavigationControl: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BoardNavigationIcon(icon: icon)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct BoardBackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(isPresented)
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .navigationBarLeading) {
                        BoardNavigationControl(icon: "chevron.left",
                                               label: L10n.MainMenu.back,
                                               action: { dismiss() })
                    }
                }
            }
    }
}

extension View {
    func boardBackButton(isPresented: Bool = true) -> some View {
        modifier(BoardBackButtonModifier(isPresented: isPresented))
    }
}

struct BoardNavigationIcon: View {
    let icon: String

    var body: some View {
        if #available(iOS 26.0, *) {
            Image(systemName: icon)
        }
        else {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundColor(BoardPalette.accent)
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())
        }
    }
}
