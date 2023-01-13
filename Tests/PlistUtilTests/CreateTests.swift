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
class CreateTests: PlistUtilTestCase {
    func testCreateEmptyList() throws {
        Create.main(["--format", "binary", "--type", "list", "/list.plist"])
        let contents = fs.contents(atPath: "/list.plist")

        guard let contents else {
            XCTFail("Should have created contents at /list.plist")
            return
        }

        // should be in correct format
        var format: PropertyListSerialization.PropertyListFormat = .xml
        let plist = try PropertyListSerialization.propertyList(from: contents, format: &format)
        XCTAssertEqual(format, .binary)
        XCTAssert((plist as? [Any])?.isEmpty == true)
    }

    func testCreateEmptyDict() throws {
        Create.main(["--format", "binary", "--type", "dict", "/dict.plist"])
        let contents = fs.contents(atPath: "/dict.plist")

        guard let contents else {
            XCTFail("Should have created contents at /dict.plist")
            return
        }

        // should be in correct format
        var format: PropertyListSerialization.PropertyListFormat = .xml
        let plist = try PropertyListSerialization.propertyList(from: contents, format: &format)
        XCTAssertEqual(format, .binary)
        XCTAssert((plist as? [String: Any])?.isEmpty == true)
    }

    func testCreateEmptySwiftDict() throws {
        Create.main(["--format", "swift", "--type", "dict", "/dict.swift"])
        let contents = fs.contents(atPath: "/dict.swift")

        guard let contents else {
            XCTFail("Should have created contents at /dict.swift")
            return
        }

        // should be in correct format
        XCTAssertEqual(contents, "let dict: [AnyHashable: Any] = [:]\n".data(using: .utf8))
    }
}
