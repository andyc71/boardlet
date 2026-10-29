import SwiftUI
import SharedSwiftUI
import LogFramework
import LogFrameworkFirebase
import EngagementKit

/// A viewport-level prompt for an empty board. It is intentionally composed
/// outside the rendered page so it can never appear in print or export output.
struct EmptyBoardView: View {
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    @EnvironmentObject private var presentationContext: ScenePresentationContext
    @ObservedObject var pageLayoutState: PageLayoutState
    let onDismiss: () -> Void

    @State private var showARASAACSymbolsPicker = false

    private var canBrowseSymbols: Bool {
        FeatureFlags.current.arasaacSymbolsEnabled
    }

    private var canTakePhoto: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            ZStack {
                ViewThatFits(in: .vertical) {
                    EmptyBoardCard(
                        isLandscape: isLandscape,
                        canBrowseSymbols: canBrowseSymbols,
                        canTakePhoto: canTakePhoto,
                        addPhotos: addPhotos,
                        browseSymbols: browseSymbols,
                        takePhoto: takePhoto,
                        onDismiss: onDismiss
                    )
                    .padding(.horizontal, 24)
                    .padding(.vertical, isLandscape ? 8 : 12)

                    ScrollView(.vertical) {
                        EmptyBoardCard(
                            isLandscape: isLandscape,
                            canBrowseSymbols: canBrowseSymbols,
                            canTakePhoto: canTakePhoto,
                            addPhotos: addPhotos,
                            browseSymbols: browseSymbols,
                            takePhoto: takePhoto,
                            onDismiss: onDismiss
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .selectARASAACSymbols(
            isPresented: $showARASAACSymbolsPicker,
            pageLayoutState: pageLayoutState,
            isAdditive: AppSettings.photoPickerIsAdditive
        )
    }

    private func addPhotos() {
        logAction("selectPhotos")
        guard let presenter = presentationContext.presenter else { return }
        selectPhotos(
            pageLayoutState: pageLayoutState,
            isAdditive: AppSettings.photoPickerIsAdditive,
            currentTheme: currentTheme,
            from: presenter
        )
    }

    private func browseSymbols() {
        guard canBrowseSymbols else { return }
        logAction("ARASAACSymbolSearch")
        showARASAACSymbolsPicker = true
    }

    private func takePhoto() {
        guard canTakePhoto else { return }
        logAction("takePhoto")
        guard let presenter = presentationContext.presenter else { return }
        takeBoardPhoto(pageLayoutState: pageLayoutState, from: presenter)
    }

    private func logAction(_ action: String) {
        MFAnalytics.logScreenView(screenName: "\(action)FromPhotoList")
    }
}

private struct EmptyBoardCard: View {
    let isLandscape: Bool
    let canBrowseSymbols: Bool
    let canTakePhoto: Bool
    let addPhotos: () -> Void
    let browseSymbols: () -> Void
    let takePhoto: () -> Void
    let onDismiss: () -> Void

    private let cardShape = RoundedRectangle(cornerRadius: 24)

    var body: some View {
        let actionsLayout = isLandscape
            ? AnyLayout(HStackLayout(spacing: 10))
            : AnyLayout(VStackLayout(spacing: 10))
        VStack(spacing: 0) {
            EmptyBoardIllustration(compact: isLandscape)
                .padding(.bottom, isLandscape ? 6 : 10)

            Text(L10n.EmptyBoardView.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(AccessibilityIdentifiers.NoPhotosView.tipView)

            Text(L10n.EmptyBoardView.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, isLandscape ? 2 : 4)

            actionsLayout {
                BoardCompactButton(
                    action: addPhotos,
                    icon: "photo",
                    title: L10n.EmptyBoardView.addPhotosButton,
                    role: .primary
                )
                .accessibilityLabel(L10n.EmptyBoardView.addPhotosButton)
                .accessibilityHint(L10n.MainMenu.selectPhotosHint)
                .accessibilityIdentifier(AccessibilityIdentifiers.NoPhotosView.addPhotosButton)

                BoardCompactButton(
                    action: browseSymbols,
                    icon: "hare",
                    title: L10n.PhotoSourceMenu.symbol,
                    role: .secondary
                )
                .disabled(!canBrowseSymbols)
                .accessibilityLabel(L10n.PhotoSourceMenu.symbol)
                .accessibilityHint(L10n.MainMenu.symbolSearchHint)
                .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.symbolSearchButton)

                BoardCompactButton(
                    action: takePhoto,
                    icon: "camera",
                    title: L10n.EmptyBoardView.takePhotoButton,
                    role: .utility
                )
                .disabled(!canTakePhoto)
                .accessibilityLabel(L10n.EmptyBoardView.takePhotoButton)
                .accessibilityHint(L10n.MainMenu.takePhotoHint)
                .accessibilityIdentifier(AccessibilityIdentifiers.NoPhotosView.takePhotoButton)
            }
            .padding(.top, isLandscape ? 10 : 14)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, isLandscape ? 12 : 18)
        .frame(maxWidth: isLandscape ? 680 : 420)
        .background(.regularMaterial, in: cardShape)
        .overlay {
            cardShape.strokeBorder(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            Button(L10n.PhotoZoomView.closeButton, systemImage: "xmark.circle.fill", action: onDismiss)
                .labelStyle(.iconOnly)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .accessibilityIdentifier(AccessibilityIdentifiers.NoPhotosView.closeButton)
                .padding(8)
        }
        .shadow(color: .black.opacity(0.07), radius: 12, y: 6)
    }
}

private struct EmptyBoardIllustration: View {
    let compact: Bool
    @ScaledMetric(relativeTo: .title2) private var cardSize = 46.0

    var body: some View {
        let size = cardSize * (compact ? 0.82 : 1)
        ZStack {
            EmptyBoardIllustrationCard(
                symbol: "sun.max.fill",
                symbolColor: .orange,
                backgroundColor: .yellow.opacity(0.22),
                size: size
            )
            .rotationEffect(.degrees(-10))
            .offset(x: -size * 0.62, y: size * 0.08)

            EmptyBoardIllustrationCard(
                symbol: "leaf.fill",
                symbolColor: .green,
                backgroundColor: .green.opacity(0.16),
                size: size
            )
            .rotationEffect(.degrees(10))
            .offset(x: size * 0.62, y: size * 0.08)

            EmptyBoardIllustrationCard(
                symbol: "person.fill",
                symbolColor: .mfVeryBrightBlue,
                backgroundColor: .mfPaleBlue,
                size: size * 1.08
            )
        }
        .frame(width: size * 2.35, height: size * 1.35)
        .accessibilityHidden(true)
    }
}

private struct EmptyBoardIllustrationCard: View {
    let symbol: String
    let symbolColor: Color
    let backgroundColor: Color
    let size: CGFloat

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(symbolColor)
            .frame(width: size * 0.72, height: size * 0.72)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: size * 0.13))
            .padding(size * 0.10)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: size * 0.18))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.18)
                    .strokeBorder(Color(uiColor: .separator).opacity(0.22))
            }
            .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
    }
}
