import XCTest
@testable import uictl

final class BuildInfoTests: XCTestCase {
    func testLibsVersionIsSortedNameVersionPairs() throws {
        let text = try XCTUnwrap(BuildInfo.libsVersion)
        let rows = text.split(separator: "\n").map { $0.split(separator: " ", omittingEmptySubsequences: true) }
        XCTAssertFalse(rows.isEmpty)
        for row in rows { XCTAssertEqual(row.count, 2, "row: \(row)") }
        let names = rows.map { String($0[0]) }
        XCTAssertEqual(names, names.sorted { $0.lowercased() < $1.lowercased() })
    }

    func testSBOMIsCycloneDXJSON() throws {
        let text = try XCTUnwrap(BuildInfo.sbom)
        let obj = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
        XCTAssertEqual(obj["bomFormat"] as? String, "CycloneDX")
        XCTAssertFalse((obj["components"] as? [Any] ?? []).isEmpty)
    }

    func testRootParsesBuildInfoFlags() throws {
        XCTAssertTrue(try Root.parse(["--libs-version"]).libsVersion)
        XCTAssertTrue(try Root.parse(["--sbom"]).sbom)
        XCTAssertThrowsError(try Root.parse(["--libs-version", "--sbom"]))
    }
}
