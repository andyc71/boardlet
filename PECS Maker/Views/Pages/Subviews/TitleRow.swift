//
//  TitleRow.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import SwiftUI

struct TitleRow: View {
    
    @Binding var photo: PhotoItem
    var index: Int
    var useFitzgeraldKeys: Bool
    //var onImageTapped: (()->())?
    var onDelete: (()->())?
    var onDuplicate: (()->())?
    var onCategorize: (()->())?

    @State var imageIsZoomed: Bool = false
    
    var body: some View {
        HStack {
            //Button(action: { onImageTapped?() }) {
            Button(action: { imageIsZoomed.toggle() }) {
                Image(uiImage: photo.image)
                    .resizable()
                    //.frame(maxWidth: 50, maxHeight: AppSettings.labelRowHeight)
                    //.frame(maxWidth: AppSettings.labelRowHeight, maxHeight: AppSettings.labelRowHeight)
                    .aspectRatio(contentMode: ContentMode.fit)
                    .if(!imageIsZoomed) { view in
                        view.width(AppSettings.labelRowHeight)
                            .maxHeight(AppSettings.labelRowHeight)
                    }
                    .clipped()
                    .cornerRadius(5)
                    //.padding(SwiftUI.Edge.Set.trailing, 10
                    .padding(SwiftUI.Edge.Set.trailing, 4)
                    //.padding(SwiftUI.Edge.Set.bottom, 5)
                    //.padding()
                    .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.image(for: index))
            }
            if !imageIsZoomed {
                Divider()
                VStack {
                    TextField(L10n.TitlesPage.titleTextPlaceholder, text: $photo.title)
                        .padding(4)
                        .background(Color.tertiarySystemFill)
                        .cornerRadius(4)
                        .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.titleText(for: index))
                    HStack(spacing: 12) {

                        #if FitzgeraldKeysFeature
                        if useFitzgeraldKeys {
                            Picker(selection: $photo.fitzgeraldKey, label: Image(systemName: "key")) {
                                ForEach(FitzgeraldKey.allCases, id: \.self) { key in
                                    Text(key.localizedName)
                                        .tag(key)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        #endif

                        Spacer()

                        Button(action: { onDelete?() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .foregroundColor(.systemRed)
//                                Text("Delete")
//                                    .foregroundColor(.secondaryLabel)
                            }
                        }
                        .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.deleteButton(for: index))
                        //.accessibilityLabel(<#T##label: Text##Text#>)
                        
                        Button(action: { onDuplicate?() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.mfBrightBlue)
//                                Text("Duplicate")
//                                    .foregroundColor(.secondaryLabel)
                            }
                        }
                        .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.duplicateButton(for: index))
                        
                        
//                        Button(action: { onCategorize?() }) {
//                            HStack(spacing: 4) {
//                                Image(systemName: "tag")
////                                Text("Categorize")
////                                    .foregroundColor(.secondaryLabel)
//                            }
//                        }

                    }
                    Spacer()
                }
                .padding(SwiftUI.Edge.Set.leading, 4)
            }
        }
    }
}

struct TitleRow_Previews: PreviewProvider {
    @State static var photoItem = PhotoItem(image: UIImage(systemName: "music.note")!, title: "Music")
    static let index = 0
    static var previews: some View {
        TitleRow(photo: $photoItem, index: index, useFitzgeraldKeys: true)
    }
}
