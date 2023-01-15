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
import ArgumentParser

struct Extract: PlistUtilSubcommandWithInputAndOutputFile {
    static let configuration = CommandConfiguration(
        abstract: "Extract a nested value to another plist.",
        usage: "extract --key NestedDict --format xml --out-file nested.plist example.plist",
        discussion: """
            For the ^ and $ key specifications respectively marking the beginning or end of \
            a list, this subcommand will extract the item at the specified location.

            Extraction of simpler types, like Ints and Strings, to stdout will be supported in a \
            future release. For now, this only supports extracting nested data structures into \
            separate files.
            """
    )

    @Option(name: .long, help: Format.usage)
    var format: Format?

    @Option(name: [.short, .customLong("out-file")], help: PlistUtil.outputPathUsage)
    var outputFile: String

    @Option(name: [.customShort("k"), .customLong("key")], help: PlistUtil.keyPathUsage)
    var keyPath: [String]

    @Argument(help: PlistUtil.filePathUsage)
    var file: String

    var inputFile: String { file }

    func validate() throws {
        guard !keyPath.isEmpty else { throw FatalError.didNotSpecify(argument: "key") }
    }

    mutating func mutate(_ contents: Any) throws -> Any? {
        let subValue = try extract(from: contents, forKeyPath: keyPath)

        guard (subValue is [AnyHashable: Any]) || (subValue is [Any]) else {
            throw FatalError.cantExtractValue(keyPath: keyPath)
        }
        
        return subValue
    }

    func extract(from plist: Any?,
                 forKeyPath keyPath: [String],
                 keyPathSoFar: [String] = []) throws -> Any? {
        // guaranteed to be non-empty when we first start, then guaranteed via the base case checks below
        var keyPath = keyPath
        let key = keyPath.removeFirst()
        let keyPathSoFar = keyPathSoFar + [key]

        func recurse(into subValue: Any?) throws -> Any? {
            return try extract(from: subValue, forKeyPath: keyPath, keyPathSoFar: keyPathSoFar)
        }

        switch plist {
        case let stringDict as [String: Any]:
            guard !keyPath.isEmpty else {
                return stringDict[key]
            }
            return try recurse(into: stringDict[key])
        case let list as [Any?]:
            guard let loc = ArrayLocation(key: key) else {
                throw FatalError.invalidKeyType(requiredType: .int, keyPath: keyPathSoFar)
            }
            switch loc {
            case .index(let index):
                guard !keyPath.isEmpty else {
                    return list[index]
                }
                return try recurse(into: list[index])
            case .start:
                guard !keyPath.isEmpty else {
                    return list.first as Any?
                }
                return try recurse(into: list.first as Any?)
            case .end:
                guard !keyPath.isEmpty else {
                    return list.last as Any?
                }
                return try recurse(into: list.last as Any?)
            }
        default:
            let typeName = plist == nil ? "nil" : PlistUtil.swiftCollectionTypeName(plist!)
            throw FatalError.unsupportedIndex(type: typeName, keyPath: keyPathSoFar)
        }
    }
}
