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
    
    @Binding var photo: PhotoItem
    var isSelected: Bool
    var index: Int?
    var useFitzgeraldKeys: Bool
    var onTapped: (()->())?
    
    //@Binding var titleAction: TitleAction
    
    private var safeIndex: Int { index ?? 0 }

    @State var imageIsZoomed: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: { onTapped?() }) {
            //Button(action: { imageIsZoomed.toggle() }) {
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
//                    .if(!imageIsZoomed) { view in
//                        view.width(AppSettings.labelRowHeight)
//                            .maxHeight(AppSettings.labelRowHeight)
//                    }
                    .clipped()
                    .cornerRadius(5)
            }
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.image(for: safeIndex))

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
                //.foregroundColors(.blue, .white)
            }
            .padding(4)
            //.buttonStyle(RoundedButtonStyle())
            .buttonStyle(MFPlainButtonStyle(purpose: .primary))
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.selectButton(for: safeIndex))
        }
        .background(isSelected ? Color.systemFill : Color.clear)
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
    @State static var photoItem = PhotoItem(image: UIImage(systemName: "music.note")!, title: "Music")
    static let index = 0
    static var previews: some View {
        PhotoCell(photo: $photoItem, isSelected: false, index: index, useFitzgeraldKeys: true,
                  onTapped: {}
        )
        .frame(width: 100, height: 100)
    }
}
