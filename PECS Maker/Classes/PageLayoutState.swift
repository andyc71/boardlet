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
import Photos
import SwiftyJSON
import PersistenceFramework

extension PageOrientation : Identifiable {
    public var id: UUID {
        return UUID()
    }
}

class PageLayoutState: ObservableObject/*, Hashable, Equatable */ {
    
    private var cancellables = [AnyCancellable]()
    
    @Published var title: String = ""
    @Published private(set) var topicImage = PhotoItem(image: UIImage(systemSymbol: .photo))
    var generateTopicThumbnail: Bool = true
    
    @Published var photoBrowserData = PhotoBrowserData()
    @Published var checkmarks = PageLayoutCheckmarks()
    @Published var lastError: Error?
    
    //@Published
    private var _pageLayout = PageLayout.zero
    var pageLayout: PageLayout {
        get { return _pageLayout }
        set {
            self._pageLayout = newValue
            updateComputedProperties(newLayout: newValue)
        }
    }
    
    @Published
    var pageSize: PageSize = .a4 {
        didSet { updateComputedProperties() }
    }
    /*
    private var _pageSize: PageSize = .a4
    var pageSize: PageSize {
        get { return _pageSize }
        set {
            _pageSize = newValue
            updateComputedProperties()
        }
    }
    */
    
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
    private (set) var availableLayouts =  [PageLayoutType]()
    
    public var topic: PECSRepo

    public init(topic: PECSRepo, setupSinks: Bool = true) {
        self.topic = topic
        load(topic: topic, shouldSetupSinks: setupSinks)
    }
    
    public init(newTopic: PECSRepo, setupSinks: Bool = true) {
        self.topic = newTopic
        initializeNewTopic(shouldSetupSinks: setupSinks)
        autoFill()
    }
    
//    public init() {
//        repoFactory = PECSRepoFactory.shared
//    }
    
    /*
    public init() {
        repoFactory = PECSRepoFactory.shared
        setDefaultProperties()
    }
     */

    
    public func setupSinks() {
        
        cancelSinks()

        //setDefaultProperties()

        //let formatting = CollageFormatting.shared
        let formatting = topic.formatting
        let canc = formatting.objectWillChange.sink( receiveValue: { [weak self] (Void) in
            
            guard let self = self else { return }
            
            self._collageForScreen = nil
            if generateTopicThumbnail {
                self.topic.topicImage = self.createTopicImage()
            }
            DispatchQueue.main.async {
                self.save()
                self.objectWillChange.send()
            }
        })
        cancellables.append(canc)

        cancellables.append(deviceOrientation.$orientation.sink { [weak self] orientation in
            
            if !orientation.isValidInterfaceOrientation {
                return
            }
            //self?.orientation = orientation.isPortrait ? .portrait : .landscape
            //self?.updateComputedProperties(isLandscape: orientation.isLandscape, previousLayout: self?.pageLayout)
            DispatchQueue.main.async {
                self?._collageForScreen = nil
                self?.objectWillChange.send()
            }
        })
        
        cancellables.append(photoBrowserData.objectWillChange.sink(receiveValue: { [weak self] photoData in
            guard let self = self else { return }
            //print("Here")
            //let photoCount = photoData
            
            //If the autofill parameter has been passed (by UI tests) then we
            //just overwrite the contents of what was selected with a known
            //set of items. It would be nice if we could preselect the items
            //in the photo browswer UI, but the autofill selections come from the
            //asset catalog and won't exist in the user's library (which the photo
            //browswer uses.
            DispatchQueue.main.async {
                self.photosDidChange()
            }
        }))
        
    }
    
    deinit {
        cancelSinks()
    }
    
    func cancelSinks() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
    }
    
    /// Changes the topic image.
    /// image: The new image for the topic
    /// isUserSeelction: True if the image was selected by the user as opposed to being auto-generated. If the image was
    /// selected by the user then we should not overwrite it later with an auto-generated thumbnails.
    /// saveChanges: True if we should save the changes to disk at this point.
    public func setTopicImage(_ image: PhotoItem, isUserSelection: Bool, saveChanges: Bool) {
        self.topicImage = image
        self.generateTopicThumbnail = !isUserSelection
        if saveChanges {
            save()
        }
    }
    
    func setDefaultProperties() {
        self.pageSize = .a4
        
        //Need to get the one from the repo because it will
        //have a localized name plus appended any necessary number.
        self.title = topic.topicName
        self.topicImage = PhotoItem(image: topic.topicImage)
        self.generateTopicThumbnail = topic.generateTopicThumbnail
        
        self.photoBrowserData.removeAll()
    }
    
    private func updateComputedProperties(newLayout: PageLayout? = nil) {
        
        _collageForScreen = nil

        let layouts = PageLayoutType.forPageSize(pageSize, orientation: self.orientation)
        self.availableLayouts = layouts
        
        if newLayout == nil {
            selectLayout()
        }
        
        calculatePageMeasurements()
        
        calculateIndividualCardMeasurements()

        calculateAspectRatio()
        
        DispatchQueue.main.async {
            //print("*****send change")
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
        guard let measurements = pageLayout.cardSize(for: pageSize, orientation: self.orientation) else {
            logger.logError(.general, "Could not calculate card measurements for page layout \(pageLayout)")
            return self.individualCardMeasurements = Measurements(CGSize(width: 100, height: 100))
        }
        self.individualCardMeasurements = measurements
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
    
    public func setPhotos(_ photoItems: [PhotoItem]) {
        if AppSettings.autoFill || AppSettings.autoFillSingle {
            return
        }
        photoBrowserData.photoItems = photoItems
    }
    
    internal func photosDidChange() {
        self._collageForScreen = nil
        //self._photos = nil
        //self.autoFill()
        self.canRepeatSinglePhoto = self.photoBrowserData.photoCount == 1
        self.save()
        self.objectWillChange.send()
    }
    
    func calculateAspectRatio() {
        self.aspectRatio = pageMeasurements2.sizeInMM.width / pageMeasurements2.sizeInMM.height
        //print("*****aspect ratio: \(self.aspectRatio)")
    }
    
    private var tempPDF: URL?
    
    public func deleteTempFiles() {
        guard let tempPDF = self.tempPDF else {
            return
        }
        do {
            try FileManager.default.removeItem(at: tempPDF)
            self.tempPDF = nil
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
            "Photo Count: \(photoBrowserData.photoItems.count)\(newline)" +
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
                  pageImage.image.draw(in: pageRect)
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
    
    /*
    @Published var didExportCollage: Bool = false
    
    func exportCollageToPhotoLibrary() {
        
        didExportCollage = false
        
        DispatchQueue.global().async {
            //Create the collage
            let pageImages = self.createPrintableCollage()
            
            do {
                
                try PHPhotoLibrary.shared().performChangesAndWait{
                    for page in pageImages {
                        PHAssetChangeRequest.creationRequestForAsset(from: page)
                    }
                }
                DispatchQueue.main.async {
                    self.didExportCollage = true
                }
            }
            catch {
                DispatchQueue.main.async {
                    self.lastError = error
                }
            }
        }
        
    }
     */
    
    ///Creates an array of items that can be shared with an UIActivityViewController
    public func createShareableItems(format: ExportCollageFormat) -> [Any] {
        //let format = AdvancedFormattingViewModel.shared.saveFormat
        var activityItems = [Any]()
        switch format {
        case .pdf:
            if let pdf = createPDF() {
                activityItems.append(pdf)
            }
        case .image:
            let pages = createPrintableCollage()
            for page in pages {
                let image = page.image
                activityItems.append(image)
            }
        }
        return activityItems
    }
    
    func createArchive(of tempFileURL: URL) {
        let fileName = "PECS - \(photoBrowserData.photoItems.count) photos - Paper \(self.pageSize) \(self.orientation) - Layout \(self.pageLayout.shortDebugDescription).pdf"
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

    /*
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
     */
    
    func deletePhoto(at index: Int) {
        _collageForScreen = nil
        photoBrowserData.deletePhoto(at: index)
    }
    
    func deletePhotos(_ photos: [PhotoItem]) {
        _collageForScreen = nil
        photoBrowserData.deletePhotos(photos)
    }
    
    func duplicatePhoto(at index: Int) {
        _collageForScreen = nil
        photoBrowserData.duplicatePhoto(at: index)
    }
    
    func duplicatePhotos(_ photos: [PhotoItem]) {
        _collageForScreen = nil
        photoBrowserData.duplicatePhotos(photos)
    }
    
    public static func copyPhotos(_ photos: [PhotoItem], to topic: PECSRepo) {
            //Create a new PageLayoutState, but don't subscribe to any
            //events because we will be done with the object in a minute.
            let pls = PageLayoutState(topic: topic, setupSinks: false)
            //Add the photos. Normally this would result in an event on
            //to the sink which causes the thumbnail to update. But because
            //we haven't setup the sinks we need to call it manually.
            pls.photoBrowserData.add(photos)
            pls.photosDidChange()
        topic.objectWillChange.send()

    }

    
//    func copyPhoto(_ photo: PhotoItem, to topic: PECSRepo) {
//        do {
//            topic.photos.add(photo: photo)
//            topic.updateThumbnail()
//            topic.saveToFile()
//            setLastError(nil)
//        }
//        catch {
//            setLastError(error)
//        }
//
//    }
    
    var _collageForScreen: [CollageItem]?
    
    struct CollageItem: Identifiable {
        var id = UUID()
        var image: UIImage
        var index: Int
    }
    
    func createCollageForScreen(maxWidth: CGFloat) -> [CollageItem] {
        if let c = _collageForScreen {
            if c.first?.image.size.width == maxWidth {
                return c
            }
        }
        
        let c = createCollage(isForPrinting: false, maxScreenWidth: maxWidth)
        _collageForScreen = c
        return c
    }
    
    func createPrintableCollage() -> [CollageItem] {
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
    
    func calculateCollageSizeForScreen3(availableSpace: CGSize) -> CGSize {
        //let maxSize = CGSize(width: screenSize.width - 20, height: screenSize.height / 2)
        //let screenSize = UIScreen.main.bounds
        let size = pageMeasurements2.convertToScreenMeasurements(.maxSize(availableSpace))
        return size
    }
    
    func createCollage(isForPrinting: Bool, maxScreenWidth: CGFloat = .infinity) -> [CollageItem] {
        
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
        
        var photos = pageLayoutState.photoBrowserData.photoItems
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
        
        var images = [CollageItem]()
        for pageNo in 0..<pageCount {
            let startIndex = pageNo * photoCountPerPage
            var endIndex = startIndex + (photoCountPerPage - 1)
            if endIndex > photos.count - 1 {
                endIndex = photos.count - 1
            }
            let photosForPage = Array(photos[startIndex...endIndex])

            //let options = CollageFormatting.shared
            let options = topic.formatting

            guard let image = CollageFactory.createCollage(from: photosForPage,
                                                           gridSize: gridSize,
                                                           pageSize: pageMeasurements,
                                                           options: options) else {
                return images
            }
            images.append(CollageItem(image: image, index: pageNo))
        }
        //return pageLayoutState.createCollage(from: pageLayoutState.photoData)
        
        return images
        
    }
    
    func autoFill() {
        guard AppSettings.autoFill || AppSettings.autoFillSingle else {
            return
        }
        
        var photoNames: [String]!
        if AppSettings.autoFill {
            photoNames = [
                "001-apple.png",
                "016-pear.png",
                "015-peach.png",
                "012-lemon.png",
                "018-plum.png",
                "009-grapes.png",
                "011-kiwi.png",
                "003-banana.png",
                "005-cherry.png",
                "010-melon.png",
                "013-mango.png",
                "006-coconut.png",
                "007-fig.png",
                "017-pineapple.png",
                "023-strawberry.png"
            ]
            
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                //Add more fruits for iPad
                photoNames.append("002-avocado.png")
                photoNames.append("004-blueberry.png")
                photoNames.append("008-durian.png")
                photoNames.append("014-papaya.png")
                photoNames.append("019-pomegranate.png")
                photoNames.append("020-raspberry.png")
                photoNames.append("024-watermelon.png")
            }
        }
        else { //.autoFillSingle
            photoNames = [ "001-apple.png" ]
        }
        
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
        //self.photos = photos
        if photoBrowserData.photoCount != photos.count {
            photoBrowserData.removeAll()
            photoBrowserData.add(photos)
            
            //CollageFormatting.reset()
            //let options = CollageFormatting.shared
            let options = topic.formatting
            DispatchQueue.main.async {
                
                options.labelPosition = .top
                
                if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    //Better for iPad Pro
                    options.labelHeightPercentage = 0.25
                }
                else {
                    //iPhone 8 Pro Max
                    options.labelHeightPercentage = 0.20
                }
                
                //options.saveToUserDefaults()
            }
            //checkmarks.didTitles = true
            //canRepeatSinglePhoto = photos.count == 1
        }
        self.save()

    }
    
    func clearSelections() {
        //self.photos.removeAll()
        photoBrowserData.removeAll()
        save()
    }

    public func load(topic: PECSRepo, shouldSetupSinks: Bool) {
        
//        guard let topic = topic else {
//            logger.logError(.repo, "Topic not set")
//            return
//        }

        //Load current repo, if it exists.
        //let repo = try repoFactory.loadRepo(topic: topic, makeActive: true, createIfMissing: false)
        //DispatchQueue.main.async {
            self.topic = topic
            self.loadPropertiesFromRepo(topic)
        if shouldSetupSinks {
            self.setupSinks()
        }
        

    }

    /*
    public func load() {
        //load(topicName: defaultTopicName)
        
        do {
            //Load current repo, if it exists.
            let repo = try repoFactory.loadCurrentRepo(makeActive: true, createIfMissing: false)
            self.topic = repo
            DispatchQueue.main.async {
                self.loadPropertiesFromRepo(repo)
            }
        }
        catch(RepoFactoryError.currentRepoNotSet) {
            //Not an error
            if repoFactory.availableTopics.count == 0 {
                do {
                    try repoFactory.createEmptyRepo(setActive: true)
                    //self.load()
                }
                catch {
                    setLastError(error)
                }
            }
            //else do nothing, because the user can select the repo to load
            //or choose to create a new one.
        }
//        catch(RepoFactoryError.repoMissing) {
//            repoFactory.currentTopic = nil
//        }
        catch {
            repoFactory.currentTopic = nil
            setLastError(error)
        }
    }
    */
    private func loadPropertiesFromRepo(_ repo: PECSRepo) {
        self.title = repo.topicName
        self.topicImage = PhotoItem(image: repo.topicImage)
        self.generateTopicThumbnail = repo.generateTopicThumbnail
        self.pageSize = repo.pageSize
        self.orientation = repo.orientation
        self.pageLayout = repo.layout

        //Don't assign to these two directly because their subscribers
        //will be pointing to the old objects still.
        self.checkmarks.copy(from: repo.checkmarks)
        self.photoBrowserData.copy(from: repo.photos)
        self.canRepeatSinglePhoto = self.photoBrowserData.photoCount == 1

        self.setLastError(nil)
        self.objectWillChange.send()
    }
    
    func setLastError(_ error: Error?) {
        DispatchQueue.main.async {
            self.lastError = error
        }
    }
    
    private func initializeNewTopic(shouldSetupSinks: Bool) {
        if shouldSetupSinks {
            setupSinks()
        }
        setDefaultProperties()
        //self.title = self.topic.topicName
        save()
    }
    
    func createTopicImage() -> UIImage{
        //return createCollageForScreen(maxWidth: 150).first ?? UIImage(systemName: "squareshape.split.3x3")!
        return createCollageForScreen(maxWidth: 500).first?.image ?? UIImage(systemName: "squareshape.split.3x3")!
    }
    
    public func save() {
        do {
            //let repo = try repoFactory.loadCurrentRepo(makeActive: true, createIfMissing: false)
//            guard let repo = self.topic else {
//                throw RepoFactoryError.currentRepoNotSet
//            }
            let repo = self.topic
            repo.topicName = title
            if generateTopicThumbnail {
                let topicImage = createTopicImage()
                self.topicImage = PhotoItem(image: topicImage)
            }
            repo.topicImage = self.topicImage.image
            repo.pageSize = pageSize
            repo.orientation = orientation
            repo.layout = pageLayout
            repo.photos = photoBrowserData
//                let message = "Could not create new topic"
//                logger.logError(.repo, message)
//                throw TopicError.saveTopic()
            repo.checkmarks = self.checkmarks
            try repo.saveToFile()
            //let topic = PECSRepo(topicName: topicName, pageSize: pageSize, orientation: orientation, layout: pageLayout, photos: photoBrowserData)
            setLastError(nil)
            //DispatchQueue.main.async {
            self.objectWillChange.send()
            //}
        }
        catch {
            setLastError(error)
        }
        
    }
    
    
}

// MARK: Bundle
/*
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
*/

