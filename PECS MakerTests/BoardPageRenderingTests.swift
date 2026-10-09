import XCTest
import SwiftUI
import PDFKit
@testable import PECS_Maker

@MainActor
final class BoardEditorRenderingTests: PersistenceTestsBase {
    func testPageLayoutDistinguishesFixedAspectChoices() {
        for (width, height) in [(1, 3), (3, 1)] {
            let fitted = PageLayout(width: width, height: height)
            let square = PageLayout(width: width, height: height, fixedCardAspectRatio: 1)
            let wide = PageLayout(width: width, height: height, fixedCardAspectRatio: 0.5)
            XCTAssertNotEqual(fitted, square)
            XCTAssertNotEqual(square, wide)
            XCTAssertEqual(Set([fitted, square, wide]).count, 3)
        }
    }

    func testPageLayoutIdentityIsStableAcrossReadsAndCopies() throws {
        let layout = PageLayout(width: 3, height: 4, fixedCardAspectRatio: 1, isDefault: .portrait)
        let restored = try JSONDecoder().decode(PageLayout.self, from: JSONEncoder().encode(layout))
        XCTAssertEqual(layout, restored)
        XCTAssertEqual(layout.hashValue, restored.hashValue)
        XCTAssertEqual(layout.id, layout.id)
        XCTAssertEqual(layout.id, restored.id)
        XCTAssertEqual(Set([layout, restored]).count, 1)
    }

    func testAllAvailableLayoutsHaveConsistentSetIdentity() {
        for pageSize in PageSize.allCases {
            for orientation in PageOrientation.allCases {
                let layouts = PageLayout.forPageSize(pageSize, orientation: orientation)
                // Expanded layout choices include fitted and square variants with
                // identical row/column counts. SwiftUI diffs these in hashed sets.
                let unique = Set(layouts + layouts.reversed())
                XCTAssertEqual(unique.count, layouts.count, "\(pageSize), \(orientation)")
                XCTAssertTrue(layouts.allSatisfy { unique.contains($0) })
                XCTAssertEqual(Set(layouts.map(\.id)), unique)
            }
        }
    }

    private func printableCardSize(
        for layout: PageLayout,
        pageSize: PageSize,
        orientation: PageOrientation,
        title: String? = nil,
        formatting: CollageFormatting = CollageFormatting(),
        attribution: String? = nil
    ) -> Measurements? {
        layout.printableCardSize(
            for: pageSize,
            orientation: orientation,
            title: title,
            style: BoardRenderStyle(formatting),
            attribution: attribution
        )
    }

    private func layoutSections(
        pageSize: PageSize,
        orientation: PageOrientation
    ) -> [PageLayoutSection] {
        PageLayoutSection.make { layout in
            printableCardSize(for: layout, pageSize: pageSize, orientation: orientation)
        }
    }

    func testLayoutSectionsHaveTheRequestedOrderAndPresets() throws {
        XCTAssertEqual(PageLayoutPreset.allCases, [.large, .medium, .small])
        for pageSize in PageSize.allCases {
            for orientation in PageOrientation.allCases {
                let sections = layoutSections(pageSize: pageSize, orientation: orientation)
                XCTAssertEqual(sections.map(\.kind), [.recommended, .singleRow, .allSizes])
                XCTAssertEqual(
                    try XCTUnwrap(sections.first { $0.kind == .recommended }).layouts.compactMap(\.preset),
                    PageLayoutPreset.allCases
                )
                XCTAssertEqual(
                    try XCTUnwrap(sections.first { $0.kind == .singleRow }).layouts.compactMap(\.preset),
                    PageLayoutPreset.allCases
                )
            }
        }
    }

    func testFeaturedLayoutsIncludeASelectedNonRecommendedLayout() throws {
        let state = try state(count: 0)
        let recommended = try XCTUnwrap(
            state.layoutSections.first(where: { $0.kind == .recommended })?.layouts
        )
        let selected = try XCTUnwrap(
            state.layoutSections
                .first(where: { $0.kind == .allSizes })?
                .layouts
                .first(where: { choice in
                    !recommended.contains(where: { $0.layout == choice.layout })
                })
        )

        state.pageLayout = selected.layout

        XCTAssertEqual(state.featuredLayoutChoices.dropLast().map(\.layout), recommended.map(\.layout))
        XCTAssertEqual(state.featuredLayoutChoices.last?.layout, selected.layout)
        XCTAssertEqual(
            Set(state.featuredLayoutChoices.map(\.id)).count,
            state.featuredLayoutChoices.count,
            "The appended selection must not reuse a recommended preset ID"
        )

        state.pageLayout = recommended[1].layout
        XCTAssertEqual(state.featuredLayoutChoices.map(\.layout), recommended.map(\.layout))
    }

    func testRecommendedPresetsUseTheClosestSupportedCardGrid() throws {
        for pageSize in PageSize.allCases {
            for orientation in PageOrientation.allCases {
                let sections = layoutSections(pageSize: pageSize, orientation: orientation)
                let recommended = try XCTUnwrap(sections.first { $0.kind == .recommended })
                let candidates = try XCTUnwrap(sections.first { $0.kind == .allSizes })
                    .layouts
                    .filter { $0.layout.width > 1 && $0.layout.height > 1 }

                for choice in recommended.layouts {
                    let preset = try XCTUnwrap(choice.preset)
                    let selectedDistance = PageLayoutSection.distance(
                        from: choice.cardSize,
                        to: preset.targetSizeInMillimetres
                    )
                    XCTAssertGreaterThan(choice.layout.width, 1)
                    XCTAssertGreaterThan(choice.layout.height, 1)
                    XCTAssertNil(choice.layout.fixedCardAspectRatio)
                    XCTAssertGreaterThanOrEqual(
                        PageLayoutSection.effectiveSize(of: choice.cardSize),
                        PageLayoutSection.minimumSupportedSize
                    )
                    for candidate in candidates {
                        XCTAssertLessThanOrEqual(
                            selectedDistance,
                            PageLayoutSection.distance(
                                from: candidate.cardSize,
                                to: preset.targetSizeInMillimetres
                            ) + 0.000_001
                        )
                    }
                }
            }
        }
    }

    func testSingleRowPresetsUseTheClosestSupportedSquareCards() throws {
        for pageSize in PageSize.allCases {
            for orientation in PageOrientation.allCases {
                let sections = layoutSections(pageSize: pageSize, orientation: orientation)
                let singleRows = try XCTUnwrap(sections.first { $0.kind == .singleRow })
                let candidates = (1...PageLayout.maxColumns).compactMap { columns -> Measurements? in
                    let layout = PageLayout(width: columns, height: 1, fixedCardAspectRatio: 1)
                    guard let size = printableCardSize(
                        for: layout,
                        pageSize: pageSize,
                        orientation: orientation
                    ), PageLayoutSection.effectiveSize(of: size) >= PageLayoutSection.minimumSupportedSize else {
                        return nil
                    }
                    return size
                }

                for choice in singleRows.layouts {
                    let preset = try XCTUnwrap(choice.preset)
                    let selectedDistance = PageLayoutSection.distance(
                        from: choice.cardSize,
                        to: preset.targetSizeInMillimetres
                    )
                    XCTAssertEqual(choice.layout.height, 1)
                    XCTAssertEqual(choice.layout.fixedCardAspectRatio, 1)
                    XCTAssertEqual(choice.cardSize.sizeInMM.width, choice.cardSize.sizeInMM.height, accuracy: 0.001)
                    for candidate in candidates {
                        XCTAssertLessThanOrEqual(
                            selectedDistance,
                            PageLayoutSection.distance(
                                from: candidate,
                                to: preset.targetSizeInMillimetres
                            ) + 0.000_001
                        )
                    }
                }
            }
        }
    }

    func testAllSizesAreColumnFirstAndStopAtThe25MillimetreMinimum() throws {
        for pageSize in PageSize.allCases {
            for orientation in PageOrientation.allCases {
                let allSizes = try XCTUnwrap(
                    layoutSections(pageSize: pageSize, orientation: orientation)
                        .first { $0.kind == .allSizes }
                )
                var expected = [PageLayout]()
                for columns in 1...PageLayout.maxColumns {
                    for rows in 1...PageLayout.maxRows {
                        let layout = PageLayout(width: columns, height: rows)
                        guard let size = printableCardSize(
                            for: layout,
                            pageSize: pageSize,
                            orientation: orientation
                        ), PageLayoutSection.effectiveSize(of: size) >= 25 else {
                            continue
                        }
                        expected.append(layout)
                    }
                }

                XCTAssertEqual(allSizes.layouts.map(\.layout), expected)
                XCTAssertTrue(allSizes.layouts.allSatisfy { $0.preset == nil })
                XCTAssertTrue(allSizes.layouts.allSatisfy {
                    PageLayoutSection.effectiveSize(of: $0.cardSize) >= 25
                })
            }
        }
    }

    func testExactly25MillimetresIsSupportedAndAnythingSmallerIsExcluded() throws {
        let sections = PageLayoutSection.make { layout in
            if layout.fixedCardAspectRatio != nil {
                let side = 100 / CGFloat(layout.width)
                return Measurements(CGSize(width: side, height: side))
            }
            return Measurements(CGSize(
                width: 100 / CGFloat(layout.width),
                height: 100 / CGFloat(layout.height)
            ))
        }
        let allSizes = try XCTUnwrap(sections.first { $0.kind == .allSizes })

        XCTAssertEqual(PageLayout.minCardSize, CGSize(width: 25, height: 25))
        XCTAssertTrue(allSizes.layouts.map(\.layout).contains(PageLayout(width: 4, height: 4)))
        XCTAssertFalse(allSizes.layouts.map(\.layout).contains(PageLayout(width: 4, height: 5)))
        XCTAssertFalse(allSizes.layouts.map(\.layout).contains(PageLayout(width: 5, height: 4)))
    }

    func testSingleSquareCardFitsWithinBothPageDimensions() {
        let size = PageLayout.cardSize(
            pageSize: CGSize(width: 100, height: 150),
            pageLayout: PageLayout(width: 1, height: 1, fixedCardAspectRatio: 1)
        )
        XCTAssertEqual(size.width, 100, accuracy: 0.001)
        XCTAssertEqual(size.height, 100, accuracy: 0.001)
    }

    func testPrintableCardSizeUsesTheSharedPostConstraintGeometry() throws {
        let formatting = CollageFormatting()
        formatting.pageTitleVisible = true
        formatting.pageTitleHeightPercentage = 0.12
        let title = "Board title"
        let attribution = "Symbol attribution\nSecond credit"

        for pageSize in PageSize.allCases {
            for orientation in PageOrientation.allCases {
                let pageInPoints = Measurements(
                    PageMeasurements2.forSize(pageSize, orientation: orientation)
                ).convertToPDFMeasurements()
                for layout in PageLayout.forPageSize(pageSize, orientation: orientation) {
                    let geometry = BoardPageGeometry(
                        pageSize: pageInPoints,
                        layout: layout,
                        title: title,
                        style: BoardRenderStyle(formatting),
                        attribution: attribution
                    )
                    let cardSize = try XCTUnwrap(printableCardSize(
                        for: layout,
                        pageSize: pageSize,
                        orientation: orientation,
                        title: title,
                        formatting: formatting,
                        attribution: attribution
                    ))
                    XCTAssertEqual(cardSize.sizeInMM.width, geometry.cellSizeInMillimetres.width, accuracy: 0.001)
                    XCTAssertEqual(cardSize.sizeInMM.height, geometry.cellSizeInMillimetres.height, accuracy: 0.001)
                }
            }
        }
    }

    func testOverflowIndicatorsTrackEdgesAndExcludeFittedAxis() {
        let size = CGSize(width: 400, height: 600)
        let start = BoardPageViewport.Overflow(contentFrame: CGRect(x: 0, y: 0, width: 1000, height: 600), viewport: size, axes: .horizontal)
        XCTAssertTrue(start.right)
        XCTAssertFalse(start.left || start.top || start.bottom)
        let end = BoardPageViewport.Overflow(contentFrame: CGRect(x: -600, y: 0, width: 1000, height: 600), viewport: size, axes: .horizontal)
        XCTAssertTrue(end.left)
        XCTAssertFalse(end.right || end.top || end.bottom)
        let middle = BoardPageViewport.Overflow(contentFrame: CGRect(x: 0, y: -100, width: 400, height: 1200), viewport: size, axes: .vertical)
        XCTAssertTrue(middle.top && middle.bottom)
        XCTAssertFalse(middle.left || middle.right)
    }

    func testFillingLaterBlankSlotPreservesPositionAndPersistsPlaceholders() async throws {
        let state = try state(count: 2, layout: PageLayout(width: 3, height: 4))
        let inserted = try XCTUnwrap(state.photoBrowserData.fillEmptySlot(at: 7, with: PhotoItem.blankCard(title: "Slot eight")))
        XCTAssertEqual(state.photoBrowserData.photoCount, 8)
        XCTAssertTrue(state.photoBrowserData.photoItems[2..<7].allSatisfy(\.isPlaceholder))
        XCTAssertEqual(state.photoBrowserData.photoItems[7].itemID, inserted.itemID)
        XCTAssertFalse(inserted.isPlaceholder)
        state.save()
        state.flushThumbnail()
        let restored = try PECSRepo.load(directory: tempDir)
        XCTAssertEqual(restored.photos.photoItems[7].title, "Slot eight")
        XCTAssertTrue(restored.photos.photoItems[2].isPlaceholder)
        let model = BoardPageRenderModel()
        await model.prepare(state: state, pageIndex: 0, viewport: CGSize(width: 390, height: 600), zoom: 1, displayScale: 2)
        XCTAssertTrue(try XCTUnwrap(model.page).cards[2].isBlank)
        XCTAssertNil(model.page?.cards[2].image)
        let placeholder = restored.photos.photoItems[2].copy()
        XCTAssertTrue(placeholder.isPlaceholder)
        placeholder.title = "Now a card"
        XCTAssertFalse(placeholder.isPlaceholder)
        let replaced = restored.photos.photoItems[3]
        replaced.image = image()
        XCTAssertFalse(replaced.isPlaceholder)
    }

    func testNearlyMatchingViewportDoesNotCreateTinyScrollRange() {
        for delta in [-1.0, 0, 1.0] {
            let viewport = BoardPageViewport(pageSize: CGSize(width: 600, height: 840), cellSize: CGSize(width: 300, height: 300),
                viewport: CGSize(width: 624 + delta, height: 864), zoom: 1)
            XCTAssertTrue(viewport.scrollAxes.isEmpty)
            XCTAssertLessThanOrEqual(viewport.displaySize.width, 600 + delta + 0.001)
            XCTAssertLessThanOrEqual(viewport.displaySize.height, 840.001)
        }
    }

    func testBoardZoomClampsAndAccessibilityStepsStayWithinRange() {
        XCTAssertEqual(BoardPageViewport.clampedZoom(0.1), 0.25)
        XCTAssertEqual(BoardPageViewport.clampedZoom(3), 2)
        XCTAssertEqual(BoardPageViewport.zoomedIn(from: 1), 1.25)
        XCTAssertEqual(BoardPageViewport.zoomedIn(from: 2), 2)
        XCTAssertEqual(BoardPageViewport.zoomedOut(from: 1.5), 1.25)
        XCTAssertEqual(BoardPageViewport.zoomedOut(from: 0.5), 0.25)
        XCTAssertEqual(BoardPageViewport.zoomedOut(from: 0.25), 0.25)

        let zoomedOut = BoardPageViewport(pageSize: CGSize(width: 840, height: 600), cellSize: CGSize(width: 300, height: 300),
            viewport: CGSize(width: 390, height: 624), zoom: BoardPageViewport.minimumZoom)
        XCTAssertLessThan(zoomedOut.displaySize.width, 390 - 2 * BoardPageViewport.inset)
        XCTAssertLessThan(zoomedOut.displaySize.height, 624 - 2 * BoardPageViewport.inset)
        XCTAssertTrue(zoomedOut.scrollAxes.isEmpty)
    }

    func testViewportFillsSpaceAndScrollsOnlyOverflowingAxes() {
        let landscape = BoardPageViewport(pageSize: CGSize(width: 840, height: 600), cellSize: CGSize(width: 100, height: 100),
            viewport: CGSize(width: 390, height: 624), zoom: 1)
        XCTAssertEqual(landscape.displaySize.height, 600, accuracy: 0.001)
        XCTAssertGreaterThan(landscape.displaySize.width, 366)
        XCTAssertEqual(landscape.scrollAxes, .horizontal)

        let portrait = BoardPageViewport(pageSize: CGSize(width: 600, height: 840), cellSize: CGSize(width: 100, height: 100),
            viewport: CGSize(width: 824, height: 424), zoom: 1)
        XCTAssertEqual(portrait.displaySize.width, 800, accuracy: 0.001)
        XCTAssertGreaterThan(portrait.displaySize.height, 400)
        XCTAssertEqual(portrait.scrollAxes, .vertical)

        let matching = BoardPageViewport(pageSize: CGSize(width: 600, height: 840), cellSize: CGSize(width: 300, height: 300),
            viewport: CGSize(width: 624, height: 864), zoom: 1)
        XCTAssertEqual(matching.displaySize, CGSize(width: 600, height: 840))
        XCTAssertTrue(matching.scrollAxes.isEmpty)

        let zoomed = BoardPageViewport(pageSize: CGSize(width: 840, height: 600), cellSize: CGSize(width: 100, height: 100),
            viewport: CGSize(width: 390, height: 624), zoom: 2)
        XCTAssertEqual(zoomed.scrollAxes, [.horizontal, .vertical])
    }

    func testModestAspectRatioDifferenceFitsWholePage() {
        // Portrait page on a tall phone, like the reported three-column board.
        let portrait = BoardPageViewport(pageSize: CGSize(width: 595, height: 842), cellSize: CGSize(width: 300, height: 300),
            viewport: CGSize(width: 390, height: 614), zoom: 1)
        XCTAssertTrue(portrait.scrollAxes.isEmpty)
        XCTAssertEqual(portrait.displaySize.width, 366, accuracy: 0.001)
        XCTAssertLessThan(portrait.displaySize.height, 590)

        // The same policy applies when a landscape page is slightly too tall.
        let landscape = BoardPageViewport(pageSize: CGSize(width: 842, height: 595), cellSize: CGSize(width: 300, height: 300),
            viewport: CGSize(width: 614, height: 390), zoom: 1)
        XCTAssertTrue(landscape.scrollAxes.isEmpty)
        XCTAssertEqual(landscape.displaySize.height, 366, accuracy: 0.001)
        XCTAssertEqual(landscape.scale, portrait.scale, accuracy: 0.001)

        let zoomed = BoardPageViewport(pageSize: CGSize(width: 595, height: 842), cellSize: CGSize(width: 300, height: 300),
            viewport: CGSize(width: 390, height: 614), zoom: 1.5)
        XCTAssertEqual(zoomed.scale, portrait.scale * 1.5, accuracy: 0.001)
        XCTAssertEqual(zoomed.scrollAxes, [.horizontal, .vertical])
    }

    func testFitDependsOnActualCardSizeRatherThanPageAspectRatio() {
        let page = CGSize(width: 840, height: 600)
        let window = CGSize(width: 390, height: 624)
        let sparse = BoardPageViewport(pageSize: page, cellSize: CGSize(width: 280, height: 300),
                                       viewport: window, zoom: 1)
        XCTAssertTrue(sparse.scrollAxes.isEmpty)
        XCTAssertEqual(sparse.displaySize.width, 366, accuracy: 0.001)
        XCTAssertEqual(sparse.padding, EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        let dense = BoardPageViewport(pageSize: page, cellSize: CGSize(width: 84, height: 60),
                                      viewport: window, zoom: 1)
        XCTAssertEqual(dense.scrollAxes, .horizontal)
        XCTAssertEqual(dense.displaySize.height, 600, accuracy: 0.001)
        XCTAssertEqual(dense.padding, EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 0))
    }

    func testCardReadabilityBoundaryAndVerticalPadding() {
        let page = CGSize(width: 600, height: 840)
        let cell = CGSize(width: 117.5, height: 117.5)
        let fit = BoardPageViewport(pageSize: page, cellSize: cell,
                                    viewport: CGSize(width: 504, height: 864), zoom: 1)
        XCTAssertTrue(fit.scrollAxes.isEmpty)
        XCTAssertEqual(cell.width * fit.scale, 94, accuracy: 0.001)
        let overflow = BoardPageViewport(pageSize: page, cellSize: cell,
                                         viewport: CGSize(width: 494, height: 864), zoom: 1)
        XCTAssertEqual(overflow.scrollAxes, .horizontal)
        let vertical = BoardPageViewport(pageSize: page, cellSize: cell,
                                         viewport: CGSize(width: 864, height: 494), zoom: 1)
        XCTAssertEqual(vertical.scrollAxes, .vertical)
        XCTAssertEqual(vertical.padding, EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 12))
        let zoomed = BoardPageViewport(pageSize: page, cellSize: cell,
                                       viewport: CGSize(width: 864, height: 494), zoom: 2)
        XCTAssertEqual(zoomed.padding, EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 0))
    }

    func testFitUsesTitleFooterAndFixedAspectCardGeometry() {
        let options = CollageFormatting()
        options.pageTitleVisible = true
        let geometry = BoardPageGeometry(pageSize: CGSize(width: 600, height: 840),
            layout: PageLayout(width: 1, height: 8, fixedCardAspectRatio: 1),
            title: "A title", style: BoardRenderStyle(options), attribution: "Credit")
        let viewport = BoardPageViewport(pageSize: geometry.pageSize, cellSize: geometry.cellSize,
                                         viewport: CGSize(width: 390, height: 624), zoom: 1)
        XCTAssertEqual(viewport.scrollAxes, .horizontal)
        XCTAssertEqual(viewport.displaySize.height, 600, accuracy: 0.001)
    }

    func testContinuousResizeKeepsOneAxisFittedAndFinite() {
        for width in stride(from: 200, through: 1200, by: 7) {
            let window = CGSize(width: width, height: 600)
            let viewport = BoardPageViewport(pageSize: CGSize(width: 600, height: 840),
                cellSize: CGSize(width: 100, height: 84), viewport: window, zoom: 1)
            XCTAssertTrue(viewport.scale.isFinite)
            XCTAssertNotEqual(viewport.scrollAxes, [.horizontal, .vertical])
            XCTAssertTrue(abs(viewport.displaySize.width - window.width + 24) < 0.001 ||
                          abs(viewport.displaySize.height - window.height + 24) < 0.001)
        }
    }

    func testCancelledResizeDoesNotRasterizeOrPublish() async throws {
        let state = try state(count: 12, layout: PageLayout(width: 3, height: 4))
        let model = BoardPageRenderModel()
        let original = CGSize(width: 390, height: 600)
        await model.prepare(state: state, pageIndex: 0, viewport: original, zoom: 1, displayScale: 2)
        let originalSize = try XCTUnwrap(model.page).displaySize
        let renderCount = model.cache.renderCount
        let resize = Task {
            await model.prepare(state: state, pageIndex: 0,
                viewport: CGSize(width: 800, height: 600), zoom: 1, displayScale: 2)
        }
        await Task.yield()
        resize.cancel()
        await resize.value
        XCTAssertEqual(model.cache.renderCount, renderCount)
        XCTAssertEqual(model.page?.displaySize, originalSize)
        await model.prepare(state: state, pageIndex: 0,
            viewport: CGSize(width: 800, height: 600), zoom: 1, displayScale: 2)
        XCTAssertNotEqual(model.page?.displaySize, originalSize)
    }

    private func image() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600), format: format).image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 20, y: 20, width: 560, height: 560))
        }
    }

    private func state(count: Int, layout: PageLayout = PageLayout(width: 8, height: 10)) throws -> PageLayoutState {
        let repo = try repoFactory.createEmptyRepo(directoryURL: tempDir, setActive: false)
        let state = PageLayoutState(topic: repo, setupSinks: false)
        state.pageLayout = layout
        let source = image()
        state.photoBrowserData.photoItems = (0..<count).map { PhotoItem(image: source, title: "Card \($0)") }
        return state
    }

    func testDenseBoardIncrementalEditsAndReorder() async throws {
        let state = try state(count: 80)
        // Match the before fixture: 600-point source at the device's default scale.
        let source = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600)).image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 20, y: 20, width: 560, height: 560))
        }
        for photo in state.photoBrowserData.photoItems { photo.image = source }
        let model = BoardPageRenderModel()
        let viewport = CGSize(width: 390, height: 552)
        await model.prepare(state: state, pageIndex: 0, viewport: viewport, zoom: 1, displayScale: 3)
        XCTAssertEqual(model.cache.renderCount, 80)
        var durations = [Double]()
        for index in 0..<10 {
            state.photoBrowserData.photoItems[42].title = "Edited \(index)"
            let start = CACurrentMediaTime()
            await model.prepare(state: state, pageIndex: 0, viewport: viewport, zoom: 1, displayScale: 3)
            durations.append((CACurrentMediaTime() - start) * 1000)
            XCTAssertEqual(model.cache.renderCount, 81 + index)
        }
        print("BOARD_INCREMENTAL edits=10 cardsPerEdit=1 meanMS=\(durations.reduce(0,+)/10) maxMS=\(durations.max()!)")
        state.photoBrowserData.photoItems.swapAt(0, 79)
        let start = CACurrentMediaTime()
        await model.prepare(state: state, pageIndex: 0, viewport: viewport, zoom: 1, displayScale: 3)
        XCTAssertEqual(model.cache.renderCount, 90, "Reorder must not redraw unchanged content")
        print("BOARD_REORDER cardsRendered=0 elapsedMS=\((CACurrentMediaTime()-start)*1000)")
        XCTAssertEqual(model.page?.cards.first?.photoID, state.photoBrowserData.photoItems.first?.itemID)
    }

    func testContentFormattingResolutionAndDecorationInvalidation() throws {
        let cache = BoardCardRenderCache()
        let photo = PhotoItem(image: image(), title: "Label")
        let format = CollageFormatting()
        let size = CGSize(width: 100, height: 120)
        func render(_ scale: CGFloat = 2) -> UIImage {
            cache.image(card: BoardCardSnapshot(photo), style: BoardRenderStyle(format), size: size, scale: scale)
        }
        let original = render()
        photo.needsSave = false
        photo.title = "Label"
        XCTAssertTrue(original === render())
        photo.title = "Edited"
        XCTAssertFalse(photo.needsSave, "A metadata edit must not re-encode the original image")
        XCTAssertFalse(original === render())
        XCTAssertEqual(cache.renderCount, 2)
        photo.image = image()
        _ = render()
        XCTAssertEqual(cache.renderCount, 3)
        photo.fitzgeraldKey = .noun
        _ = render()
        XCTAssertEqual(cache.renderCount, 4)
        format.cardTitleFontBold.toggle()
        _ = render()
        XCTAssertEqual(cache.renderCount, 5)
        format.pageTitleColor = .red
        format.gridlinesThick.toggle()
        _ = render()
        XCTAssertEqual(cache.renderCount, 5, "Page decorations do not invalidate card content")
        _ = render(3)
        XCTAssertEqual(cache.renderCount, 6)
    }

    func testRepeatedEmptyPartialAndMultiplePages() async throws {
        let state = try state(count: 1, layout: PageLayout(width: 3, height: 4))
        let model = BoardPageRenderModel()
        let viewport = CGSize(width: 390, height: 600)
        state.repeatSinglePhoto = true
        await model.prepare(state: state, pageIndex: 0, viewport: viewport, zoom: 1, displayScale: 2)
        let repeated = try XCTUnwrap(model.page)
        XCTAssertEqual(Set(repeated.cards.map(\.id)).count, 12)
        XCTAssertEqual(Set(repeated.cards.compactMap(\.photoID)).count, 1)
        XCTAssertEqual(model.cache.renderCount, 1)
        XCTAssertTrue(repeated.cards.allSatisfy { $0.image === repeated.cards[0].image })
        state.repeatSinglePhoto = false
        state.photoBrowserData.photoItems = (0..<13).map { PhotoItem(image: image(), title: "Card \($0)") }
        await model.prepare(state: state, pageIndex: 1, viewport: viewport, zoom: 1, displayScale: 2)
        XCTAssertEqual(model.page?.cards.filter { $0.image != nil }.count, 1)
        XCTAssertEqual(model.page?.cards.first?.sourceIndex, 12)
        XCTAssertEqual(state.createPrintableCollage().count, 2)
        state.photoBrowserData.photoItems = []
        await model.prepare(state: state, pageIndex: 0, viewport: viewport, zoom: 1, displayScale: 2)
        XCTAssertTrue(try XCTUnwrap(model.page).cards.allSatisfy { $0.image == nil })
        XCTAssertEqual(state.createPrintableCollage().count, 1)
    }

    func testThumbnailChangesOnlyForFirstPageVisualInputsAndPersistsImmediately() throws {
        let state = try state(count: 13, layout: PageLayout(width: 3, height: 4))
        state.save()
        XCTAssertEqual(state.thumbnailRenderCount, 0, "Saving must not synchronously render a cover")
        state.flushThumbnail()
        XCTAssertEqual(state.thumbnailRenderCount, 1)
        state.photoBrowserData.photoItems[12].title = "Second page edit"
        state.photosDidChange()
        let persisted = try PECSRepo.load(directory: tempDir)
        XCTAssertEqual(persisted.photos.photoItems[12].title, "Second page edit")
        state.flushThumbnail()
        XCTAssertEqual(state.thumbnailRenderCount, 1)
        for index in 0..<5 {
            state.photoBrowserData.photoItems[0].title = "First page edit \(index)"
            state.photosDidChange()
        }
        XCTAssertEqual(state.thumbnailRenderCount, 1)
        state.flushThumbnail()
        XCTAssertEqual(state.thumbnailRenderCount, 2)
        // Attribution anywhere on the board changes the reserved footer on page one.
        state.photoBrowserData.photoItems[12].symbolSource = SymbolSource(provider: .arasaac, symbolID: 1)
        state.photosDidChange()
        state.flushThumbnail()
        XCTAssertEqual(state.thumbnailRenderCount, 3)
    }

    func testPendingThumbnailRecoversAfterReload() throws {
        let original = try state(count: 2, layout: PageLayout(width: 3, height: 4))
        original.save()
        let persisted = try PECSRepo.load(directory: tempDir)
        XCTAssertTrue(persisted.generatedThumbnailNeedsUpdate)
        // Cancel the first state's delayed work to simulate termination before rendering.
        original.generateTopicThumbnail = false
        original.flushThumbnail()
        let restored = PageLayoutState(topic: persisted, setupSinks: false)
        restored.flushThumbnail()
        XCTAssertEqual(restored.thumbnailRenderCount, 1)
        XCTAssertFalse(try PECSRepo.load(directory: tempDir).generatedThumbnailNeedsUpdate)
    }

    func testManualCoverIsPreservedWhenBoardContentChanges() throws {
        let state = try state(count: 2, layout: PageLayout(width: 3, height: 4))
        state.save()
        state.flushThumbnail()
        let renderCount = state.thumbnailRenderCount
        let manualCover = image()
        state.setTopicImage(PhotoItem(image: manualCover), isUserSelection: true, saveChanges: true)

        state.photoBrowserData.photoItems[0].title = "Changed after choosing a cover"
        state.photosDidChange()
        state.flushThumbnail()

        XCTAssertFalse(state.generateTopicThumbnail)
        XCTAssertEqual(state.thumbnailRenderCount, renderCount)
        XCTAssertTrue(state.topicImage.image === manualCover)
        let restored = try PECSRepo.load(directory: tempDir)
        XCTAssertFalse(restored.generateTopicThumbnail)
        XCTAssertFalse(restored.generatedThumbnailNeedsUpdate)
    }

    func testManualCoverCanReturnToAutomaticGeneration() throws {
        let state = try state(count: 2, layout: PageLayout(width: 3, height: 4))
        let manualCover = image()
        state.setTopicImage(PhotoItem(image: manualCover), isUserSelection: true, saveChanges: true)

        state.useGeneratedTopicThumbnail(saveChanges: true)

        XCTAssertTrue(state.generateTopicThumbnail)
        XCTAssertEqual(state.thumbnailRenderCount, 1)
        XCTAssertFalse(state.topicImage.image === manualCover)
        let restored = try PECSRepo.load(directory: tempDir)
        XCTAssertTrue(restored.generateTopicThumbnail)
        XCTAssertFalse(restored.generatedThumbnailNeedsUpdate)
    }

    func testCancelledPreparationCannotReplaceNewerPage() async throws {
        let state = try state(count: 100)
        let model = BoardPageRenderModel()
        let old = Task { await model.prepare(state: state, pageIndex: 0,
            viewport: CGSize(width: 390, height: 600), zoom: 1, displayScale: 2) }
        await Task.yield()
        old.cancel()
        state.photoBrowserData.photoItems[0].title = "Newest edit"
        await model.prepare(state: state, pageIndex: 0, viewport: CGSize(width: 390, height: 600), zoom: 1, displayScale: 2)
        await old.value
        XCTAssertEqual(model.page?.cards.first?.title, "Newest edit")
    }

    func testPageGeometryAndRasterCompositionMatchExport() throws {
        let format = CollageFormatting()
        format.pageTitleVisible = true
        format.fitzgeraldBordersEnabled = true
        format.gridlinesThick = true
        format.cardTitleFontBold = true
        let photos = (0..<7).map { PhotoItem(image: image(), title: "A long label \($0)", fitzgeraldKey: .noun) }
        for pageSize in [CGSize(width: 600, height: 840), CGSize(width: 840, height: 600)] {
            for layout in [PageLayout(width: 3, height: 4), PageLayout(width: 10, height: 10),
                           PageLayout(width: 1, height: 8, fixedCardAspectRatio: 1)] {
                for top in [false, true] {
                    format.cardTitlePosition = top ? .top : .bottom
                    let style = BoardRenderStyle(format)
                    let geometry = BoardPageGeometry(pageSize: pageSize, layout: layout, title: "Board title",
                                                     style: style, attribution: "Symbol attribution\nSecond credit")
                    XCTAssertGreaterThan(geometry.footerRect.height, 0)
                    XCTAssertLessThanOrEqual(geometry.gridRect.maxY, geometry.footerRect.minY + 0.001)
                    XCTAssertGreaterThanOrEqual(geometry.gridRect.minY + 0.001, geometry.titleRect.maxY)
                    let scale: CGFloat = 2
                    let cache = BoardCardRenderCache()
                    let renderedCards = photos.map { cache.image(card: BoardCardSnapshot($0), style: style, size: geometry.cellSize, scale: scale) }
                    let titleStrip = CollageFactory.renderDecorationRegion(geometry.titleRect, geometry: geometry,
                        title: "Board title", attribution: "Symbol attribution\nSecond credit", style: style, scale: scale)
                    let footerStrip = CollageFactory.renderDecorationRegion(geometry.footerRect, geometry: geometry,
                        title: "Board title", attribution: "Symbol attribution\nSecond credit", style: style, scale: scale)
                    let composed = CollageFactory.render(size: pageSize, scale: scale) { context in
                        UIColor.white.setFill()
                        context.fill(CGRect(origin: .zero, size: pageSize))
                        for (slot, image) in renderedCards.enumerated() { image.draw(in: geometry.cellRect(slot: slot)) }
                        context.setStrokeColor(UIColor(style.gridlinesColor).cgColor)
                        context.setLineWidth(style.gridlinesWidth)
                        for line in geometry.gridLines { context.strokeLineSegments(between: [line.0, line.1]) }
                        titleStrip?.draw(in: geometry.titleRect)
                        footerStrip?.draw(in: geometry.footerRect)
                    }
                    let exported = try XCTUnwrap(CollageFactory.createCollage(from: photos, gridSize: layout,
                        pageSize: CGSize(width: pageSize.width * scale, height: pageSize.height * scale),
                        pageTitle: "Board title", options: format, attribution: "Symbol attribution\nSecond credit", canonicalPageSize: pageSize))
                    XCTAssertEqual(exported.cgImage?.width, Int(pageSize.width * scale))
                    let difference = pixelDifference(composed, exported)
                    XCTAssertLessThan(difference, 2, "Composition/export mean pixel difference: \(difference)")
                    if pageSize.width == 600, layout.width == 3, !top {
                        let attachment = XCTAttachment(image: composed)
                        attachment.name = "Individual card composition"
                        attachment.lifetime = .keepAlways
                        add(attachment)
                        let export = XCTAttachment(image: exported)
                        export.name = "Exported page"
                        export.lifetime = .keepAlways
                        add(export)
                    }
                }
            }
        }
    }

    func testScreenAndPrintResolutionKeepTheSameLayout() throws {
        let state = try state(count: 7, layout: PageLayout(width: 3, height: 4))
        state.title = "Shared title"
        state.topic.formatting.pageTitleVisible = true
        state.topic.formatting.fitzgeraldBordersEnabled = true
        state.photoBrowserData.photoItems[0].symbolSource = SymbolSource(provider: .arasaac, symbolID: 1)
        state.photoBrowserData.photoItems[0].fitzgeraldKey = .noun
        for orientation in [PageOrientation.portrait, .landscape] {
            state.orientation = orientation
            let screen = try XCTUnwrap(state.createCollagePageForScreen(maxWidth: 500, page: 0)?.image)
            let printImage = try XCTUnwrap(state.createPrintableCollage().first?.image)
            let expected = state.pageMeasurements2.convertWithDPI(300)
            XCTAssertEqual(CGFloat(printImage.cgImage!.width), expected.width, accuracy: 1)
            XCTAssertEqual(CGFloat(printImage.cgImage!.height), expected.height, accuracy: 1)
            let reduced = CollageFactory.render(size: screen.size, scale: 1) { _ in
                printImage.draw(in: CGRect(origin: .zero, size: screen.size))
            }
            XCTAssertLessThan(pixelDifference(screen, reduced), 4)
        }
        state.generateTopicThumbnail = false
    }

    func testPDFExportPreservesTheIntendedPhysicalPageAndCardSize() throws {
        let state = try state(count: 7, layout: PageLayout(width: 3, height: 4))
        state.title = "Shared title"
        state.topic.formatting.pageTitleVisible = true
        state.photoBrowserData.photoItems[0].symbolSource = SymbolSource(provider: .arasaac, symbolID: 1)
        state.photosDidChange()

        let intendedCardSize = try XCTUnwrap(state.pageLayout.printableCardSize(
            for: state.pageSize,
            orientation: state.orientation,
            title: state.title,
            style: BoardRenderStyle(state.topic.formatting),
            attribution: state.symbolAttribution
        ))
        let displayedChoice = try XCTUnwrap(
            state.layoutSections.flatMap(\.layouts).first { $0.layout == state.pageLayout }
        )
        XCTAssertEqual(
            state.individualCardMeasurements.sizeInMM.width,
            intendedCardSize.sizeInMM.width,
            accuracy: 0.001
        )
        XCTAssertEqual(
            state.individualCardMeasurements.sizeInMM.height,
            intendedCardSize.sizeInMM.height,
            accuracy: 0.001
        )
        XCTAssertEqual(displayedChoice.cardSize.sizeInMM.width, intendedCardSize.sizeInMM.width, accuracy: 0.001)
        XCTAssertEqual(displayedChoice.cardSize.sizeInMM.height, intendedCardSize.sizeInMM.height, accuracy: 0.001)
        let pdfURL = try XCTUnwrap(state.createPDF())
        let document = try XCTUnwrap(PDFDocument(url: pdfURL))
        let page = try XCTUnwrap(document.page(at: 0))
        let mediaSize = page.bounds(for: .mediaBox).size
        let intendedPageSize = state.pageMeasurements2.convertToPDFMeasurements()

        XCTAssertEqual(mediaSize.width, intendedPageSize.width, accuracy: 0.01)
        XCTAssertEqual(mediaSize.height, intendedPageSize.height, accuracy: 0.01)

        let exportedGeometry = BoardPageGeometry(
            pageSize: mediaSize,
            layout: state.pageLayout,
            title: state.title,
            style: BoardRenderStyle(state.topic.formatting),
            attribution: state.symbolAttribution
        )
        XCTAssertEqual(
            exportedGeometry.cellSizeInMillimetres.width,
            intendedCardSize.sizeInMM.width,
            accuracy: 0.01
        )
        XCTAssertEqual(
            exportedGeometry.cellSizeInMillimetres.height,
            intendedCardSize.sizeInMM.height,
            accuracy: 0.01
        )
        print("PDF_TEST_URL=\(pdfURL.path)")
        state.generateTopicThumbnail = false
    }

    private func pixelDifference(_ lhs: UIImage, _ rhs: UIImage) -> Double {
        func pixels(_ image: UIImage) -> [UInt8] {
            let width = image.cgImage!.width, height = image.cgImage!.height
            var data = [UInt8](repeating: 0, count: width * height * 4)
            data.withUnsafeMutableBytes { bytes in
                let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            return data
        }
        let a = pixels(lhs), b = pixels(rhs)
        guard a.count == b.count else { return 255 }
        var total = 0
        var count = 0
        for index in stride(from: 0, to: a.count, by: 17) {
            total += abs(Int(a[index]) - Int(b[index]))
            count += 1
        }
        return Double(total) / Double(count)
    }
}
