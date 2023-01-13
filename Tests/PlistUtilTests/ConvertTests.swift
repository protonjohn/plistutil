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
class ConvertTests: PlistUtilTestCase {
    func testNotSpecifyingFormatResultsInError() throws {
        let plist: [String: String] = ["hello": "world", "foo": "bar"]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        fs.createFile("/xml.plist", data, nil)

        do {
            var convert = try Convert.parse(["--out-file", "/bin.plist", "/xml.plist"])
            try convert.validate()
            try convert.run()
            XCTFail("Command should not have succeeded")
        } catch let error as CommandError {
            guard case .userValidationError(FatalError.didNotSpecify(argument: "format")) = error.parserError else {
                XCTFail("Expected user validation error but got \(String(describing: error))")
                return
            }
        }
    }

    func testConvertToBinary() throws {
        let plist: [String: String] = ["hello": "world", "foo": "bar"]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        fs.createFile("/xml.plist", data, nil)

        do {
            Convert.main(["--format", "binary", "--out-file", "/bin.plist", "/xml.plist"])
            let contents = fs.contents(atPath: "/bin.plist")

            guard let contents else {
                XCTFail("Should have created contents at /bin.plist")
                return
            }

            // should be in correct format
            var format: PropertyListSerialization.PropertyListFormat = .xml
            let convertedPlist = try PropertyListSerialization.propertyList(from: contents, format: &format)
            XCTAssertEqual(format, .binary)
            XCTAssertEqual(plist, convertedPlist as? [String: String])
        }

        // now do it again, but editing in-place
        do {
            Convert.main(["--format", "binary", "/xml.plist"])
            let contents = fs.contents(atPath: "/xml.plist")

            guard let contents else {
                XCTFail("Should have created contents at /xml.plist")
                return
            }

            // should be in correct format
            var format: PropertyListSerialization.PropertyListFormat = .xml
            let convertedPlist = try PropertyListSerialization.propertyList(from: contents, format: &format)
            XCTAssertEqual(format, .binary)
            XCTAssertEqual(plist, convertedPlist as? [String: String])
        }
    }
}
