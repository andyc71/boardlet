//
//  View+selectSymbols.swift
//  PECS Maker
//
//  Created by Andy on 19/01/2023.
//

import SwiftUI
import SharedSwiftUI
import DynavoxSymbols
import AISymbols

extension View {
    
    ///Show a DV symbols picker popup and append the selected items in photoBrowserData.
    func selectDVSymbols(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState, isAdditive: Bool = false) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            DVSymbolPicker<DVSymbol>(completion: { symbols in
                didSelectSymbols(symbols, pageLayoutState: pageLayoutState, isAdditive: isAdditive)
                isPresented.wrappedValue = false
            })
        }
    }
    
    ///Show a picker that can create new symbols through UI, and append the selected item in photoBrowserData.
    func selectAISymbols(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState, isAdditive: Bool = false) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            AISymbolPicker(completion: { symbol in
                if let symbol = symbol {
                    didSelectSymbols([symbol], pageLayoutState: pageLayoutState, isAdditive: isAdditive)
                }
                isPresented.wrappedValue = false
            })
        }
    }
    
    ///Show a symbols picker popup and append the selected items in photoBrowserData.
    func selectTopicSymbol(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            DVSymbolPicker<DVSymbol>(maxSelections: 1, completion: { symbols in
                if let symbol = symbols.first {
                    didSelectSymbolForTopic(symbol, pageLayoutState: pageLayoutState)
                }
                isPresented.wrappedValue = false
            })
        }
    }
    
    var imageSize: CGSize { CGSize(width: 500, height: 500) }
    
    func didSelectSymbols(_ symbols: [any ImagePickerItem], pageLayoutState: PageLayoutState, isAdditive: Bool = false) {
        
        DispatchQueue.global().async {
            var photoItems = [PhotoItem]()
            for i in 0..<symbols.count {
                let symbol = symbols[i]
                let image = symbol.loadImage(size: imageSize)
                let photoItem = PhotoItem(image: image, asset: nil, title: symbol.title)
                photoItems.append(photoItem)
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
    
    func didSelectSymbolForTopic(_ symbol: DVSymbol, pageLayoutState: PageLayoutState) {
        
        DispatchQueue.global().async {
            let image = symbol.loadImage(size: imageSize)
            let photoItem = PhotoItem(image: image)
            DispatchQueue.main.async {
                pageLayoutState.setTopicImage(photoItem, isUserSelection: true, saveChanges: true)
            }
        }
    }
    
}
