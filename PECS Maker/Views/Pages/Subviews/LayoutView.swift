//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI

struct LayoutView: View, Equatable {
    
    static func == (lhs: LayoutView, rhs: LayoutView) -> Bool {
        lhs.layout == rhs.layout &&
        lhs.pageLayoutState.aspectRatio == rhs.pageLayoutState.aspectRatio &&
        lhs.isSelected == rhs.isSelected
    }
    
    @ObservedObject var pageLayoutState: PageLayoutState

    //@State var photoData: [PhotoPickerData?]
    @State var layout: PageLayoutType
    @State var isSelected: Bool
    
    func createColorImage(color: Color, size: CGSize) -> UIImage {
        //let size = CGSize(width: 10, height: 10)
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.toUIColor()?.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else { return UIImage() }
        return UIImage(cgImage: cgImage)
    }
    
    func createCollage() -> UIImage {
        let pageMeasurements = CGSize(width: 100, height: 100 / pageLayoutState.aspectRatio)
        //print("Page Measurements for paper size \(pageLayoutState.pageSize) orientation: \(pageLayoutState.orientation) grid layout: \(layout) - \(pageMeasurements) aspect aspect: \(pageLayoutState.aspectRatio)")
        
        let options = CollageFormatting()
        options.cellFillColor = isSelected ? Theme.selectionHighlightColor : AppSettings.pageColor
        options.gridlinesThick = false
        
//        let imageColor = options.cellFillColor
//        let imageMeasurements = CGSize(width: 5, height: 5 / aspectRatio)
//        let colorImage = createColorImage(color: imageColor, size: imageMeasurements)
//        var images = [UIImage]()
//        for _ in 0..<(cols * rows) {
//            images.append(colorImage)
//        }
        
        //let images = getPhotos(from: pageLayoutState.photoData)

        guard let image = CollageFactory.createCollage(
            from: [],
            gridSize: layout,
            pageSize: pageMeasurements,
            options: options) else {
                return UIImage()
        }
        
        return image
        
    }
    
    var body: some View {
        VStack {

            Image(uiImage: createCollage())
                //Image(systemName: "music.note")
                .resizable()
                .aspectRatio(pageLayoutState.aspectRatio, contentMode: .fit )
                //.padding()
                .border(Color(UIColor.secondaryLabel), width: 1)
//                .if(isVertical) { view in
//                    view.frame(maxHeight: .infinity)
//                }
//                .if(!isVertical) { view in
//                    view.frame(maxWidth: .infinity)
//                }
        }
    }

    
}

//struct LayoutView_Previews: PreviewProvider {
//    static var previews: some View {
//        LayoutView(cols: 2, rows: 3, isSelected: false, aspectRatio: 0.7)
//    }
//}
