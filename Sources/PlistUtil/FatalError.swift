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

enum FatalError: Error, CustomStringConvertible {
    case invalidPath(String)
    case noFileExists(at: URL)
    case noValueExists(keyPath: [String])
    case invalidKeyType(requiredType: DataType, keyPath: [String])
    case invalidValue(String, type: DataType)
    case couldNotGetContents(of: URL)
    case cantConvert(from: Format)
    case wontConvertLossily(to: Format)
    case didNotSpecify(argument: String)
    case noCollectionLiterals(type: String)
    case unsupportedIndex(type: String, keyPath: [String])
    case cantExpressType(String)
    case utf8EncodingError
    case noInputFilesSpecified
    case cantExtractValue(keyPath: [String])

    var description: String {
        switch self {
        case .invalidPath(let argument):
            return "\(argument) is not a valid path."
        case .noFileExists(let url):
            return "no file exists at \(url.absoluteString)."
        case .noValueExists(let keyPath):
            return "no value exists for key(s) \(keyPath.joined(separator: "."))"
        case .invalidKeyType(let requiredType, let keyPath):
            return "key \(keyPath.joined(separator: ".")) was not of the expected type '\(requiredType.rawValue)'"
        case let .invalidValue(value, type):
            return "'\(value)' is not a valid value for type '\(type.rawValue)'"
        case .couldNotGetContents(let url):
            return "could not get contents of file at \(url.absoluteString)."
        case .cantConvert(let format):
            return "can't convert from '\(format.rawValue)'."
        case .wontConvertLossily(let format):
            return "won't convert to \(format.rawValue) in-place as it would cause data loss; please specify an output file."
        case .didNotSpecify(let argument):
            return "did not specify '\(argument)'."
        case .noCollectionLiterals(let type):
            return """
            literals for collections of type '\(type)' are not supported. \
            Leave `value' unspecified to create an empty collection for the key in the target file, \
            then use this script again to insert the individual items.
            """
        case let .unsupportedIndex(type, keyPath):
            return "don't know how to index into type '\(type)' at '\(keyPath.joined(separator: "."))'."
        case .cantExpressType(let type):
            return "don't know how to express type '\(type)'."
        case .utf8EncodingError:
            return "unable to express plist as utf8-encoded data."
        case .noInputFilesSpecified:
            return "no input files specified."
        case .cantExtractValue(let keyPath):
            return "the value at \(keyPath.joined(separator: ".")) doesn't exist or isn't a collection."
        }
    }
}
