//
//  View+selectSymbols.swift
//  PECS Maker
//
//  Created by Andy on 19/01/2023.
//

import SwiftUI
import SharedSwiftUI
import DynavoxSymbols

extension View {
    
    ///Show a symbols picker popup and append the selected items in photoBrowserData.
    func selectSymbols(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState, isAdditive: Bool = false) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            DVSymbolPicker<DVSymbol>(completion: { symbols, trimWhitespace in
                didSelectSymbols(symbols, trimWhitespace: trimWhitespace, pageLayoutState: pageLayoutState, isAdditive: isAdditive)
                isPresented.wrappedValue = false
            })
        }
    }
    
    ///Show a symbols picker popup and append the selected items in photoBrowserData.
    func selectTopicSymbol(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            DVSymbolPicker<DVSymbol>(maxSelections: 1, completion: { symbols, trimWhitespace in
                if let symbol = symbols.first {
                    didSelectSymbolForTopic(symbol, trimWhitespace: trimWhitespace, pageLayoutState: pageLayoutState)
                }
                isPresented.wrappedValue = false
            })
        }
    }
    
    var imageSize: CGSize { CGSize(width: 500, height: 500) }
    
    func didSelectSymbols(_ symbols: [DVSymbol], trimWhitespace: Bool, pageLayoutState: PageLayoutState, isAdditive: Bool = false) {
        
        DispatchQueue.global().async {
            var photoItems = [PhotoItem]()
            for i in 0..<symbols.count {
                let symbol = symbols[i]
                if let image = symbol.image(size: imageSize, trimWhitespace: trimWhitespace) {
                    let photoItem = PhotoItem(image: image, asset: nil, title: symbol.label)
                    photoItems.append(photoItem)
                }
            }
            DispatchQueue.main.async {
                //Updating the photoBrowserData will automatically call save on the repo.
                if isAdditive {
                    pageLayoutState.photoBrowserData.add(photoItems)
                }
                else {
                    pageLayoutState.setPhotos(photoItems)
                    //photoBrowserData.photoItems = photoItems
                    //self.save()
                }
            }
        }
    }
    
    func didSelectSymbolForTopic(_ symbol: DVSymbol, trimWhitespace: Bool, pageLayoutState: PageLayoutState) {
        
        DispatchQueue.global().async {
            var photoItems = [PhotoItem]()
            if let image = symbol.image(size: imageSize, trimWhitespace: trimWhitespace) {
                let photoItem = PhotoItem(image: image)
                DispatchQueue.main.async {
                    pageLayoutState.setTopicImage(photoItem, isUserSelection: true, saveChanges: true)
                }
            }
        }
    }
    
}
