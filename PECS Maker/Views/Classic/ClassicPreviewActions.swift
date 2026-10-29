import SwiftUI

/// A small output rail in compact height, and a short action dock in portrait.
struct ClassicPreviewActions: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var pageLayoutState: PageLayoutState
    let isCompactHeight: Bool
    let isSavingToPhotoLibrary: Bool
    let showFormatting: () -> Void
    let saveImage: () -> Void
    let exportPDF: () -> Void

    private var usesRows: Bool { isCompactHeight || dynamicTypeSize.isAccessibilitySize }

    private var secondaryLayout: AnyLayout {
        usesRows ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            actions
            ScrollView { actions }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            secondaryLayout {
                if pageLayoutState.canRepeatSinglePhoto {
                    Button {
                        pageLayoutState.repeatSinglePhoto.toggle()
                    } label: {
                        ClassicPreviewActionLabel(title: L10n.PreviewPage.repeatButton,
                            symbol: pageLayoutState.repeatSinglePhoto ? "repeat.circle.fill" : "repeat.circle",
                            usesRow: usesRows)
                    }
                    .accessibilityValue(pageLayoutState.repeatSinglePhoto ? Text("On") : Text("Off"))
                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.repeatImageButton)
                    if usesRows { Divider().padding(.leading, 44) }
                }

                Button(action: showFormatting) {
                    ClassicPreviewActionLabel(title: L10n.BoardEditor.formatAction,
                                              symbol: "slider.horizontal.3", usesRow: usesRows)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.formattingButton)

                if usesRows { Divider().padding(.leading, 44) }

                Button(action: saveImage) {
                    ClassicPreviewActionLabel(title: L10n.PreviewPage.saveImageShortButton,
                                              symbol: "photo", usesRow: usesRows)
                }
                .accessibilityLabel(L10n.PreviewPage.saveImageButton)
                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintImageButton)
                .disabled(isSavingToPhotoLibrary)

#if EasyPECSPlus
                if usesRows { Divider().padding(.leading, 44) }

                Button(action: exportPDF) {
                    ClassicPreviewActionLabel(title: L10n.PreviewPage.savePDFButton,
                                              symbol: "doc", usesRow: usesRows)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintPDFButton)
#endif
            }
            .buttonStyle(.plain)
            .padding(4)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }

            Button(action: exportPDF) {
                Label(L10n.PreviewPage.saveButton, systemImage: "printer")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
