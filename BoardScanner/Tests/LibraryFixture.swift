import Foundation
@testable import BoardScanner

enum LibraryFixture {
    static func document(_ title: String) -> BoardDocument {
        let button = SnapButton(id: "word", label: "Water", message: "I want water", destinationIDs: [], serializedCommands: "")
        let placement = SnapPlacement(id: 1, elementID: "word", column: 0, row: 0, columnSpan: 1, rowSpan: 1, visible: true)
        let layout = SnapLayout(id: 1, setting: "", columns: 2, rows: 2, placements: [placement])
        let page = SnapPage(id: "home", title: title, pageType: 1, layouts: [layout])
        return BoardDocument(pageSet: SnapPageSet(title: title, schemaVersion: "4.20", homePageID: "home",
                                                 pages: [page], buttons: ["word": button], assets: [:]))
    }
}
