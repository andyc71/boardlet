import Foundation
import XCTest
import SQLite3

enum SnapTestFixture {
    // Mirrors Motor Plan's role commands with retained, absent page references.
    static let roleCommandsSQL = #"""
    INSERT INTO Button VALUES(4,40,'Home','',0,0),(5,50,'Keyboard','',0,0);
    INSERT INTO ElementPlacement VALUES(5,40,'1,0','1,1',1,3),(6,50,'2,0','1,1',1,2);
    INSERT INTO ButtonPageLink VALUES(6,4,'old-home'),(7,5,'old-keyboard');
    INSERT INTO CommandSequence VALUES(3,4,'{"$type":"1","$values":[{"$type":"5"}]}'),
        (4,5,'{"$type":"1","$values":[{"$type":"17","IsVisit":false}]}');
    """#

    static func make(extraSQL: String = "") throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sps")
        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &db), SQLITE_OK)
        defer { sqlite3_close(db) }
        let sql = #"""
        CREATE TABLE PageSetProperties(FriendlyName,SchemaVersion,DefaultHomePageUniqueId,GridDimension);
        INSERT INTO PageSetProperties VALUES('Test set','4.20','HOME','3,2');
        CREATE TABLE Page(Id,UniqueId,Title,PageType,GridDimension);
        INSERT INTO Page VALUES(1,'HOME','Home',1,NULL),(2,'child','Child',1,NULL),(3,'shared','Shared',1,NULL),(4,'orphan','Unlinked',1,NULL);
        CREATE TABLE PageLayout(Id,PageId,PageLayoutSetting);
        INSERT INTO PageLayout VALUES(1,1,'2,3,False,0'),(2,1,'3,2,True,0'),(3,2,'3,2,True,0'),(4,3,'3,2,True,0'),(5,4,'3,2,True,0');
        CREATE TABLE ElementPlacement(Id,ElementReferenceId,GridPosition,GridSpan,Visible,PageLayoutId);
        INSERT INTO ElementPlacement VALUES(1,10,'0,0','2,1',1,2),(2,30,'0,3','1,1',0,2),(3,20,'0,0','1,1',1,3),(4,30,'0,0','1,1',1,4);
        CREATE TABLE Button(Id,ElementReferenceId,Label,Message,LibrarySymbolId,PageSetImageId);
        INSERT INTO Button VALUES(1,10,'Go to café 🗣️','Hello',0,1),(2,20,'Return','',0,0),(3,30,'Shared child','',999,0);
        CREATE TABLE ButtonPageLink(Id,ButtonId,PageUniqueId);
        INSERT INTO ButtonPageLink VALUES(1,1,'child'),(2,2,'home'),(3,2,'shared'),(4,2,'missing'),(5,3,'child');
        CREATE TABLE CommandSequence(Id,ButtonId,SerializedCommands);
        INSERT INTO CommandSequence VALUES(1,1,'{"$values":[{"LinkedPageId":"child"}]}'),(2,2,'{"$values":[{"Action":{"LinkedPageId":"shared"}}]}');
        CREATE TABLE PageSetData(Id,Identifier,Data);
        INSERT INTO PageSetData VALUES(1,'IMG:test',X'D7CDC69A');
        """#
        XCTAssertEqual(sqlite3_exec(db, sql + extraSQL, nil, nil, nil), SQLITE_OK)
        return url
    }
}
