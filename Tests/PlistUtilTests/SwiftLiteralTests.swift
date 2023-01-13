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

import XCTest
@testable import PlistUtil

final class SwiftLiteralTests: XCTestCase {
    func assertVal(_ value: Any, looksLike string: String) {
        guard let literal = try? PlistUtil.itemAsSwiftLiteral(value) else {
            XCTFail("Didn't expect nil literal value for \(value)")
            return
        }
        XCTAssertEqual(literal, string)
    }

    func testInt() {
        assertVal(5, looksLike: "5")
    }

    func testString() {
        assertVal("foo", looksLike: "\"foo\"")
    }

    func testBool() {
        assertVal(true, looksLike: "true")
        assertVal(false, looksLike: "false")
    }

    func testData() {
        assertVal(Data([1, 2, 3]), looksLike: "Data([1, 2, 3])")
    }

    func testArray() {
        assertVal([1, 2, 3], looksLike: "[1, 2, 3]")
        assertVal(["foo", "bar", "baz"], looksLike: "[\"foo\", \"bar\", \"baz\"]")
        assertVal([1, "bar", 3], looksLike: "[1, \"bar\", 3]")
    }
}
