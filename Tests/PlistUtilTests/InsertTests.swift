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
class InsertTests: PlistUtilTestCase {
    func testInsert() throws {
        let string = "never gonna give you up"
        let stringData = string.data(using: .utf8)!
        let stringDataEncoded = stringData.base64EncodedString()

        Create.main(["--output-format", "binary", "--type", "dict", "/dict.plist"])
        func getPlist() -> [AnyHashable: Any]? {
            guard let contents = fs.contents(atPath: "/dict.plist") else {
                XCTFail("Should have created contents at /dict.plist")
                return nil
            }

            var format: PropertyListSerialization.PropertyListFormat = .xml
            guard let plist = try? PropertyListSerialization.propertyList(from: contents, format: &format) as? [AnyHashable: Any] else {
                XCTFail("plist was of unexpected type")
                return nil
            }
            XCTAssertEqual(format, .binary)

            return plist
        }

        Insert.main(["--type", "int", "--key", "IntKey", "--value", "42", "/dict.plist"])
        XCTAssertEqual(getPlist()!["IntKey"] as? Int, 42)
        Insert.main(["--type", "bool", "--key", "BoolKey", "--value", "true", "/dict.plist"])
        XCTAssertEqual(getPlist()!["BoolKey"] as? Bool, true)
        Insert.main(["--type", "data", "--key", "DataKey", "--value", stringDataEncoded, "/dict.plist"])
        XCTAssertEqual(getPlist()!["DataKey"] as? Data, stringData)
        Insert.main(["--type", "string", "--key", "StringKey", "--value", string, "/dict.plist"])
        XCTAssertEqual(getPlist()!["StringKey"] as? String, string)

        Insert.main(["--type", "dict", "--key", "DictKey", "/dict.plist"])
        Insert.main(["--type", "string", "--key", "DictKey", "--key", "InnerDictKey", "--value", "InnerValue", "/dict.plist"])
        XCTAssertEqual((getPlist()!["DictKey"] as? Equality.Dict)?["InnerDictKey"] as? String, "InnerValue")

        Insert.main(["--type", "list", "--key", "ListKey", "/dict.plist"])
        Insert.main(["--type", "int", "--key", "ListKey", "--key", "^", "--value", "213", "/dict.plist"])
        XCTAssertEqual((getPlist()!["ListKey"] as? Equality.List)?.first as? Int, 213)
        Insert.main(["--type", "bool", "--key", "ListKey", "--key", "$", "--value", "false", "/dict.plist"])
        XCTAssertEqual((getPlist()!["ListKey"] as? Equality.List)?.last as? Bool, false)

        let expectedValue: [AnyHashable: Any] = [
            "IntKey": 42,
            "BoolKey": true,
            "DataKey": stringData,
            "StringKey": string,
            "DictKey": [
                "InnerDictKey": "InnerValue",
            ],
            "ListKey": [213, false],
        ]

        XCTAssert(expectedValue.collectionDefinitelyEquals(otherPlist: getPlist()!))
    }
}
