//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI

struct LayoutView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState

    //@State var photoData: [PhotoPickerData?]
    @State var cols: Int
    @State var rows: Int
    var isSelected: Bool
    var aspectRatio: CGFloat
    
    func createColorImage(color: UIColor, size: CGSize) -> UIImage {
        //let size = CGSize(width: 10, height: 10)
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else { return UIImage() }
        return UIImage(cgImage: cgImage)
    }
    
    func createCollage() -> UIImage {

        //let gridSize = CGSize(width: 2, height: 3)
        //let pageMeasurements = CGSize(width: 2000, height: 3000)

        let gridSize = CGSize(width: cols, height: rows)
        let pageMeasurements = CGSize(width: 100, height: 100 / aspectRatio)
        print("Page Measurements for grid layout: \(pageMeasurements)")
        
        let imageColor = isSelected ? Theme.selectionHighlightUIColor : AppSettings.pageColor
        let imageMeasurements = CGSize(width: 5, height: 5 * aspectRatio)
        let colorImage = createColorImage(color: imageColor, size: imageMeasurements)
        var images = [UIImage]()
        for _ in 0..<(cols * rows) {
            images.append(colorImage)
        }
        
        //let images = getPhotos(from: pageLayoutState.photoData)
        
        var options = CollageOptions()
        options.cellFillColor = isSelected ? Theme.selectionHighlightUIColor : AppSettings.pageColor
        options.borderWidth = 1

        guard let image = CollageFactory.createCollage(
            from: images,
            gridSize: gridSize,
            pageSize: pageMeasurements,
            options: options) else {
            
            //cellFillColor: isSelected ? Theme.selectionHighlightUIColor : AppSettings.pageColor, borderWidth: 1)
            
                return UIImage()
        }
        
        print("Collage Size: \(image.size)")

        return image
        
    }
    
    var body: some View {
        VStack {

            Image(uiImage: createCollage())
                //Image(systemName: "music.note")
                .resizable()
                .aspectRatio(aspectRatio, contentMode: .fit )
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
