//
//  CodingCollection.swift
//  
//
//  Created by John Biggs on 27.10.23.
//

import Foundation

public indirect enum CodingCollection: Equatable, Hashable {
    case null
    case int(Int)
    case bool(Bool)
    case data(Data)
    case double(Double)
    case string(String)

    case list([Self])
    case dictionary([Self: Self])
}

public extension CodingCollection {
    var isInt: Bool {
        guard case .int = self else { return false }
        return true
    }
    var isData: Bool {
        guard case .data = self else { return false }
        return true
    }
    var isBool: Bool {
        guard case .bool = self else { return false }
        return true
    }
    var isString: Bool {
        guard case .string = self else { return false }
        return true
    }
}

public extension CodingCollection {
    subscript(_ key: Self) -> Self? {
        get throws {
            guard case .dictionary(let dictionary) = self else {
                throw CodingCollectionError.notADictionary(self)
            }

            return dictionary[key]
        }
    }
}

public extension CodingCollection {
    var value: AnyHashable? {
        switch self {
        case .null:
            return nil
        case .int(let int):
            return int
        case .bool(let bool):
            return bool
        case .data(let data):
            return data
        case .double(let double):
            return double
        case .string(let string):
            return string
        case .list(let array):
            return array.map(\.value)
        case .dictionary(let dictionary):
            var result: [AnyHashable?: AnyHashable] = [:]
            for (key, value) in dictionary {
                result[key.value] = value.value
            }
            return result
        }
    }

    init?(value: Any?) {
        switch value {
        case let selfValue as Self:
            self = selfValue
        case nil:
            self = .null
        case let int as Int:
            self = .int(int)
        case let bool as Bool:
            self = .bool(bool)
        case let data as Data:
            self = .data(data)
        case let double as Double:
            self = .double(double)
        case let string as String:
            self = .string(string)
        case let list as [Any?]:
            var result: [Self] = []
            for item in list {
                guard let value = Self(value: item) else {
                    return nil
                }
                result.append(value)
            }
            self = .list(result)
        case let dict as [AnyHashable: Any?]:
            var result: [Self: Self] = [:]
            for (key, value) in dict {
                guard let keyValue = Self(value: key), let dictValue = Self(value: value) else {
                    return nil
                }
                result[keyValue] = dictValue
            }
            self = .dictionary(result)
        default:
            return nil
        }
    }
}


public enum CodingCollectionError: Error, CustomStringConvertible {
    case unsupportedEncodingValue(Any)
    case notADictionary(CodingCollection)
    case valueNotFound(CodingCollection, in: CodingCollection, for: CodingCollection?)
    case expectedString
    case expectedSymbol
    case unrecognizedSymbol(String)
    case expectedList
    case invalidCaseStep(CodingCollection)
    case expectedDictionary

    public var description: String {
        switch self {
        case .unsupportedEncodingValue(let value):
            return "\(value) is not supported for encoding."
        case .notADictionary(let value):
            return "Expected a dictionary but got \(value)."
        case let .valueNotFound(value, collection, key):
            return "\(value) was not found under key \(String(describing: key)) for collection \(collection)."
        case .expectedList:
            return "Expected a list."
        case .expectedDictionary:
            return "Expected a dictionary."
        case .expectedSymbol:
            return "Expected a symbol."
        case let .unrecognizedSymbol(symbol):
            return "Unrecognized symbol '\(symbol)'"
        case let .invalidCaseStep(value):
            return "Invalid case step \(value)."
        case .expectedString:
            return "Expected string."
        }
    }
}
