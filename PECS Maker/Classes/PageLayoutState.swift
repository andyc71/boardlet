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

extension PageOrientation : Identifiable {
    public var id: UUID {
        return UUID()
    }
}

class PageLayoutState: ObservableObject {
    
    private var cancellables = [AnyCancellable]()
    
    @Published var photoData = [PhotoPickerData?]() {
        didSet {
            _collageForScreen = nil
            //print("Here")
            let photoCount = self.photoData.count
            while self.titles.count < photoCount {
                self.titles.append("")
            }
            self.canRepeatSinglePhoto = photoCount == 1
        }
    }
    
    @Published var titles = [String]() {
        didSet {
            self._collageForScreen = nil
        }
    }
    
    @Published var pageLayout: PageLayout = PageLayout.zero {
        didSet {
            self._collageForScreen = nil
        }
    }

    @Published var availableLayouts =  [PageLayoutType]() {
        didSet { print(availableLayouts ) }
    }
    
    @ObservedObject var deviceOrientation = DeviceOrientationObservable()

    
    @Published var didPageLayout: Bool = false
    @Published var didTitles: Bool = false
    @Published var didPrint: Bool = false

    @Published var pageSize: PageSize = .a4 {
        didSet {
            updateComputedProperties()
        }
    }
    
    @Published var repeatSinglePhoto: Bool = false {
        didSet {
            _collageForScreen = nil
        }
    }
    
    @Published private(set) var canRepeatSinglePhoto: Bool = false
    
    @Published var orientation: PageOrientation = .portrait {
        didSet {
            _collageForScreen = nil
        }
    }
    
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
            let cardWidth = pageMeasurements2.sizeInMM.width / CGFloat(pageLayout.width)
            let cardHeight = pageMeasurements2.sizeInMM.height / CGFloat(pageLayout.height)
            return Measurements(CGSize(width: cardWidth, height: cardHeight))
        }
    }
    
    var aspectRatio : CGFloat {
        get {
            //let aspect: CGFloat = pageMeasurements.height / pageMeasurements.width
            let aspect: CGFloat = pageMeasurements2.sizeInMM.width / pageMeasurements2.sizeInMM.height
            //print("Aspect ratio: \(aspect)")
            return aspect
        }
    }

    init() {
        self.pageSize = .a4
        //init(_ elements: Binding<[String]>){
        //self._elements = elements
        //self.titles = [String]()
        //canc = self.photoData.sink.objectWillChange.
        
        let canc = CollageFormatting.shared.objectWillChange.sink(receiveValue: { (Void) in
            self._collageForScreen = nil
            self.objectWillChange.send()
        })
        cancellables.append(canc)

        cancellables.append(deviceOrientation.$orientation.sink { [weak self] orientation in
            
            if !orientation.isValidInterfaceOrientation {
                return
            }
            //self?.orientation = orientation.isPortrait ? .portrait : .landscape
            //self?.updateComputedProperties(isLandscape: orientation.isLandscape, previousLayout: self?.pageLayout)
            self?._collageForScreen = nil
            self?.objectWillChange.send()
        })

        
    }
    
    func updateComputedProperties(previousLayout: PageLayout? = nil) {
        
        _collageForScreen = nil

        let layouts = PageLayoutType.forPageSize(pageSize)
        self.availableLayouts = layouts
        
        /*
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
            
        }*/
        
        for layout in layouts {
            if layout.isDefault == self.orientation {
                self.pageLayout = layout
                return
            }
        }
        
        pageLayout = availableLayouts.first ?? PageLayout(width: 1, height: 1)

    }
    
    var tempPDF: URL?
    
    func deleteTempFiles() {
        
        if AppSettings.keepPDFs {
            return
        }
        
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
    
    func makeDocumentTitle() -> String {
        let newline = CharacterSet.newlines
        let title =
            "PECS Cards\(newline)" +
            "Photo Count: \(photos.count)\(newline)" +
            "Repeat Single Photo?: \(repeatSinglePhoto)\(newline)" +
            "Page Size: \(pageSize)\(newline)" +
            "Page Orientation: \(self.orientation)\(newline)" +
            "Grid Size: \(pageLayout.width)x\(pageLayout.height)\(newline)" +
            "Page Measurements (mm): \(pageMeasurements2.formatAs(measurementType: .mm))\(newline)" +
            "Page Measurements (in): \(pageMeasurements2.formatAs(measurementType: .inches))\(newline)" +
            "Individual Card Size (mm): \(individualCardMeasurements.formatAs(measurementType: .mm))\(newline)" +
            "Individual Card Size (in): \(individualCardMeasurements.formatAs(measurementType: .inches))\(newline)"
        return title
    }
    
    func createPDF(from photoData: [PhotoPickerData?]) -> URL? {
        
        deleteTempFiles()
        
        //Create the collage
        let pageImages = createPrintableCollage(from: photoData)
        
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
            kCGPDFContextAuthor: "meetmyfamily.org",
            kCGPDFContextTitle: "PECS Cards",
            //kCGPDFContextTitle: makeDocumentTitle(),
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
              for pageImage in pageImages {
                  context.beginPage()
                  // 6
                  pageImage.draw(in: pageRect)
              }
          }
        

        // The url to save the data to
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PECS.pdf")

        do {
            // Save the data to the url
            try data.write(to: url)
            logger.logInfo(.general, "Saved temp PDF to: \(url.path)")
        }
        catch {
            logger.logError(.general, "Unable to save PDF to file: \(url.path)", error)
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
    
    var _collageForScreen: [UIImage]?
    
    func createCollageForScreen(maxWidth: CGFloat) -> [UIImage] {
        if let c = _collageForScreen {
            if c.first?.size.width == maxWidth {
                return c
            }
        }
        
        let c = createCollage(isForPrinting: false, maxScreenWidth: maxWidth)
        _collageForScreen = c
        return c
    }
    
    func createPrintableCollage(from photoData: [PhotoPickerData?]) -> [UIImage] {
        return createCollage(isForPrinting: true)
    }
    
    func calculateCollageSizeForScreen(maxWidth: CGFloat) -> CGSize {
        let size = pageMeasurements2.convertToScreenMeasurements(.maxWidth(maxWidth))
        return size
    }

    func calculateCollageSizeForScreen2() -> CGSize {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            let size = pageMeasurements2.convertToScreenMeasurements(.maxWidth(250))
//            return size
//        }
//        else {
            let screenSize = UIScreen.main.bounds
            let maxSize = CGSize(width: screenSize.width - 20, height: screenSize.height / 2)
            let size = pageMeasurements2.convertToScreenMeasurements(.maxSize(maxSize))
            return size
//        }
    }

    
    func createCollage(isForPrinting: Bool, maxScreenWidth: CGFloat = .infinity) -> [UIImage] {
        
        let pageLayoutState = self
        
        var pageMeasurements: CGSize
        if isForPrinting {
            //Create a high-resolution collage for printing.
            pageMeasurements = self.pageMeasurements2.convertWithDPI(300)
        }
        else {
            pageMeasurements = pageLayoutState.pageMeasurements2.convertToScreenMeasurements(.maxWidth( maxScreenWidth))
        }
        //print("Page Measurements for grid layout: \(pageMeasurements)")

        
        let gridSize = pageLayoutState.pageLayout
        let photoCountPerPage = Int(gridSize.height * gridSize.width)
        
        var photos = getPhotos(from: pageLayoutState.photoData)
        var titles = pageLayoutState.titles
        if repeatSinglePhoto && photos.count == 1 {
            let photoCountPerPage = Int(gridSize.height * gridSize.width)
            if let firstPhoto = photos.first {
                photos = Array(repeating: firstPhoto, count: photoCountPerPage)
            }
            if let firstTitle = titles.first {
                titles = Array(repeating: firstTitle, count: photoCountPerPage)
            }
        }
        
        //If there are no photos, append a dummy because we want to
        //at least generate an empty collage.
        if photos.isEmpty {
            photos.append(UIImage())
            titles.append("")
        }
        
        //let pageCount = photos.count / photoCountPerPage
        let pageCount = Int(ceil(Double(photos.count) / Double(photoCountPerPage)))
        
        var images = [UIImage]()
        for pageNo in 0..<pageCount {
            let startIndex = pageNo * photoCountPerPage
            var endIndex = startIndex + (photoCountPerPage - 1)
            if endIndex > photos.count - 1 {
                endIndex = photos.count - 1
            }
            let photosForPage = Array(photos[startIndex...endIndex])
            let titlesForPage = Array(titles[startIndex...endIndex])

            let options = CollageFormatting.shared
            //let options = self.formattingOptions
            //options.cellFillColor = AppSettings.pageColor
            //options.labelHeightPercent = AppSettings.labelHeightPercent
            //options.borderWidth = self.collageFormatting.thickGridlines ? 4 : 1
            //options.borderColor = self.collageFormatting.gridlineColor.toUIColor() ?? .black

            guard let image = CollageFactory.createCollage(from: photosForPage,
                                                           gridSize: gridSize,
                                                           pageSize: pageMeasurements,
                                                           labels: titlesForPage,
                                                           options: options) else {
                return [UIImage()]
            }
            images.append(image)
        }
        //return pageLayoutState.createCollage(from: pageLayoutState.photoData)
        
        return images
        
    }
    
    
}
