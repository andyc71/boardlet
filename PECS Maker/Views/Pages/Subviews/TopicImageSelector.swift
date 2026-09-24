//
//  TopicImageSelector.swift
//  PECS Maker
//
//  Created by Andy on 29/06/2024.
//

import SwiftUI
import SharedSwiftUI
import ZLPhotoBrowser

struct TopicImageSelector: View {
    @EnvironmentObject private var currentTheme: SharedUITheme
    //var currentImage: UIImage
    
    //@State var image: UIImage = UIImage(systemSymbol: .photo)
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State private var showTopicSymbolPicker: Bool = false
    
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
                    selectTopicPhoto(currentTheme: currentTheme, onSelect: { selectedImage in
                        let photoItem = PhotoItem(image: selectedImage)
                        pageLayoutState.setTopicImage(photoItem, isUserSelection: true, saveChanges: true)
                        //print("PageLayoutStateID: \(Unmanaged.passUnretained(pageLayoutState).toOpaque())")
                        //print("PageLayoutStateID: \(Unmanaged.passUnretained(topicImage).toOpaque())")
                    })
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
                .padding(12)
                
#if EasyPECSPlus
                Button("Use Another Symbol") {
                        showTopicSymbolPicker = true
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
                .padding(12)
                .selectTopicSymbol(isPresented: $showTopicSymbolPicker, pageLayoutState: pageLayoutState)
#endif
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo", systemImage: "camera") {
                    takePhoto { image in
                        pageLayoutState.setTopicImage(PhotoItem(image: image), isUserSelection: true, saveChanges: true)
                    }
                }
            }
            Button("Edit Photo", systemImage: "pencil") {
                let image = pageLayoutState.topicImage.image
                ZLEditImageViewController.showEditImageVC(parentVC: PhotoPresentation.presenter, animate: true, image: image) { edited, _ in
                    pageLayoutState.setTopicImage(PhotoItem(image: edited), isUserSelection: true, saveChanges: true)
                }
            }
            .accessibilityIdentifier("editTopicPhoto")
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
