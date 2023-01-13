//
//  Created on 12.01.23.
//
//  Copyright (c) 2023 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import XCTest
@testable import ArgumentParser
@testable import PlistUtil

@available(macOS 13, *)
class ExtractTests: PlistUtilTestCase {
    func testExtract() throws {
        let innerDict = [
            "InnerDictKey": "InnerValue",
            "OtherDictKey": "OtherValue",
        ]

        let innerList: [Any] = [213, "foo", false]

        let initialValue: [AnyHashable: Any] = [
            "DictKey": innerDict,
            "EmptyDictKey": [:],
            "ListKey": innerList,
            "EmptyListKey": [],
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: initialValue, format: .binary, options: 0)
        fs.createFile("/bin.plist", data, nil)

        func getPlist(at path: String = "/bin.plist") -> Any? {
            guard let contents = fs.contents(atPath: path) else {
                XCTFail("Should have created contents at \(path)")
                return nil
            }

            var format: PropertyListSerialization.PropertyListFormat = .xml
            let plist = try? PropertyListSerialization.propertyList(from: contents, format: &format)
            return plist
        }

        Extract.main(["--key", "DictKey", "--format", "xml", "--out-file", "/xml.plist", "/bin.plist"])
        XCTAssert((getPlist() as! Equality.Dict).collectionDefinitelyEquals(otherPlist: initialValue)) // shouldn't have changed
        XCTAssert((getPlist(at: "/xml.plist") as! Equality.Dict).collectionDefinitelyEquals(otherPlist: innerDict)) // shouldn't have changed

        Extract.main(["--key", "ListKey", "--format", "xml", "--out-file", "/xml.plist", "/bin.plist"])
        XCTAssert((getPlist() as! Equality.Dict).collectionDefinitelyEquals(otherPlist: initialValue)) // shouldn't have changed
        XCTAssert((getPlist(at: "/xml.plist") as! Equality.List).collectionDefinitelyEquals(otherPlist: innerList)) // shouldn't have changed

        Extract.main(["--key", "EmptyDictKey", "--format", "xml", "--out-file", "/xml.plist", "/bin.plist"])
        XCTAssert((getPlist() as! Equality.Dict).collectionDefinitelyEquals(otherPlist: initialValue)) // shouldn't have changed
        XCTAssert((getPlist(at: "/xml.plist") as! Equality.Dict).collectionDefinitelyEquals(otherPlist: [:])) // shouldn't have changed

        Extract.main(["--key", "EmptyListKey", "--format", "xml", "--out-file", "/xml.plist", "/bin.plist"])
        XCTAssert((getPlist() as! Equality.Dict).collectionDefinitelyEquals(otherPlist: initialValue)) // shouldn't have changed
        XCTAssert((getPlist(at: "/xml.plist") as! Equality.List).collectionDefinitelyEquals(otherPlist: [])) // shouldn't have changed
    }
}
