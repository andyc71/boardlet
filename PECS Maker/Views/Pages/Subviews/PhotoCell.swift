//
//  PhotoCell.swift
//  PECS Maker
//
//  Created by Andy on 18/12/2022.
//

import SwiftUI
import SwiftUIX
import SharedSwiftUI
import ZLPhotoBrowser

//enum TitleAction : Equatable { case none, view(PhotoItem), rename(PhotoItem), duplicate(PhotoItem), delete(PhotoItem) }

struct PhotoCell: View {
    
    //enum SelectMode { case none, tapImage, tapIcon }
    
    @Binding var photo: PhotoItem
    var isSelected: Bool = false
    var showSelectButton: Bool = false
    var showDeleteButton: Bool = false
    var index: Int?
    var useFitzgeraldKeys: Bool
    var onTapped: (()->())?
    var onDelete: (()->())?
    
    private let isDeleteButtonInside: Bool = true
    
    //@Binding var titleAction: TitleAction
    
    private var safeIndex: Int { index ?? 0 }
    
    @State private var showDeleteTopicPrompt: Bool = false
    
    @State var imageIsZoomed: Bool = false
    
    var deleteButtonOutside : some View {
        Button(action: { showDeleteTopicPrompt = true } ) {
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.systemRed)
                .font(.title2)
        }
        .frame(width:44, height: 44)
        .offset(x: -22, y: -22)
        //TODO: Accessibility
        //.accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicDeleteButton(for: index ?? 0))
        //.accessibilityLabel(L10n.TopicSelectionView.topicDeleteButton(topic.topicName))
    }
    
    var deleteButtonInside : some View {
        Button(action: { showDeleteTopicPrompt = true } ) {
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.systemRed)
                .font(.title2)
                //.imageScale(.medium)
        }
        //.frame(width:44, height: 44)
        //.offset(x: 22, y: 22)
        //TODO: Accessibility
        //.accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicDeleteButton(for: index ?? 0))
        //.accessibilityLabel(L10n.TopicSelectionView.topicDeleteButton(topic.topicName))
    }
    
    var selectionButton : some View {
        Button(action: { onTapped?() }) {
            ZStack {
                
                if isSelected {
                    //Image(uiImage: UIImage(named: "zl_btn_selected", in: Bundle(for: ZLPhotoUIConfiguration.self), with: nil)!)
                    Image(uiImage: UIImage(named: "zl_btn_selected")!)
                }
                else {
                    //Image(uiImage: UIImage(named: "zl_btn_unselected", in: Bundle(for: ZLPhotoUIConfiguration.self), with: nil)!)
                    Image(uiImage: UIImage(named: "zl_btn_unselected")!)
                }
                /*
                 Image(systemName: SFSymbolName.circleFill)
                 .imageScale(.large)
                 .foregroundColor(Color.white)
                 if isSelected {
                 Image(systemName: SFSymbolName.checkmarkCircleFill)
                 .imageScale(.large)
                 .foregroundColor(Color.mfBrightBlue)
                 Image(systemName: SFSymbolName.circle.rawValue)
                 .imageScale(.large)
                 .foregroundColor(.white)
                 }
                 else {
                 Image(systemName: SFSymbolName.circleFill)
                 .imageScale(.large)
                 .foregroundColor(Color.white)
                 Image(systemName: SFSymbolName.circle.rawValue)
                 .imageScale(.large)
                 .foregroundColor(Color.mfBrightBlue)
                 }
                 */
                
                
            }
        }
    }
    
    var body: some View {
            Button(action: { onTapped?() }) {
                //Button(action: { imageIsZoomed.toggle() }) {
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                //                    .if(!imageIsZoomed) { view in
                //                        view.width(AppSettings.labelRowHeight)
                //                            .maxHeight(AppSettings.labelRowHeight)
                //                    }
                //                    .clipped()
                //                    .cornerRadius(5)
                    .background(.systemBackground)
                    .cornerRadius(8)
                    .shadow(radius: 8)
                    .if(showDeleteButton && !isDeleteButtonInside) { view in
                        view.overlay(deleteButtonOutside, alignment: .topLeading)
                    }
                    .if(showDeleteButton && isDeleteButtonInside) { view in
                        view.overlay(deleteButtonInside, alignment: .topLeading)
                    }
                    .if(showSelectButton) { view in
                        view.overlay(selectionButton, alignment: .topTrailing)
                    }

            }
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.image(for: safeIndex))

            //.foregroundColors(.blue, .white)
        
        
        //.padding(4)
        //.buttonStyle(RoundedButtonStyle())
        .buttonStyle(MFPlainButtonStyle(purpose: .primary))
        .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.selectButton(for: safeIndex))
        .if(isSelected) { view in
            view.accessibilityAddTraits(.isSelected)
        }
        
        .background(isSelected ? Color.systemFill : Color.clear)
        
        .askQuestionYesNo(isPresented: $showDeleteTopicPrompt,
                title: nil,
                message: L10n.DeletePhotoAlert.message,
            isDestructive: true, yesAction: {
                onDelete?()
        }, noAction: { } )

    }
}

/*
 extension View {
 func foregroundColors(_ color1: Color, _ color2: Color) -> some View {
 if #available(iOS 15.0, *) {
 return self.foregroundStyle(.blue, .white)
 } else {
 return self.foregroundColor(color1)
 }
 }
 }
 */
struct PhotoCell_Previews: PreviewProvider {
    @State static var photoItem = PhotoItem(image: UIImage(systemName: "play.square")!, title: "Music")
    static let index = 0
    static var previews: some View {
        PhotoCell(photo: $photoItem, isSelected: false, showDeleteButton: true, index: index, useFitzgeraldKeys: true,
                  onTapped: {}
        )
        .frame(width: 100, height: 100)
        //.border(Color.black, width: 1)
    }
}
