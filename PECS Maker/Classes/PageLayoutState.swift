//
//  LayoutState.swift
//  PECS Maker
//
//  Created by Andy on 25/09/2021.
//

import UIKit
import Combine
import SwiftUI
import PDFKit
import LogFramework

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
    
    @Published var photoData = [PhotoPickerData?]() {
        didSet {
            //print("Here")
            let photoCount = self.photoData.count
            while self.titles.count < photoCount {
                self.titles.append("")
            }
        }
    }
    
    @Published var titles = [String]()
    
    @Published var pageLayout: PageLayout = CGSize.zero

    @Published var availableLayouts =  [CGSize]() {
        didSet { print(availableLayouts ) }
    }
    
    @Published var didPageLayout: Bool = false
    @Published var didTitles: Bool = false
    @Published var didPrint: Bool = false

    @Published var pageSize: PageSize = .a4 {
        didSet {
            updateComputedProperties()
        }
    }
    
    @Published var orientation: PageOrientation = .portrait
    
    var pageMeasurements2: Measurements {
        get {
            var size = PageMeasurements2.forSize(pageSize)
            if orientation == .landscape {
                size = size.asLandsape()
            }
            return Measurements(size)
        }
    }
    
    var individualCardMeasurements: Measurements {
        get {
            let cardWidth = pageMeasurements2.sizeInMM.width / pageLayout.width
            let cardHeight = pageMeasurements2.sizeInMM.height / pageLayout.height
            return Measurements(CGSize(width: cardWidth, height: cardHeight))
        }
    }
    
    var aspectRatio : CGFloat {
        get {
            //let aspect: CGFloat = pageMeasurements.height / pageMeasurements.width
            let aspect: CGFloat = pageMeasurements2.sizeInMM.width / pageMeasurements2.sizeInMM.height
            print("Aspect ratio: \(aspect)")
            return aspect
        }
    }

    init() {
        self.pageSize = .a4
        //init(_ elements: Binding<[String]>){
        //self._elements = elements
        //self.titles = [String]()
        //canc = self.photoData.sink.objectWillChange.

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
    
    func createPrintableCollage(from photoData: [PhotoPickerData?]) -> UIImage {
        
        
        let photos = getPhotos(from: photoData)
        let gridSize = self.pageLayout
        
        //Create a high-resolution collage for printing.
        let highResImageMeasurements = self.pageMeasurements2.convertWithDPI(300)
        print("Page Measurements: \(highResImageMeasurements)")
                
        guard let image = CollageFactory.createCollage(from: photos, gridSize: gridSize, pageSize: highResImageMeasurements, labels: self.titles, labelHeightPercent: AppSettings.labelHeightPercent ) else {
            return UIImage()
        }
        
        print("Collage Size: \(image.size)")

        return image
        
    }
    
    var tempPDF: URL?
    
    func deleteTempFiles() {
        guard let tempPDF = self.tempPDF else {
            return
        }
        do {
            try FileManager.default.removeItem(at: tempPDF)
        }
        catch {
            logger.logError(.general, "Unable to delete temp file at \(tempPDF.path)", error)
        }
    }
    
    func createPDF(from photoData: [PhotoPickerData?]) -> URL? {
        
        deleteTempFiles()
        
        //Create the collage
        let image = createPrintableCollage(from: photoData)
        
        /*
        // Create an empty PDF document
        let pdfDocument = PDFDocument()

        // Create a PDF page instance from your image
        guard let pdfPage = PDFPage(image: image) else {
            logger.logError(.general, "Failed to create PDF page from image")
            return nil
        }

        // Insert the PDF page into your document
        pdfDocument.insert(pdfPage, at: 0)

        // Get the raw data of your PDF document
        let data = pdfDocument.dataRepresentation()
         */
        
        //From https://www.raywenderlich.com/4023941-creating-a-pdf-in-swift-with-pdfkit
        
        // 1
          let pdfMetaData = [
            kCGPDFContextCreator: "Easy PECS",
            kCGPDFContextAuthor: "meetmyfamily.org"
          ]
          let format = UIGraphicsPDFRendererFormat()
          format.documentInfo = pdfMetaData as [String: Any]

          // 2 Convert page size to 72dpi (default for PDF)
        let pageSize = self.pageMeasurements2.convertToPDFMeasurements()
        let pageRect = CGRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height)

          // 3
          let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
          // 4
          let data = renderer.pdfData { (context) in
            // 5
            context.beginPage()
            // 6
              image.draw(in: pageRect)
          }

        
        
        
        

        // The url to save the data to
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PECS.pdf")

        do {
            // Save the data to the url
            try data.write(to: url)
        }
        catch {
            logger.logError(.general, "Unable to save PDF to file \(url.path)", error)
        }
        
        //return pdfDocument
        
        tempPDF = url
        
        return url
        
    }
    
    /*
    var photoThumbnails: [UIImage] {
        get {
            let photos = self.photos
            let thumbnails = [UIImage]()
            for each photo in photos {
                let thumbnail =
            }
            
        }
    }*/

    var photos: [UIImage] {
        get {
            return getPhotos(from: self.photoData)
        }
    }
    
}
