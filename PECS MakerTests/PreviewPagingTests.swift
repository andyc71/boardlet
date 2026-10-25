import XCTest
import SwiftUI
import SharedSwiftUI
import FeatureFramework
import RatingFramework
@testable import PECS_Maker

@MainActor
final class PreviewPagingTests: PersistenceTestsBase {
    private func makeBoard(pageCount: Int = 3) throws -> PageLayoutState {
        let directory = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let board = try repoFactory.createEmptyRepo(directoryURL: directory, setActive: false)
        board.layout = PageLayout(width: 1, height: 1)
        board.photos.photoItems = (0..<pageCount).map { index in
            PhotoItem(image: UIImage(systemName: "star.fill")!, title: "Page \(index + 1)")
        }
        let state = PageLayoutState(topic: board, setupSinks: false)
        state.generateTopicThumbnail = false
        return state
    }

    func testRenderedPageIdentitySurvivesResizeAndFormatting() throws {
        let state = try makeBoard()
        state.selectedPreviewPage = 2
        let first = state.createCollageForScreen(maxWidth: 250)
        XCTAssertEqual(first.map(\.id), [0, 1, 2])
        for width: CGFloat in [150, 400, 200, 500] {
            let rendered = state.createCollageForScreen(maxWidth: width)
            XCTAssertEqual(rendered.map(\.id), first.map(\.id))
            XCTAssertEqual(rendered[2].image.size.width, width, accuracy: 1)
            XCTAssertEqual(state.selectedPreviewPage, 2)
        }
        state.setupSinks()
        state.topic.formatting.marginPercentage += 1
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertEqual(state.createCollageForScreen(maxWidth: 250).map(\.id), first.map(\.id))
        XCTAssertEqual(state.selectedPreviewPage, 2)
    }

    func testSelectionClampsAndDoesNotResurrectWhenPagesReturn() throws {
        let state = try makeBoard()
        state.selectedPreviewPage = 2
        state.photoBrowserData.photoItems.removeLast()
        state.photosDidChange()
        XCTAssertEqual(state.selectedPreviewPage, 1)
        state.photoBrowserData.photoItems.append(PhotoItem(image: UIImage(), title: "Returned page"))
        state.photosDidChange()
        XCTAssertEqual(state.selectedPreviewPage, 1)
        state.pageLayout = PageLayout(width: 2, height: 2)
        XCTAssertEqual(state.selectedPreviewPage, 0)
        state.photoBrowserData.photoItems.removeAll()
        state.photosDidChange()
        XCTAssertEqual(state.createCollageForScreen(maxWidth: 250).count, 1)
        XCTAssertEqual(state.selectedPreviewPage, 0)
        state.selectedPreviewPage = -1
        XCTAssertEqual(state.clampedPreviewPage(pageCount: 0), 0)
    }

    func testBoardIdentityResetsSelectionButSameBoardReloadPreservesIt() throws {
        let state = try makeBoard()
        state.selectedPreviewPage = 2
        state.load(topic: state.topic, shouldSetupSinks: false)
        XCTAssertEqual(state.selectedPreviewPage, 2)
        let other = try makeBoard()
        state.load(topic: other.topic, shouldSetupSinks: false)
        XCTAssertEqual(state.selectedPreviewPage, 0)
    }

    func testHostedPreviewKeepsPageAndRegrowsWithControls() throws {
        let state = try makeBoard()
        let root = PagePreviewView(pageLayoutState: state, dismissAction: {})
            .environmentObject(SharedUITheme())
            .environmentObject(FeaturesViewModel(featureSettings: AppSettings.shared))
            .environmentObject(RatingStateMachine2())
        let host = UIHostingController(rootView: root)
        let container = UIViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.addChild(host)
        container.view.addSubview(host.view)
        host.didMove(toParent: container)
        defer {
            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
            window.isHidden = true
        }

        func descendants(_ view: UIView) -> [UIView] {
            [view] + view.subviews.flatMap(descendants)
        }
        func resize(_ size: CGSize) {
            container.setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: size.width < 600 ? .compact : .regular), forChild: host)
            host.view.frame = CGRect(origin: .zero, size: size)
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        }
        func displayedPagerFrame() throws -> CGRect {
            let scrollView = try XCTUnwrap(descendants(host.view).compactMap { $0 as? UIScrollView }.first { $0.isPagingEnabled })
            return scrollView.convert(scrollView.bounds, to: host.view)
        }
        func assertVisiblePreview() throws {
            let frame = try displayedPagerFrame()
            XCTAssertGreaterThan(frame.height, 0)
            XCTAssertTrue(host.view.bounds.insetBy(dx: -1, dy: -1).contains(frame))
            XCTAssertEqual(frame.width / frame.height, state.aspectRatio, accuracy: 0.01)
        }
        func attachPreview(_ name: String) {
            let attachment = XCTAttachment(image: UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
                host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
            })
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        func pageControl() throws -> UIPageControl {
            try XCTUnwrap(descendants(host.view).compactMap { $0 as? UIPageControl }.first)
        }
        func assertPage(_ page: Int, count: Int = 3, file: StaticString = #filePath, line: UInt = #line) throws {
            let control = try pageControl()
            XCTAssertEqual(control.numberOfPages, count, file: file, line: line)
            XCTAssertEqual(control.currentPage, page, file: file, line: line)
            XCTAssertEqual(state.selectedPreviewPage, page, file: file, line: line)
        }
        resize(CGSize(width: 700, height: 900))
        // Drive the real native page indicator, exercising the TabView binding.
        let control = try pageControl()
        control.currentPage = 2
        control.sendActions(for: .valueChanged)
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        try assertPage(2)

        for iteration in 0..<2 {
            for size in [CGSize(width: 360, height: 700), CGSize(width: 700, height: 450),
                         CGSize(width: 360, height: 450), CGSize(width: 700, height: 900)] {
                resize(size)
                try assertPage(2)
                try assertVisiblePreview()
                if iteration == 1 { attachPreview("Page 3 at \(Int(size.width))x\(Int(size.height))") }
                let images = try XCTUnwrap(state._collageForScreen)
                let renderedSize = images[2].image.size
                XCTAssertGreaterThan(renderedSize.height, 0)
                XCTAssertLessThanOrEqual(renderedSize.width, size.width)
                XCTAssertLessThan(renderedSize.height, size.height)
                XCTAssertEqual(renderedSize.width / renderedSize.height, state.aspectRatio, accuracy: 0.01)
                if size.height == 900 {
                    XCTAssertGreaterThan(try displayedPagerFrame().height, 450, "Preview must grow again after a short parent")
                }
            }
        }
        resize(.zero)
        resize(CGSize(width: 700, height: 900))
        try assertPage(2)
        try assertVisiblePreview()
        state.setupSinks()
        state.topic.formatting.cardTitleFontBold.toggle()
        resize(CGSize(width: 700, height: 900))
        try assertPage(2)
        state.photoBrowserData.photoItems.removeLast()
        state.photosDidChange()
        resize(CGSize(width: 700, height: 900))
        try assertPage(1, count: 2)
        state.orientation = .landscape
        resize(CGSize(width: 700, height: 900))
        try assertPage(0, count: 1) // The default landscape grid fits both photos.
        try assertVisiblePreview()
        let other = try makeBoard()
        state.load(topic: other.topic, shouldSetupSinks: false)
        resize(CGSize(width: 700, height: 900))
        try assertPage(0)

        attachPreview("Preview after switching boards")
    }
}
