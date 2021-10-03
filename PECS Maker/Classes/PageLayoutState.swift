//
//  LayoutState.swift
//  PECS Maker
//
//  Created by Andy on 25/09/2021.
//

import UIKit
import Combine
import SwiftUI

func getPhotos(from photoData: [PhotoPickerData?]) -> [UIImage] {
        var images = [UIImage]()
        for data in photoData {
            if let image = data?.image {
                images.append(image)
            }
        }
        return images
}

enum PageOrientation: CaseIterable { case portrait, landscape }

extension PageOrientation : Identifiable {
    public var id: UUID {
        return UUID()
    }
}

class PageLayoutState: ObservableObject {
    
    private var canc: AnyCancellable!
    
    @Published var photoData = [PhotoPickerData?]()
    
    @Published var pageLayout: PageLayout = CGSize.zero

    @Published var availableLayouts =  [CGSize]() {
        didSet { print(availableLayouts ) }
    }
    
    @Published var didPageLayout: Bool = false
    @Published var didPrint: Bool = false

    @Published var pageSize: PageSize = .a4 {
        didSet {
            updateComputedProperties()
        }
    }
    
    @Published var orientation: PageOrientation = .portrait
    
    var pageMeasurements: Measurements {
        get {
            var size = PageMeasurements.forSize(pageSize)
            if orientation == .landscape {
                size = size.asLandsape()
            }
            return Measurements(size)
        }
    }
    
    var individualCardMeasurements: Measurements {
        get {
            let cardWidth = pageMeasurements.size.width / pageLayout.width
            let cardHeight = pageMeasurements.size.height / pageLayout.height
            return Measurements(CGSize(width: cardWidth, height: cardHeight))
        }
    }
    
    var aspectRatio : CGFloat {
        get {
            //let aspect: CGFloat = pageMeasurements.height / pageMeasurements.width
            let aspect: CGFloat = pageMeasurements.width / pageMeasurements.height
            print("Aspect ratio: \(aspect)")
            return aspect
        }
    }

    init() {
        self.pageSize = .a4
    }
    
    func updateComputedProperties(previousLayout: PageLayout? = nil) {
        let layouts = PageLayoutType.forPageSize(pageSize)
        self.availableLayouts = layouts
        
        if let previousLayoutUnwrapped = previousLayout {
            
            //See if we can find the exact same layout.
            for layout in layouts {
                if previousLayoutUnwrapped == layout {
                    return
                }
            }
            
            //See if there is a flipped version of the layout.
            let previousLayoutFlipped = previousLayoutUnwrapped.flipped()
            for layout in layouts {
                if layout == previousLayoutFlipped {
                    self.pageLayout = previousLayoutFlipped
                    return
                }
            }
            
        }
        
        pageLayout = availableLayouts.first ?? PageLayout(width: 1, height: 1)

    }
    

    
    func createCollage(from photoData: [PhotoPickerData?]) -> UIImage {
        
        
        //let gridSize = CGSize(width: 2, height: 3)
        //let pageMeasurements = CGSize(width: 2000, height: 3000)

        let photos = getPhotos(from: photoData)
        let gridSize = self.pageLayout
        let pageMeasurements = self.pageMeasurements
        print("Page Measurements: \(pageMeasurements)")

        guard let image = CollageFactory.createCollage(from: photos, gridSize: gridSize, pageSize: pageMeasurements.size ) else {
            return UIImage()
        }
        
        print("Collage Size: \(image.size)")

        return image
        
    }
    
    
    
    
}
