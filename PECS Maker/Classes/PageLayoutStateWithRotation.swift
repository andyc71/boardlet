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

    @ObservedObject var deviceOrientation = DeviceOrientationObservable()
    
    @Published var pageSize: PageSize = .a4 {
        didSet {
            updateComputedProperties(isLandscape: deviceOrientation.orientation.isLandscape)
        }
    }
    
    @Published var orientation: PageOrientation = .portrait {
        didSet {
            updateComputedProperties(isLandscape: deviceOrientation.orientation.isLandscape)
        }
    }
    
    var pageMeasurements: CGSize {
        get {
            var pm = PageMeasurements.forSize(pageSize)
            if orientation == .landscape {
                pm = pm.asLandsape()
            }
            return pm
        }
    }
    
    var aspectRatio : CGFloat {
        get {
            //let aspect: CGFloat = pageMeasurements.height / pageMeasurements.width
            let aspect: CGFloat = pageMeasurements.width / pageMeasurements.height
            //print("Aspect ratio: \(aspect)")
            return aspect
        }
    }

    init() {
        self.pageSize = .a4
        
        canc = deviceOrientation.$orientation.sink { [weak self] orientation in
            
            if !orientation.isValidInterfaceOrientation {
                return
            }
            self?.orientation = orientation.isPortrait ? .portrait : .landscape
            self?.updateComputedProperties(isLandscape: orientation.isLandscape, previousLayout: self?.pageLayout)
            
        }
    }
    
    func updateComputedProperties(isLandscape: Bool, previousLayout: PageLayout? = nil) {
        var layouts = PageLayoutType.forPageSize(pageSize)
        print("Device orientation is landscape?: \(isLandscape)")
        if isLandscape {
            for i in 0..<layouts.count {
                var layout = layouts[i]
                layout = layout.asLandsape()
                layouts[i] = layout
            }
        }
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

        guard let image = CollageFactory.createCollage(from: photos, gridSize: gridSize, pageSize: pageMeasurements ) else {
            return UIImage()
        }
        
        print("Collage Size: \(image.size)")

        return image
        
    }
    
    
    
    
}
