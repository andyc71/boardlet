//
//  View+selectSymbols.swift
//  PECS Maker
//
//  Created by Andy on 19/01/2023.
//

import SwiftUI
import SharedSwiftUI
#if EasyPECSPlus
import DynavoxSymbols
import AISymbols
import AACStandardSymbols
#endif
import ARASAACSymbols

extension View {
    
#if EasyPECSPlus
    func selectAACStandardSymbols(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState,
                                  isAdditive: Bool = false, forTopic: Bool = false) -> some View {
        fullScreenCover(isPresented: isPresented) {
            AACStandardSymbolPicker(maxSelections: forTopic ? 1 : nil) { selections in
                let items = selections.compactMap { selection -> PhotoItem? in
                    guard let image = UIImage(data: selection.imageData) else { return nil }
                    let symbol = selection.symbol
                    return PhotoItem(image: image, title: symbol.title,
                        symbolSource: SymbolSource(provider: .aacStandard, symbolID: symbol.id,
                                                   languageCode: symbol.languageCode,
                                                   imageURL: symbol.imageURL, sourceURL: symbol.sourceURL))
                }
                if forTopic {
                    if let item = items.first {
                        pageLayoutState.setTopicImage(item, isUserSelection: true, saveChanges: true)
                    }
                } else if !items.isEmpty {
                    if isAdditive { pageLayoutState.photoBrowserData.add(items) }
                    else { pageLayoutState.setPhotos(items) }
                }
                isPresented.wrappedValue = false
            }
        }
    }

    ///Show a DV symbols picker popup and append the selected items in photoBrowserData.
    func selectDVSymbols(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState, isAdditive: Bool = false) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            DVSymbolPicker<DVSymbol>(completion: { symbols in
                didSelectSymbols(symbols, pageLayoutState: pageLayoutState, isAdditive: isAdditive)
                isPresented.wrappedValue = false
            })
        }
    }

#endif

    func selectARASAACSymbols(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState, isAdditive: Bool = false, maxSelections: Int? = nil, forTopic: Bool = false) -> some View {
        self.if(FeatureFlags.current.arasaacSymbolsEnabled) { view in
            view.fullScreenCover(isPresented: isPresented) {
                ARASAACSymbolPicker(maxSelections: maxSelections) { selections in
                    if !selections.isEmpty {
                        let items = selections.compactMap { selection -> PhotoItem? in
                            guard let image = UIImage(data: selection.imageData) else { return nil }
                            return PhotoItem(image: image, title: selection.symbol.title,
                                             symbolSource: SymbolSource(provider: .arasaac,
                                                                        symbolID: selection.symbol.id))
                        }
                        if forTopic {
                            if let item = items.first {
                                pageLayoutState.setTopicImage(item, isUserSelection: true, saveChanges: true)
                            }
                        } else if !items.isEmpty {
                            if isAdditive {
                                pageLayoutState.photoBrowserData.add(items)
                            } else {
                                pageLayoutState.setPhotos(items)
                            }
                        }
                    }
                    isPresented.wrappedValue = false
                }
            }
        }
    }
    
#if EasyPECSPlus
    ///Show a picker that can create new symbols through UI, and append the selected item in photoBrowserData.
    @ViewBuilder
    func selectAISymbols(isPresented: Binding<Bool>, pageLayoutState: PageLayoutState, isAdditive: Bool = false) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            if let config = AppSettings.shared.openAIConfig {
                AISymbolPicker(config: config, completion: { symbol in
                    if let symbol = symbol {
                        didSelectSymbols([symbol], pageLayoutState: pageLayoutState, isAdditive: isAdditive)
                    }
                    isPresented.wrappedValue = false
                })
            }
            else {
                Text("Error - Open AI Config not found.")
            }
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
    
#endif
}
