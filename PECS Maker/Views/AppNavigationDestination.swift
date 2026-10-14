import SwiftUI
import SettingsFramework

/// The single mapping from board routes to screens, shared by every stack/column.
struct AppNavigationDestination: View {
    @EnvironmentObject private var navigationModel: NavigationModel
    @State private var insertedPhoto: PhotoItem?
    let route: AppRoute
    let interfaceStyle: InterfaceStyle
    let isForSplitView: Bool
    @Binding var appMode: PECSAppMode
    @Binding var selectedItems: [PhotoItem]

    private var pageLayoutState: PageLayoutState? { navigationModel.pageLayoutState }

    @ViewBuilder
    var body: some View {
        switch route {
        case .board(let id):
            if let topic = pageLayoutState?.topic, topic.id == id {
                MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode,
                    action: navigationModel.actionBinding, selectedItems: $selectedItems,
                    isForSplitView: isForSplitView)
            }
        case .menu(let action):
            menuDestination(for: action, isForSplitView: isForSplitView,
                appMode: $appMode, mainMenuAction: navigationModel.actionBinding,
                interfaceStyle: interfaceStyle)
                .boardBackButton(isPresented: !isForSplitView && action != .changeSelections)
        case .photo(let id):
            if let state = pageLayoutState {
                PhotoCellZoomed(pageLayoutState: state, photo: photoBinding(id: id),
                                onDelete: deletePhoto)
            }
        case .emptyCard(let index):
            if let state = pageLayoutState {
                PhotoCellZoomed(pageLayoutState: state, photo: emptyCardBinding(index: index),
                                onDelete: deletePhoto,
                                isEmptySlot: true, index: index)
            }
        case .boardDetails:
            if let state = pageLayoutState {
                PhotoCellZoomed(pageLayoutState: state, photo: .constant(nil),
                                onDelete: { _ in }, isBoardDetails: true)
            }
        case .allLayouts:
            if let state = pageLayoutState { AllLayoutsView(pageLayoutState: state) }
        case .credits:
            CreditsView().ignoresSafeArea().boardBackButton()
        case .diagnostics:
            DiagnosticSettingsView(settingsViewModel: SettingsViewModel(config: AppSettings.shared),
                                   largeTitle: false).boardBackButton()
        }
    }

    private func emptyCardBinding(index: Int) -> Binding<PhotoItem?> {
        Binding(get: {
            if let insertedPhoto { return insertedPhoto }
            let photos = pageLayoutState?.photoBrowserData.photoItems ?? []
            return photos.indices.contains(index) ? photos[index] : nil
        }, set: { photo in
            insertedPhoto = photo
            if photo == nil, navigationModel.path.last == .emptyCard(index) {
                navigationModel.pop()
            }
        })
    }

    private func deletePhoto(_ photo: PhotoItem) {
        pageLayoutState?.deletePhotos([photo])
        navigationModel.selectedPhotoIDs.remove(photo.itemID)
    }

    private func photoBinding(id: UUID) -> Binding<PhotoItem?> {
        Binding(get: { pageLayoutState?.photoBrowserData.photoItems.first { $0.itemID == id } },
                set: { photo in
                    if photo == nil, navigationModel.path.last == .photo(id) {
                        navigationModel.pop()
                    }
                })
    }

    @ViewBuilder
    private func menuDestination(for action: MainMenuAction, isForSplitView: Bool,
                                 appMode: Binding<PECSAppMode>, mainMenuAction: Binding<MainMenuAction?>,
                                 interfaceStyle: InterfaceStyle) -> some View {
        if action == .settings {
            SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings.shared))
        } else if let state = pageLayoutState {
            switch action {
            case .changeTopicIcon:
                TopicImageSelector(pageLayoutState: state)
            case .selectPhoto, .changeSelections:
                if interfaceStyle == .classic {
                    ClassicSelectedPhotosView(pageLayoutState: state, appMode: appMode,
                        isForSplitView: isForSplitView, dismissAction: { state.save() })
                } else {
                    PhotoListView2(pageLayoutState: state, appMode: appMode,
                        mainMenuAction: mainMenuAction, isForSplitView: isForSplitView,
                        dismissAction: { state.save() })
                }
            case .selectLayout:
                PageSizeAndLayoutView(pageLayoutState: state) {
                    state.checkmarks.didPageLayout = true
                    state.save()
                }
            case .titles:
                TitlesView(pageLayoutState: state) {
                    state.checkmarks.didTitles = true
                    state.save()
                }
            case .print:
                if interfaceStyle == .classic {
                    ClassicPreviewAndPrintView(pageLayoutState: state) {
                        state.checkmarks.didPrint = true
                        state.save()
                    }
                } else {
                    PhotoListView2(pageLayoutState: state, appMode: appMode,
                        mainMenuAction: mainMenuAction, isForSplitView: isForSplitView,
                        dismissAction: { state.save() })
                }
            case .settings:
                EmptyView() // Handled without requiring a selected board above.
            }
        }
    }
}
