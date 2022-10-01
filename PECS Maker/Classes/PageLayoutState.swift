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
import YPImagePicker
import Photos
import SwiftyJSON

extension PageOrientation : Identifiable {
    public var id: UUID {
        return UUID()
    }
}

class PageLayoutState: ObservableObject, Codable {
    
    private var cancellables = [AnyCancellable]()
    
    @Published var photoBrowserData = PhotoBrowserData()
        
    //@Published
    private var _pageLayout = PageLayout.zero
    var pageLayout: PageLayout {
        get { return _pageLayout }
        set {
            self._pageLayout = newValue
            updateComputedProperties(newLayout: newValue)
        }
    }
    
    //@Published
    private var _pageSize: PageSize = .a4
    var pageSize: PageSize {
        get { return _pageSize }
        set {
            _pageSize = newValue
            updateComputedProperties()
        }
    }
    
    //@Published
    private var _orientation: PageOrientation = .portrait
    var orientation: PageOrientation {
        get { return _orientation }
        set {
            self._orientation = newValue
            //print("*****Orientation: \(newValue)")
            updateComputedProperties()
        }
    }

    @ObservedObject var deviceOrientation = DeviceOrientationObservable()
    
    @Published var didPageLayout: Bool = false
    @Published var didTitles: Bool = false
    @Published var didPrint: Bool = false

    @Published var repeatSinglePhoto: Bool = false {
        didSet {
            _collageForScreen = nil
        }
    }
    
    @Published var useFitzgeraldKey: Bool = true {
        didSet {
            _collageForScreen = nil
        }
    }
    
    @Published private(set) var canRepeatSinglePhoto: Bool = false
    
    
    //@Published
    private(set) var pageMeasurements2: Measurements = Measurements(CGSize.zero)
    
    //@Published
    private(set) var individualCardMeasurements: Measurements = Measurements(CGSize.zero)
    
    //@Published
    private(set) var aspectRatio : CGFloat = 1.0
    
    //@Published
    private (set) var availableLayouts =  [PageLayoutType]() {
        didSet { print(availableLayouts ) }
    }
    


    public init() {
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
        
        cancellables.append(photoBrowserData.objectWillChange.sink(receiveValue: { [weak self] photoData in
            guard let self = self else { return }
            self._collageForScreen = nil
            self._photos = nil
            //print("Here")
            //let photoCount = photoData
            self.canRepeatSinglePhoto = self.photoBrowserData.photoCount == 1
            self.autoFill()
            self.objectWillChange.send()
        }))
        
    
        
        
    }
    
    private func updateComputedProperties(newLayout: PageLayout? = nil) {
        
        _collageForScreen = nil

        let layouts = PageLayoutType.forPageSize(pageSize)
        self.availableLayouts = layouts
        
        if newLayout == nil {
            selectLayout()
        }
        
        calculatePageMeasurements()
        
        calculateIndividualCardMeasurements()

        calculateAspectRatio()
        
        DispatchQueue.main.async {
            print("*****send change")
            self.objectWillChange.send()
        }
    }
    
    func calculatePageMeasurements() {
        var size = PageMeasurements2.forSize(pageSize)
        if orientation == .landscape {
            size = size.asLandsape()
        }
        self.pageMeasurements2 = Measurements(size)
    }
    
    func calculateIndividualCardMeasurements() {
        let cardWidth = pageMeasurements2.sizeInMM.width / CGFloat(pageLayout.width)
        let cardHeight = pageMeasurements2.sizeInMM.height / CGFloat(pageLayout.height)
        self.individualCardMeasurements = Measurements(CGSize(width: cardWidth, height: cardHeight))

    }
    
    private func selectLayout() {
        for layout in availableLayouts {
            if layout.isDefault == self.orientation {
                self._pageLayout = layout
                return
            }
        }
        
        self._pageLayout = availableLayouts.first ?? PageLayout(width: 1, height: 1)
    }
    
    func calculateAspectRatio() {
        self.aspectRatio = pageMeasurements2.sizeInMM.width / pageMeasurements2.sizeInMM.height
        print("*****aspect ratio: \(self.aspectRatio)")
    }
    
    private var tempPDF: URL?
    
    public func deleteTempFiles() {
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
    
    func makeAnnotationText() -> String {
        //let newline = CharacterSet.newlines
        let newline = "\n"
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
    
    func annotatePDF(_ pdf: PDFDocument) {
        
        guard pdf.pageCount > 0 else {
            return
        }
        
        guard let page = pdf.page(at: 0) else {
            return
        }
        
        let pageSize = page.bounds(for: PDFDisplayBox.mediaBox)
        
        //let margin = CGFloat(20)
        let margin = CGFloat(0)
        let annotationSize = CGSize(width: 10, height: 10)
        let annotationBounds = CGRect(origin: CGPoint(x: margin, y: pageSize.height - (annotationSize.height + margin)), size: annotationSize)
        
        let annotation = PDFAnnotation(bounds: annotationBounds, forType: .text, withProperties: nil)
        annotation.contents = makeAnnotationText()
        annotation.backgroundColor = UIColor.white
        annotation.fontColor = UIColor.black
        
        page.addAnnotation(annotation)
    }
    
    func createPDF() -> URL? {
        
        deleteTempFiles()
        
        //Create the collage
        let pageImages = createPrintableCollage()
        
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

            guard let pdf = PDFDocument(data: data) else {
                logger.logError(.general, "Could not create PDF from pdf data")
                return nil
            }
            
            if AppSettings.keepPDFs {
                annotatePDF(pdf)
            }
            
            pdf.write(to: url)

            // Save the data to the url
            //try data.write(to: url)
            
            logger.logInfo(.general, "Saved temp PDF to: \(url.path)")
        
        //return pdfDocument
        
        tempPDF = url
        
        if AppSettings.keepPDFs {
            createArchive(of: url)
        }
        
        return url
        
    }
    
    func createArchive(of tempFileURL: URL) {
        let fileName = "PECS - \(photos.count) photos - Paper \(self.pageSize) \(self.orientation) - Layout \(self.pageLayout.shortDebugDescription).pdf"
        let archiveURL = tempFileURL.deletingLastPathComponent().appendingPathComponent(fileName)
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: archiveURL.path) {
                try fileManager.removeItem(at: archiveURL)
            }
            try fileManager.copyItem(at: tempFileURL, to: archiveURL)
            print("PDF archive copy saved to: \(archiveURL.path)")
        }
        catch {
            logger.logError(.repo, "Unable to copy item at \(tempFileURL) to \(archiveURL)")
        }
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

    var _photos: [PhotoItem]?
    
    var photos: [PhotoItem] {
        get {
            if let p = _photos {
                return p
            }
            let ps = photoBrowserData.photoItems
            _photos = ps
            return ps
        }
        set {
            _photos = newValue
            objectWillChange.send()
        }
    }
    
    func deletePhoto(at index: Int) {
        guard index < photos.count else {
            return
        }
        var photosLocal = photos
        let photoToRemove = photosLocal[index]
        photosLocal.remove(at: index)
        
        //See if the same asset exists again in the list.
        if let assetID = photoToRemove.assetId {
            if !photosLocal.contains(where: { $0.assetId == assetID } ) {
                //If not, remove it from the photo data that's used when displaying the
                //system photo picker.
                photoBrowserData.removePhoto(with: assetID)
            }
        }
        
        _collageForScreen = nil
        DispatchQueue.main.async {
            self.photos = photosLocal
            self.objectWillChange.send()
        }
    }
    
    func duplicatePhoto(at index: Int) {
        guard index < photos.count else {
            return
        }
        var photosCopy = photos
        let photoCopy = photosCopy[index].copy()
        photosCopy.insert(photoCopy, at: index + 1)
        //photosCopy.append(photoCopy)
        _collageForScreen = nil
        DispatchQueue.main.async {
            self.photos = photosCopy
            self.objectWillChange.send()
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
    
    func createPrintableCollage() -> [UIImage] {
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
        
        var photos = pageLayoutState.photos
        if repeatSinglePhoto && photos.count == 1 {
            let photoCountPerPage = Int(gridSize.height * gridSize.width)
            if let firstPhoto = photos.first {
                photos = Array(repeating: firstPhoto, count: photoCountPerPage)
            }
        }
        
        //If there are no photos, append a dummy because we want to
        //at least generate an empty collage.
        if photos.isEmpty {
            photos.append(PhotoItem(image: UIImage()))
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

            let options = CollageFormatting.shared
            //let options = self.formattingOptions
            //options.cellFillColor = AppSettings.pageColor
            //options.labelHeightPercent = AppSettings.labelHeightPercent
            //options.borderWidth = self.collageFormatting.thickGridlines ? 4 : 1
            //options.borderColor = self.collageFormatting.gridlineColor.toUIColor() ?? .black

            guard let image = CollageFactory.createCollage(from: photosForPage,
                                                           gridSize: gridSize,
                                                           pageSize: pageMeasurements,
                                                           options: options) else {
                return [UIImage()]
            }
            images.append(image)
        }
        //return pageLayoutState.createCollage(from: pageLayoutState.photoData)
        
        return images
        
    }
    
    func autoFill() {
        guard AppSettings.autoFill else {
            return
        }
        
        let photoNames = [
            "001-apple.png",
            "016-pear.png",
            "015-peach.png",
            "012-lemon.png",
            "023-strawberry.png",
            "009-grapes.png",
            "017-pineapple.png",
            "003-banana.png",
            "005-cherry.png",
        ]
        
        let bundle = Bundle(for: type(of: self))
        
        var photos = [PhotoItem]()
        for photoName in photoNames {
            guard let imageFromBundle = UIImage(named: photoName, in: bundle, with: nil) else {
                continue
            }
            
//            guard let imageURL = bundle.url(forResource: photoName, withExtension: "") else {
//                XCTFail("Unable image for \(photoName)")
//                //continuation.resume(returning: false)
//                return
//            }
//
//            let loader = ImageLoader(imageURL: imageURL, thumbnailScheme: ImageLoader.ThumbnailScheme.decodeFullImage)
//            let (image, imageMetadata) = try! loader.loadBitmapImage(maximumPixelDimensions: nil, colorSpace: nil, allowCropping: true, cancelled: nil)
//            print(imageMetadata.cameraMaker)
            
            
            //Filename is in the format 001-name.PNG
            //Title, in English, is the filename, removing the extension and the first 4
            //characters (001-)
            let title = photoName.dropLast(4).dropFirst(4)
            let titleLocalized = NSLocalizedString("FruitNames.\(title)", comment: "Fruit Name")

            let photoItem = PhotoItem(image: imageFromBundle, title: titleLocalized)
            photos.append(photoItem)
        }
        self.photos = photos

    }
    
    func clearSelections() {
        //self.photos.removeAll()
        photoBrowserData.removeAll()
    }
    

    //MARK: Codable.
    
    required init(from decoder: Decoder) throws {
        try decode(from: decoder)
    }

     private enum CodingKeys: String, CodingKey {
        case photoBrowserData
    }
    
    // The archived file name, name saved to Documents folder.
    private let dataFileName = "PageLayoutState"

    func load(folderName: String) throws {
        let url = try dataModelURL(folderName: folderName)
        if let codedData = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(PhotoBrowserData.self, from: codedData) {
                photoBrowserData = decoded
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(photoBrowserData, forKey: .photoBrowserData)
    }

    func decode(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        photoBrowserData = try values.decode(PhotoBrowserData.self, forKey: .photoBrowserData)
    }
    
    private func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private var indexFileName: String = "index.json"
    
    private func dataModelURL(folderName: String, create: Bool = false) throws -> URL {
        let docURL = documentsDirectory()
        let dataModelFolder = docURL.appendingPathComponent(folderName, isDirectory: true)
        if create {
            try FileManager.default.createDirectory(at: dataModelFolder, withIntermediateDirectories: true)
        }
        let fileURL = dataModelFolder.appendingPathComponent(indexFileName)
        return fileURL
    }

    func save(folderName: String) throws {
        let encoder = JSONEncoder()
        let url = try dataModelURL(folderName: folderName, create: true)
                
        if let encoded = try? encoder.encode(photoBrowserData) {
            do {
                try encoded.write(to: url)
            } catch {
                logger.logError(.repo, "Could not write to \(url.path)", error)
            }
        }
    }
}

// MARK: Bundle

extension Bundle {
    func decode(_ file: String) -> [PageLayoutState] {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }
        let decoder = JSONDecoder()
        guard let loaded = try? decoder.decode([PageLayoutState].self, from: data) else {
            fatalError("Failed to decode \(file) from bundle.")
        }
        return loaded
        
    }
}


