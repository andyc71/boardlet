//
//  View+selectSymbols.swift
//  PECS Maker
//
//  Created by Andy on 19/01/2023.
//

import SwiftUI
import SharedSwiftUI
import DynavoxSymbols

private let dynavoxImageRenderer = DVSymbolImageRenderer()

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
    
    @MainActor
    func didSelectSymbols(_ symbols: [DVSymbol], pageLayoutState: PageLayoutState, isAdditive: Bool = false) {
        let records = symbols.map(\.record)
        Task {
            do {
                let renderedSymbols = try await dynavoxImageRenderer.render(records, size: imageSize)
                try Task.checkCancellation()
                let photoItems = renderedSymbols.compactMap { rendered -> PhotoItem? in
                    guard let image = UIImage(data: rendered.pngData) else { return nil }
                    return PhotoItem(image: image, asset: nil, title: rendered.title)
                }
                guard photoItems.count == renderedSymbols.count else {
                    throw DVSymbolImportError.invalidRenderedImage
                }
                if isAdditive {
                    pageLayoutState.photoBrowserData.add(photoItems)
                } else {
                    pageLayoutState.setPhotos(photoItems)
                }
            } catch is CancellationError {
                return
            } catch {
                pageLayoutState.setLastError(error)
            }
        }
    }
    
    @MainActor
    func didSelectSymbolForTopic(_ symbol: DVSymbol, pageLayoutState: PageLayoutState) {
        let record = symbol.record
        Task {
            do {
                let rendered = try await dynavoxImageRenderer.render([record], size: imageSize)
                try Task.checkCancellation()
                guard let data = rendered.first?.pngData, let image = UIImage(data: data) else {
                    throw DVSymbolImportError.invalidRenderedImage
                }
                let photoItem = PhotoItem(image: image)
                pageLayoutState.setTopicImage(photoItem, isUserSelection: true, saveChanges: true)
            } catch is CancellationError {
                return
            } catch {
                pageLayoutState.setLastError(error)
            }
        }
    }
    
}

private enum DVSymbolImportError: LocalizedError {
    case invalidRenderedImage

    var errorDescription: String? {
        "A selected symbol could not be decoded."
    }
}
