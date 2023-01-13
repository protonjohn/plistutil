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
class RemoveTests: PlistUtilTestCase {
    func testRemove() throws {
        let string = "never gonna give you up"
        let stringData = string.data(using: .utf8)!

        let initialValue: [AnyHashable: Any] = [
            "IntKey": 42,
            "BoolKey": true,
            "DataKey": stringData,
            "StringKey": string,
            "DictKey": [
                "InnerDictKey": "InnerValue",
                "OtherDictKey": "OtherValue",
            ],
            "EmptyDictKey": [:],
            "ListKey": [213, "foo", false],
            "EmptyListKey": [],
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: initialValue, format: .xml, options: 0)
        fs.createFile("/xml.plist", data, nil)

        func getPlist() -> [AnyHashable: Any]? {
            guard let contents = fs.contents(atPath: "/xml.plist") else {
                XCTFail("Should have created contents at /xml.plist")
                return nil
            }

            var format: PropertyListSerialization.PropertyListFormat = .xml
            guard let plist = try? PropertyListSerialization.propertyList(from: contents, format: &format) as? [AnyHashable: Any] else {
                XCTFail("plist was of unexpected type")
                return nil
            }
            XCTAssertEqual(format, .xml)

            return plist
        }

        Remove.main(["--key", "IntKey", "/xml.plist"])
        XCTAssertNil(getPlist()!["IntKey"])
        Remove.main(["--key", "BoolKey", "/xml.plist"])
        XCTAssertNil(getPlist()!["BoolKey"])
        Remove.main(["--key", "DataKey", "/xml.plist"])
        XCTAssertNil(getPlist()!["DataKey"])
        Remove.main(["--key", "StringKey", "/xml.plist"])
        XCTAssertNil(getPlist()!["StringKey"])
        Remove.main(["--key", "DictKey", "--key", "InnerKey", "/xml.plist"])
        XCTAssertNil((getPlist()!["DictKey"] as? Equality.Dict)?["InnerKey"])
        Remove.main(["--key", "DictKey", "/xml.plist"])
        XCTAssertNil(getPlist()!["DictKey"])
        Remove.main(["--key", "EmptyDictKey", "/xml.plist"])
        XCTAssertNil(getPlist()!["EmptyDictKey"])
        Remove.main(["--key", "ListKey", "--key", "$", "/xml.plist"])
        XCTAssert((getPlist()!["ListKey"] as? Equality.List)?.contains(where: { ($0 as? Bool) == false }) == false)
        Remove.main(["--key", "ListKey", "--key", "^", "/xml.plist"])
        XCTAssert((getPlist()!["ListKey"] as? Equality.List)?.contains(where: { ($0 as? Int) == 213 }) == false)
        Remove.main(["--key", "ListKey", "/xml.plist"])
        XCTAssertNil(getPlist()!["ListKey"])
        Remove.main(["--key", "EmptyListKey", "/xml.plist"])
        XCTAssertNil(getPlist()!["EmptyListKey"])
        XCTAssert(getPlist()!.isEmpty)
    }
}
