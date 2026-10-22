import XCTest
@testable import PECS_Maker

final class TopicLayoutRecommendationTests: XCTestCase {
    func testScreenCardsShrinkToFitThenScrollAtThePaperMinimum() {
        let layout = PageLayout(width: 3, height: 4)
        let original = ScreenCardGridGeometry.fittingPage(layout,
            in: CGSize(width: 402, height: 700), cardAspectRatio: 0.8)
        let smaller = ScreenCardGridGeometry.fittingPage(layout,
            in: CGSize(width: 750, height: 440), cardAspectRatio: 0.8)
        XCTAssertLessThan(smaller.cardSize.width, original.cardSize.width)
        XCTAssertLessThanOrEqual(smaller.pageSize.width, 750 - 16)
        XCTAssertLessThanOrEqual(smaller.pageSize.height, 440 - 40)
        XCTAssertGreaterThanOrEqual(smaller.cardSize.width, 64)
        XCTAssertGreaterThanOrEqual(smaller.cardSize.height, 64)

        let cramped = ScreenCardGridGeometry.fittingPage(layout,
            in: CGSize(width: 240, height: 200), cardAspectRatio: 0.8)
        XCTAssertGreaterThanOrEqual(cramped.cardSize.width, 64 - 0.001)
        XCTAssertGreaterThanOrEqual(cramped.cardSize.height, 64 - 0.001)
        XCTAssertGreaterThan(cramped.pageSize.height, 200 - 40)
        XCTAssertEqual(cramped.columns, 3)
        XCTAssertEqual(cramped.rows, 4)

        let returned = ScreenCardGridGeometry.fittingPage(layout,
            in: CGSize(width: 402, height: 700), cardAspectRatio: 0.8)
        XCTAssertEqual(returned.cardSize, original.cardSize)
        XCTAssertEqual(smaller.withRows(7).cardSize.height, smaller.cardSize.height, accuracy: 0.001)
    }

    func testScreenRecommendationsUsePaperRankingForViewport() {
        for viewport in [CGSize(width: 390, height: 650), CGSize(width: 800, height: 360)] {
            let sections = PageLayoutSection.forScreen(in: viewport)
            let candidates = sections.first(where: { $0.kind == .allSizes })!.layouts
                .filter { $0.layout.width > 1 && $0.layout.height > 1 }
            let recommendations = sections.first!.layouts
            XCTAssertEqual(recommendations.count, 3)
            for choice in recommendations {
                let target = choice.preset!.targetSizeInMillimetres
                let best = candidates.map { PageLayoutSection.distance(from: $0.cardSize, to: target) }.min()!
                XCTAssertEqual(PageLayoutSection.distance(from: choice.cardSize, to: target), best)
            }
        }
        XCTAssertNotEqual(PageLayoutMedium.automaticLayout(in: CGSize(width: 390, height: 650)),
                          PageLayoutMedium.automaticLayout(in: CGSize(width: 800, height: 360)))
    }

    func testScreenPresetRoundTripsAndInvalidDataFallsBack() throws {
        let viewport = CGSize(width: 390, height: 650)
        let layout = PageLayout(width: 3, height: 4)
        XCTAssertEqual(PageLayoutMedium.predefinedLayout(data: try JSONEncoder().encode(layout), viewport: viewport), layout)
        XCTAssertGreaterThan(PageLayoutMedium.predefinedLayout(data: Data(), viewport: viewport).total, 0)
    }

    func testSharedPhotoGridPreservesPageFittingAndReadableCells() {
        let portrait = ScreenCardGridGeometry.fittingPage(PageLayout(width: 3, height: 4),
            in: CGSize(width: 402, height: 700), cardAspectRatio: 1)
        XCTAssertEqual(portrait.pageSize.width, 386, accuracy: 0.001)
        XCTAssertEqual(portrait.pageSize.height, 386 * 4.0 / 3, accuracy: 0.001)
        XCTAssertEqual(portrait.cardSize.width, (386 - 16) / 3.0, accuracy: 0.001)
        XCTAssertEqual(portrait.cardSize.height, (386 * 4.0 / 3 - 24) / 4, accuracy: 0.001)

        let dense = ScreenCardGridGeometry.fittingPage(PageLayout(width: 8, height: 8),
            in: CGSize(width: 402, height: 300), cardAspectRatio: 0.7)
        XCTAssertGreaterThanOrEqual(dense.cardSize.width, 64 - 0.001)
        XCTAssertGreaterThanOrEqual(dense.cardSize.height, 64 - 0.001)
    }

    func testSharedContinuousGridReservesPartialRowSlotsAndFillsWidth() {
        let geometry = ScreenCardGridGeometry.fillingWidth(402, columns: 3, rows: 2,
                                                          cardAspectRatio: 5.0 / 7)
        XCTAssertEqual(geometry.columns, 3)
        XCTAssertEqual(geometry.rows, 2)
        XCTAssertEqual(geometry.pageSize.width, 362, accuracy: 0.001)
        XCTAssertEqual(geometry.cardSize.width * 3 + 24, geometry.pageSize.width, accuracy: 0.001)
        XCTAssertEqual(geometry.cardSize.height * 2 + 12, geometry.pageSize.height, accuracy: 0.001)
        XCTAssertEqual(geometry.cardSize.width / geometry.cardSize.height, 5.0 / 7, accuracy: 0.001)
    }

    func testRecommendationsFitPhoneTabletAndIntermediateWidths() {
        let cases: [(CGFloat, Int, Int)] = [(375, 3, 2), (402, 3, 2), (600, 5, 3), (834, 7, 5), (1032, 8, 6)]
        for (width, compact, large) in cases {
            XCTAssertEqual(TopicLayoutRecommendation.compactSquare.columns(in: width), compact)
            XCTAssertEqual(TopicLayoutRecommendation.compactTall.columns(in: width), compact)
            XCTAssertEqual(TopicLayoutRecommendation.largeSquare.columns(in: width), large)
            XCTAssertEqual(TopicLayoutRecommendation.largeTall.columns(in: width), large)
        }
    }

    func testRotationChangesColumnCountWhileFillingWidthAndKeepingShape() {
        for recommendation in TopicLayoutRecommendation.allCases {
            XCTAssertGreaterThan(recommendation.columns(in: 874), recommendation.columns(in: 402))
            for width in [CGFloat(402), 600, 834, 1032, 1376] {
                let columns = recommendation.columns(in: width)
                let size = recommendation.cardSize(in: width)
                XCTAssertEqual(size.width / size.height, recommendation.aspectRatio, accuracy: 0.001)
                XCTAssertEqual(CGFloat(columns) * size.width + CGFloat(columns - 1) * 12 + 40, width, accuracy: 0.001)
            }
        }
    }

    func testAccessibilityCardsKeepShapeAndReduceColumns() {
        for recommendation in TopicLayoutRecommendation.allCases {
            let size = recommendation.cardSize(in: 402, accessibility: true)
            XCTAssertEqual(size.width / size.height, recommendation.aspectRatio, accuracy: 0.001)
            XCTAssertLessThan(recommendation.columns(in: 402, accessibility: true), recommendation.columns(in: 402))
            XCTAssertEqual(recommendation.columns(in: 100, accessibility: true), 1)
            XCTAssertEqual(recommendation.cardSize(in: 100, accessibility: true).width, 60)
        }
    }
}
