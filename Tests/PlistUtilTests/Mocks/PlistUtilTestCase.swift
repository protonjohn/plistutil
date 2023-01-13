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
@testable import PlistUtil

@available(macOS 13.0, *)
class NaiveFilesystem {
    var files: [String: Data?] = [ "/": nil ]

    func createDirectory(_ url: URL, _ withIntermediateDirectories: Bool, _ attributes: [FileAttributeKey : Any]?) -> Bool {
        let parentDir = url.deletingLastPathComponent()
        // make sure parent directory exists
        if files["\(url.deletingLastPathComponent().absoluteString)"] == nil {
            guard withIntermediateDirectories else {
                return false
            }

            guard createDirectory(parentDir, true, attributes) else {
                return false
            }
        }

        let component = url.lastPathComponent
        let urlAsFile = parentDir.appending(path: component, directoryHint: .notDirectory)

        // make sure this isn't a directory
        guard files["\(urlAsFile.absoluteString)"] == nil else { return false }

        // good to go :)
        files[url.absoluteString] = nil
        return true
    }

    @discardableResult
    func createFile(_ path: String, _ contents: Data?, _ attributes: [FileAttributeKey : Any]?) -> Bool {
        let url = URL(string: path)!.absoluteURL
        let parentDir = url.deletingLastPathComponent()
        // make sure parent directory exists
        guard files["\(url.deletingLastPathComponent().absoluteString)"] != nil else { return false }

        let component = url.lastPathComponent
        let urlAsDir = parentDir.appending(path: component, directoryHint: .isDirectory)

        // make sure this isn't a directory
        guard files["\(urlAsDir.absoluteString)"] == nil else { return false }

        // good to go :)
        files[url.absoluteString] = contents
        return true
    }

    func removeItem(at url: URL) throws {
        guard url.absoluteString != "/" else { throw POSIXError(.EPERM) }

        files.removeValue(forKey: url.absoluteString)
    }

    func fileExists(atPath path: String) -> Bool {
        files[URL(string: path)!.absoluteString] != nil
    }

    func contents(atPath path: String) -> Data? {
        files[URL(string: path)!.absoluteString] ?? nil
    }
}

@available(macOS 13.0, *)
class PlistUtilTestCase: XCTestCase {
    let fs = NaiveFilesystem()
    var console = ""

    override func setUp() {
        FileSystem.createFile = fs.createFile
        FileSystem.removeItem = fs.removeItem
        FileSystem.fileExists = fs.fileExists
        FileSystem.contents = fs.contents
        
        Console.print = { [weak self] in
            self?.console.append("\($0)\n")
        }
    }
}

enum Equality {
    typealias Dict = Dictionary<AnyHashable, Any>
    typealias List = Array<Any>
    
    static func element(_ lhs: Any, definitelyEqualsPlistElement rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case let (l, r) as (Bool, Bool):
            return l == r
        case let (l, r) as (Int, Int):
            return l == r
        case let (l, r) as (String, String):
            return l == r
        case let (l, r) as (Data, Data):
            return l == r
        case let (l, r) as (Dict, Dict):
            return l.collectionDefinitelyEquals(otherPlist: r)
        case let (l, r) as (List, List):
            return l.collectionDefinitelyEquals(otherPlist: r)
        default:
            return false
        }
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func collectionDefinitelyEquals(otherPlist: Self) -> Bool {
        guard count == otherPlist.count else {
            return false
        }
        
        for (key, lhs) in self {
            guard let rhs = otherPlist[key] else {
                return false
            }

            guard Equality.element(lhs, definitelyEqualsPlistElement: rhs) else {
                return false
            }
        }
        return true
    }
}

extension Array where Element == Any {
    func collectionDefinitelyEquals(otherPlist: Self) -> Bool {
        guard count == otherPlist.count else {
            return false
        }

        for (index, lhs) in self.enumerated() {
            let rhs = otherPlist[index]

            guard Equality.element(lhs, definitelyEqualsPlistElement: rhs) else {
                return false
            }
        }
        return true
    }
}
