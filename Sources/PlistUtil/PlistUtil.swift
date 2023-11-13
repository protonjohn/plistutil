//
//  Created on 2022-11-21.
//
//  Copyright (c) 2022 Proton AG
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
import Yams
import CodingCollection
import ArgumentParser

internal typealias Option = ArgumentParser.Option

enum DataType: String, ExpressibleByArgument, CaseIterable {
    case bool
    case int
    case string
    case data
    case dict
    case list

    static let usage = ArgumentHelp(stringLiteral:
        "The type of the value being inserted. Acceptible types: \(casesString)."
    )
}

enum Format: String, ExpressibleByArgument, CaseIterable {
    case xml
    case binary
    case openStep
    case json
    case yaml
    case swift

    init(from format: PropertyListSerialization.PropertyListFormat) {
        switch format {
        case .xml:
            self = .xml
        case .binary:
            self = .binary
        case .openStep:
            self = .openStep
        @unknown default:
            fatalError("Unrecognized format type '\(format.rawValue)'")
        }
    }

    var plistFormat: PropertyListSerialization.PropertyListFormat? {
        switch self {
        case .openStep:
            return .openStep
        case .binary:
            return .binary
        case .xml:
            return .xml
        case .yaml, .json, .swift:
            return nil
        }
    }

    var isPlistFormat: Bool {
        plistFormat != nil
    }

    static let usage = ArgumentHelp(stringLiteral:
        "The output format of the property list. Acceptible formats: \(casesString)."
    )
}

@main
public struct PlistUtil: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "plistutil",
        abstract: "A utility for modifying property list files.",
        usage: """
            plistutil create --format binary example.plist
            plistutil insert --key Example --value Test --type string example.plist
            plistutil print example.plist
            plistutil convert --format xml --in-file example.plist xml.plist
            plistutil remove --key Example example.plist
            plistutil print example.plist
            """,
        discussion: """
            See each subcommand's help message for more specific usage information.

            For subcommands which take a keypath, the key is assumed to be a string, unless the value \
            encountered along the keypath is a list. In that case, the key can be one of the following:
            - An integer representing a zero-indexed reference to an existing element in the list
            - A ^ or $ character, respectively representing the beginning or end of the list
            """,
        subcommands: [
            Convert.self,
            Create.self,
            Extract.self,
            Insert.self,
            Print.self,
            Remove.self,
        ]
    )

    public init() {}

    public static func runMain() {
        Self.main()
    }

    static func value(_ value: String?, accordingTo type: DataType) throws -> Any {
        let result: Any?

        switch type {
        case .bool where value != nil:
            result = Bool(value!)
        case .int where value != nil:
            result = Int(value!)
        case .string:
            result = value
        case .data where value != nil:
            result = Data(base64Encoded: value!, options: .ignoreUnknownCharacters)
        case .list:
            result = [] as [Any]
        case .dict:
            result = [:] as [String: Any]
        default:
            result = nil
        }

        guard let result else {
            throw FatalError.invalidValue(value ?? "", type: type)
        }

        return result
    }
    
    static func swiftCollectionTypeName(_ item: Any) -> String {
        switch item {
        case let dict as [AnyHashable: Any] where dict.isEmpty:
            return "[AnyHashable: Any]"
        case is [String: [String: Any]]:
            return "[String: [String: Any]]"
        case is [String: Any]:
            return "[String: Any]"
        case is [String]:
            return "[String]"
        case is [Data]:
            return "[Data]"
        case is [Int]:
            return "[Int]"
        case is [Bool]:
            return "[Bool]"
        case is [Any]:
            return "[Any]"
        default:
            return "Any"
        }
    }

    static func itemAsSwiftLiteral(_ item: Any, level: Int = 0) throws -> String {
        switch item {
        case let bool as Bool:
            return "\(bool)"
        case let int as Int:
            return "\(int)"
        case let string as String:
            return "\"\(string)\""
        case let data as Data:
            return "Data([" + data.map({ "\($0)" }).joined(separator: ", ") + "])"
        case let dict as [String: Any]:
            guard !dict.isEmpty else { return "[:]" }

            let indent = String(repeating: "\t", count: level)
            let elements = try dict.sorted(by: { $0.key < $1.key })
                .map {
                    try "\n\t" + indent +
                        itemAsSwiftLiteral($0.key, level: level + 1) + ": " +
                        itemAsSwiftLiteral($0.value, level: level + 1)
                }

            return "[" + elements.joined(separator: ",") + "\n" + indent + "]"
        case let list as [Any]:
            return try "[" + list.map({ try itemAsSwiftLiteral($0, level: level + 1) }).joined(separator: ", ") + "]"
        default:
            throw FatalError.cantExpressType(String(describing: Swift.type(of: item)))
        }
    }

    static let filePathUsage = ArgumentHelp(stringLiteral: "The plist file to use.")
    static let outputPathUsage = ArgumentHelp(stringLiteral:
        "An optional file to use as output. Certain formats require this option to avoid data loss."
    )
    static let keyPathUsage = ArgumentHelp(stringLiteral: """
        The key to index. If more than one is specified, each key will be treated as indexing into a dictionary \
        value one level down. Can also be used to index into arrays if the key is an integer and the indexed value \
        is a list type.
        """
    )
}

enum Console {
    static var print: ((String) -> ()) = {
        print($0)
    }
}

enum FileSystem {
    static var createDirectory = FileManager.default.createDirectory(at:withIntermediateDirectories:attributes:)
    static var createFile = FileManager.default.createFile(atPath:contents:attributes:)
    static var removeItem = FileManager.default.removeItem(at:)
    static var fileExists = FileManager.default.fileExists(atPath:)
    static var contents   = FileManager.default.contents(atPath:)
}

protocol PlistUtilSubcommand: ParsableCommand {
    mutating func contents() throws -> (Any, Format?)
    mutating func mutate(_ contents: Any) throws -> Any?
    func write(_ plist: Any?, originalFormat: Format?) throws
}

protocol PlistUtilSubcommandWithInputFile: PlistUtilSubcommand {
    var inputFormat: Format? { get }
    var inputFile: String { get }
}

protocol PlistUtilSubcommandWithOutputFile: PlistUtilSubcommand {
    var outputFormat: Format? { get }
    var outputFile: String { get }
}

protocol PlistUtilSubcommandWithKeyPath: PlistUtilSubcommand {
    var keyPath: [String] { get set }
    var keyTypes: [DataType] { get set }
}

protocol PlistUtilSubcommandWithInputAndOutputFile: PlistUtilSubcommandWithInputFile & PlistUtilSubcommandWithOutputFile {
}

extension PlistUtilSubcommand {
    mutating func run() throws {
        let (dict, format) = try contents()
        try write(mutate(dict), originalFormat: format)
    }
}

extension PlistUtilSubcommandWithInputFile {
    func contents() throws -> (Any, Format?) {
        guard let plistPath = URL(string: inputFile) else { throw FatalError.invalidPath(inputFile) }
        guard FileSystem.fileExists(inputFile) else { throw FatalError.noFileExists(at: plistPath) }
        guard let contents = FileSystem.contents(inputFile) else { throw FatalError.couldNotGetContents(of: plistPath) }

        switch inputFormat {
        case .binary, .openStep, .xml, nil:
            var plistFormat: PropertyListSerialization.PropertyListFormat = .xml
            let result = try PropertyListSerialization.propertyList(from: contents, format: &plistFormat)
            return (result, Format(from: plistFormat))
        case .json:
            return (try JSONDecoder().decode(CodingCollection.self, from: contents), .json)
        case .yaml:
            return (try YAMLDecoder().decode(CodingCollection.self, from: contents), .yaml)
        case .swift:
            throw FatalError.cantConvert(from: .swift)
        }
    }
}

extension PlistUtilSubcommandWithOutputFile {
    func write(_ plist: Any?, originalFormat: Format?) throws {
        let outputFile = URL(string: outputFile)! // for certain commands, if outputFile unspecified, inputFile is done in-place

        let outputFormat = outputFormat ?? originalFormat

        let data: Data
        switch outputFormat {
        case .swift:
            let dictName = outputFile.deletingPathExtension().lastPathComponent.lowercasingFirstLetter
            let typeName = PlistUtil.swiftCollectionTypeName(plist!)
            let literal = try "let \(dictName): \(typeName) = \(PlistUtil.itemAsSwiftLiteral(plist!))\n"
            guard let literalData = literal.data(using: .utf8) else {
                throw FatalError.utf8EncodingError
            }
            data = literalData
        case .xml, .binary, .openStep, nil:
            data = try PropertyListSerialization.data(fromPropertyList: plist!, format: outputFormat?.plistFormat ?? .xml, options: 0)
        case .json:
            let codingValue = CodingCollection(value: plist)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            data = try encoder.encode(codingValue)
        case .yaml:
            let codingValue = CodingCollection(value: plist)
            let encoder = YAMLEncoder()
            encoder.options = .init(sortKeys: true)
            data = try encoder.encode(codingValue).data(using: .utf8) ?? Data()
        }

        try? FileSystem.removeItem(outputFile)
        _ = FileSystem.createFile(outputFile.absoluteString, data, nil)
    }
}
