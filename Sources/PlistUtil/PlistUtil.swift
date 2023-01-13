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
        case .swift:
            return nil
        }
    }

    static let usage = ArgumentHelp(stringLiteral:
        "The output format of the property list. Acceptible formats: \(casesString)."
    )
}

@main
public struct PlistUtil: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "plistutil",
        subcommands: [
            Convert.self,
            Create.self,
            Extract.self,
            Insert.self,
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
            result = []
        case .dict:
            result = [:]
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
    static let keyTypeUsage = ArgumentHelp(stringLiteral: """
        The types of each key. If specified, must be equal to the number of keys. By default, all keys are assumed to \
        be strings.
        """
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
    mutating func contents() throws -> (Any, PropertyListSerialization.PropertyListFormat?)
    mutating func mutate(_ contents: Any) throws -> Any?
    func write(_ plist: Any?, originalFormat: PropertyListSerialization.PropertyListFormat?) throws
}

protocol PlistUtilSubcommandWithInputFile: PlistUtilSubcommand {
    var inputFile: String { get }
}

protocol PlistUtilSubcommandWithOutputFile: PlistUtilSubcommand {
    var format: Format? { get set }
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
        let (plist, plistFormat) = try contents()
        try write(mutate(plist), originalFormat: plistFormat)
    }
}

extension PlistUtilSubcommandWithInputFile {
    func contents() throws -> (Any, PropertyListSerialization.PropertyListFormat?) {
        guard let plistPath = URL(string: inputFile) else { throw FatalError.invalidPath(inputFile) }

        guard FileSystem.fileExists(inputFile) else { throw FatalError.noFileExists(at: plistPath) }
        guard let contents = FileSystem.contents(inputFile) else { throw FatalError.couldNotGetContents(of: plistPath) }

        var plistFormat: PropertyListSerialization.PropertyListFormat = .xml
        let result = try PropertyListSerialization.propertyList(from: contents, format: &plistFormat)
        return (result, plistFormat)
    }
}

extension PlistUtilSubcommandWithOutputFile {
    func write(_ plist: Any?, originalFormat: PropertyListSerialization.PropertyListFormat?) throws {
        let outputFile = URL(string: outputFile)! // for certain commands, if outputFile unspecified, inputFile is done in-place

        let data: Data
        if format == .swift {
            let dictName = outputFile.deletingPathExtension().lastPathComponent.lowercasingFirstLetter
            let typeName = PlistUtil.swiftCollectionTypeName(plist!)
            let literal = try "let \(dictName): \(typeName) = \(PlistUtil.itemAsSwiftLiteral(plist!))\n"
            guard let literalData = literal.data(using: .utf8) else {
                throw FatalError.utf8EncodingError
            }
            data = literalData
        } else {
            let plistFormat = format?.plistFormat ?? originalFormat ?? .xml
            data = try PropertyListSerialization.data(fromPropertyList: plist!, format: plistFormat, options: 0)
        }

        try? FileSystem.removeItem(outputFile)
        _ = FileSystem.createFile(outputFile.absoluteString, data, nil)
    }
}
