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

struct Insert: PlistUtilSubcommandWithInputAndOutputFile {
  static let configuration = CommandConfiguration(
        abstract: "Insert a value into the plist.",
        usage: """
            insert --key BoolKey --type bool --value true example.plist
            insert --key TopLevelKey --key LowerLevelKey --type string --value "In a nested dictionary" example.plist
            insert --key ArrayKey --key "$" --type string --value "Appended to an array" example.plist
            insert --key ArrayKey --key "^" --type string --value "Prepended to an array" example.plist
            insert --key ArrayKey --key "0" --type string --value "Set value at index 0" example.plist
            """,
        discussion: """
            If a dictionary along a keypath is not encountered, an empty one will be created, and the \
            value inserted. So, the command:

            insert --key DictKey --key ExampleKey --type bool --value true example.plist

            when run on an empty plist, would look something like:

            {
              "DictKey" => {
                "ExampleKey" => true
              }
            }

            For the ^ and $ key specifications respectively marking the beginning or end of \
            a list, this subcommand will prepend or append the specified value.

            Data types are also supported by entering the data in as a base64-encoded string.
            """
    )

    @Option(name: .long, help: Format.usage)
    var format: Format?

    var inputFormat: Format? {
        format
    }

    var outputFormat: Format? {
        format
    }

    @Option(name: .long, help: DataType.usage)
    var type: DataType

    @Option(name: .shortAndLong, help: PlistUtil.outputPathUsage)
    var outFile: String?

    @Option(name: [.customShort("k"), .customLong("key")], help: PlistUtil.keyPathUsage)
    var keyPath: [String]

    @Option(name: .shortAndLong, help: "The value to set.")
    var value: String?

    @Argument(help: PlistUtil.filePathUsage)
    var file: String

    var inputFile: String { file }
    var outputFile: String { outFile ?? file }

    func validate() throws {
        guard !keyPath.isEmpty else { throw FatalError.didNotSpecify(argument: "key") }

        guard !(format == .swift && outFile == nil) else {
            throw FatalError.wontConvertLossily(to: .swift)
        }
        
        guard value != nil || type == .list || type == .dict else {
            throw FatalError.didNotSpecify(argument: "value")
        }

        guard (type != .list && type != .dict) || value == nil else {
            throw FatalError.noCollectionLiterals(type: type.rawValue)
        }
    }

    mutating func mutate(_ contents: Any) throws -> Any? {
        var plist: Any? = contents

        let typedValue = try PlistUtil.value(value, accordingTo: type)
        try insert(into: &plist, typedValue: typedValue, forKeyPath: keyPath)
        precondition(plist != nil, "plist was nil after inserting new value")
        return plist!
    }

    func insert(into plist: inout Any?,
                typedValue: Any,
                forKeyPath keyPath: [String],
                keyPathSoFar: [String] = []) throws {
        if plist == nil {
            plist = [String: Any]()
        }

        // guaranteed to be non-empty when we first start, then guaranteed via the base case checks below
        var keyPath = keyPath
        let key = keyPath.removeFirst()
        let keyPathSoFar = keyPathSoFar + [key]
        func recurse(into subValue: inout Any?) throws {
            try insert(into: &subValue, typedValue: typedValue, forKeyPath: keyPath, keyPathSoFar: keyPathSoFar)
        }

        switch plist {
        case var stringDict as [String: Any]:
            defer { plist = stringDict }

            guard !keyPath.isEmpty else {
                stringDict[key] = typedValue
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
                    list[index] = typedValue
                    return
                }
                try recurse(into: &list[index])
            case .start:
                guard !keyPath.isEmpty else {
                    list.insert(typedValue, at: 0)
                    return
                }

                var item: Any? = [String: Any]()
                try recurse(into: &item)
                list.insert(item, at: 0)
            case .end:
                guard !keyPath.isEmpty else {
                    list.append(typedValue)
                    return
                }

                var item: Any? = [String: Any]()
                try recurse(into: &item)
                list.append(item)
            }
        default:
            let typeName = plist == nil ? "nil" : PlistUtil.swiftCollectionTypeName(plist!)
            throw FatalError.unsupportedIndex(type: typeName, keyPath: keyPathSoFar)
        }
    }
}
