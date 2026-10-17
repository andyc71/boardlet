import SwiftUI

enum PhotoSource {
    case library
    case camera
    case aacStandard
    case dynavox
    case ai
    case symbol
}

struct PhotoSourceMenu<LabelContent: View>: View {
    let libraryIdentifier: String
    var cameraIdentifier: String? = nil
    let onSelect: (PhotoSource) -> Void
    @ViewBuilder let label: () -> LabelContent

    var body: some View {
        Menu {
            Button(L10n.PhotoSelectionView.photoLibrary, systemImage: "photo") {
                onSelect(.library)
            }
            .accessibilityIdentifier(libraryIdentifier)

            if FeatureFlags.current.arasaacSymbolsEnabled {
                Button(L10n.PhotoSourceMenu.symbol, systemImage: "hare") {
                    onSelect(.symbol)
                }
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(L10n.PhotoSelectionView.camera, systemImage: "camera") {
                    onSelect(.camera)
                }
                .accessibilityIdentifier(cameraIdentifier ?? "photoSourceCamera")
            }

#if EasyPECSPlus
            Button(L10n.Symbols.aacStandard, systemImage: "square.grid.2x2") {
                onSelect(.aacStandard)
            }
            Button(L10n.Symbols.dynavox, systemImage: "square.grid.2x2") {
                onSelect(.dynavox)
            }
            Button(L10n.Symbols.createWithAI, systemImage: "sparkles") {
                onSelect(.ai)
            }
#endif
        } label: {
            label()
        }
        .menuOrder(.fixed)
    }
}
