//
//  TopicImageSelector.swift
//  PECS Maker
//
//  Created by Andy on 29/06/2024.
//

import SwiftUI
import SharedSwiftUI

struct TopicImageSelector: View {
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var presentationContext: ScenePresentationContext
    //var currentImage: UIImage
    
    //@State var image: UIImage = UIImage(systemSymbol: .photo)
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
#if EasyPECSPlus
    @State private var showAACStandardTopicPicker = false
#endif
    @State private var showTopicSymbolPicker: Bool = false
    @State private var showARASAACTopicPicker: Bool = false
    @State private var chooseSymbolSource: Bool = false
    
    private static var hasDynavoxSymbols: Bool {
#if EasyPECSPlus
        true
#else
        false
#endif
    }

    private var imageSize: CGFloat = 100
    
    public init(pageLayoutState: PageLayoutState) {
        self.pageLayoutState = pageLayoutState
    }
    
    var body: some View {
        
        VStack {
            Text("Current Image")
            //Text("TopicImageID: \(pageLayoutState.topicImage.itemID)")
            //Text("PageLayoutStateID: \(Unmanaged.passUnretained(pageLayoutState).toOpaque())")
            ImageViewAsync(symbol: pageLayoutState.topicImage, size: CGSize(width: imageSize, height: imageSize))
            //Image(uiImage: pageLayoutState.topicImage.loadImage(size: CGSize(width: imageSize, height: imageSize)))
            //    .resizable(true)
                .frame(width: imageSize, height: imageSize)
            
            HStack {
                Button("Use Another Photo") {
                    guard let presenter = presentationContext.presenter else { return }
                    selectTopicPhoto(currentTheme: currentTheme, from: presenter, onSelect: { selectedImage in
                        let photoItem = PhotoItem(image: selectedImage)
                        pageLayoutState.setTopicImage(photoItem, isUserSelection: true, saveChanges: true)
                        //print("PageLayoutStateID: \(Unmanaged.passUnretained(pageLayoutState).toOpaque())")
                        //print("PageLayoutStateID: \(Unmanaged.passUnretained(topicImage).toOpaque())")
                    })
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
                .padding(12)
                
                if FeatureFlags.current.arasaacSymbolsEnabled || Self.hasDynavoxSymbols {
                    Button("Use Another Symbol") {
#if EasyPECSPlus
                        chooseSymbolSource = true
#else
                        showARASAACTopicPicker = true
#endif
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicImageSelector.selectSymbolButton)
                    .padding(12)
#if EasyPECSPlus
                    .selectAACStandardSymbols(isPresented: $showAACStandardTopicPicker,
                                              pageLayoutState: pageLayoutState, forTopic: true)
                    .selectTopicSymbol(isPresented: $showTopicSymbolPicker, pageLayoutState: pageLayoutState)
                    .confirmationDialog(L10n.Symbols.library, isPresented: $chooseSymbolSource) {
                        Button(L10n.Symbols.aacStandard) { showAACStandardTopicPicker = true }
                        Button(L10n.Symbols.dynavox) { showTopicSymbolPicker = true }
                        if FeatureFlags.current.arasaacSymbolsEnabled {
                            Button(L10n.Symbols.arasaac) { showARASAACTopicPicker = true }
                        }
                    }
#endif
                    .selectARASAACSymbols(isPresented: $showARASAACTopicPicker, pageLayoutState: pageLayoutState, maxSelections: 1, forTopic: true)
                }
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo", systemImage: "camera") {
                    guard let presenter = presentationContext.presenter else { return }
                    takePhoto(from: presenter) { image in
                        pageLayoutState.setTopicImage(PhotoItem(image: image), isUserSelection: true, saveChanges: true)
                    }
                }
            }
            Button("Edit Photo", systemImage: "pencil") {
                let image = pageLayoutState.topicImage.image
                guard let presenter = presentationContext.presenter else { return }
                PhotoPresentation.edit(image, theme: currentTheme, from: presenter) { edited in
                    let item = pageLayoutState.topicImage.copy()
                    item.image = edited
                    pageLayoutState.setTopicImage(item, isUserSelection: true, saveChanges: true)
                }
            }
            .accessibilityIdentifier("editTopicPhoto")
            if !pageLayoutState.generateTopicThumbnail {
                Button(L10n.TopicImageSelector.useGeneratedThumbnailButton,
                       systemImage: "rectangle.stack") {
                    pageLayoutState.useGeneratedTopicThumbnail(saveChanges: true)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicImageSelector.useGeneratedThumbnailButton)
            }
            Spacer()
        }
        .navigationBarTitle(L10n.TopicImageSelector.title, displayMode: .inline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))

        

        
    }
}

/*
#Preview {
    TopicImageSelector()
}
*/
