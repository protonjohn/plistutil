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

@available(macOS 13.0, *)
class PrintTests: PlistUtilTestCase {
    func testPrint() throws {
        let expected = """
            format: xml
            {
                BoolKey = 1;
                DataKey = {length = 23, bytes = 0x6e6576657220676f6e6e61206769766520796f75207570};
                DictKey =     {
                    InnerDictKey = InnerValue;
                    OtherDictKey = OtherValue;
                };
                EmptyDictKey =     {
                };
                EmptyListKey =     (
                );
                IntKey = 42;
                ListKey =     (
                    213,
                    foo,
                    0
                );
                StringKey = "never gonna give you up";
            }
            
            """

        let string = "never gonna give you up"
        let stringData = string.data(using: .utf8)!

        let plist: [AnyHashable: Any] = [
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
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        fs.createFile("/xml.plist", data, nil)

        var print = try Print.parse(["/xml.plist"])
        try print.run()

        XCTAssertEqual(console, expected)
    }
}
