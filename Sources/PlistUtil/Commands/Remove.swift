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

struct Remove: PlistUtilSubcommandWithInputAndOutputFile {
    static let configuration = CommandConfiguration(
        abstract: "Insert a value into the plist.",
        usage: """
            remove --key BoolKey example.plist
            remove --key TopLevelKey --key LowerLevelKey example.plist
            remove --key ArrayKey --key "$" example.plist
            remove --key ArrayKey --key "^" example.plist
            remove --key ArrayKey --key "0" example.plist
            """,
        discussion: """
            For the ^ and $ key specifications respectively marking the beginning or end of \
            a list, this subcommand will remove the item at the specified location.

            Data types are also supported by entering the data in as a base64-encoded string.
            """
    )

    @Option(name: .long, help: Format.usage)
    var inputFormat: Format?

    @Option(name: .long, help: Format.usage)
    var outputFormat: Format?

    @Option(name: .shortAndLong, help: PlistUtil.outputPathUsage)
    var outFile: String?

    @Option(name: [.customShort("k"), .customLong("key")], help: PlistUtil.keyPathUsage)
    var keyPath: [String]
    
    @Argument(help: PlistUtil.filePathUsage)
    var file: String

    var inputFile: String { file }
    var outputFile: String { outFile ?? file }

    func mutate(_ contents: Any) throws -> Any? {
        var contents: Any? = contents
        try remove(from: &contents, valueAtKeyPath: keyPath)
        return contents
    }

    func remove(from plist: inout Any?,
                valueAtKeyPath keyPath: [String],
                keyPathSoFar: [String] = []) throws {
        guard plist != nil else {
            throw FatalError.noValueExists(keyPath: keyPathSoFar)
        }

        // guaranteed to be non-empty when we first start, then guaranteed via the base case checks below
        var keyPath = keyPath
        let key = keyPath.removeFirst()
        let keyPathSoFar = keyPathSoFar + [key]
        func recurse(into subValue: inout Any?) throws {
            try remove(from: &subValue, valueAtKeyPath: keyPath, keyPathSoFar: keyPathSoFar)
        }

        switch plist {
        case var stringDict as [String: Any]:
            defer { plist = stringDict }

            guard !keyPath.isEmpty else {
                stringDict.removeValue(forKey: key)
                return
            }
            try recurse(into: &stringDict[key])
        case var list as [Any?]:
            defer { plist = list }

            guard let loc = ArrayLocation(key: key) else {
                throw FatalError.invalidKeyType(requiredType: .int, keyPath: keyPathSoFar)
            }
            switch loc {
            case .index(let index):
                guard !keyPath.isEmpty else {
                    list.remove(at: index)
                    return
                }
                try recurse(into: &list[index])
            case .start:
                guard !keyPath.isEmpty else {
                    if !list.isEmpty {
                        list.removeFirst()
                    }
                    return
                }
                guard !list.isEmpty else {
                    throw FatalError.noValueExists(keyPath: keyPathSoFar)
                }
                try recurse(into: &list[0])
            case .end:
                guard !keyPath.isEmpty else {
                    if !list.isEmpty {
                        list.removeLast()
                    }
                    return
                }
                guard !list.isEmpty else {
                    throw FatalError.noValueExists(keyPath: keyPathSoFar)
                }
                try recurse(into: &list[list.count-1])
            }
        default:
            throw FatalError.unsupportedIndex(type: String(describing: Swift.type(of: plist)), keyPath: keyPathSoFar)
        }
    }
}
