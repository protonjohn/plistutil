//
//  CodingCollection+Codable.swift
//  
//
//  Created by John Biggs on 13.11.23.
//

import Foundation

extension CodingCollection: Codable {
    private static let nullValue: String? = nil

    static func decode<T: Decodable>(using item: (T) -> Self, in container: SingleValueDecodingContainer) -> Self? {
        return try? item(container.decode(T.self))
    }

    static func decoder<T: Decodable>(_ item: @escaping (T) -> Self) -> ((SingleValueDecodingContainer) -> Self?) {
        return { Self.decode(using: item, in: $0) }
    }

    public init(from decoder: Decoder) throws {
        typealias Empty = String?
        let container = try decoder.singleValueContainer()

        let cases = [
            Self.decoder(Self.int),
            Self.decoder(Self.double),
            Self.decoder(Self.bool),
            Self.decoder(Self.string),
            Self.decoder(Self.data),
            Self.decoder(Self.list),
            Self.decoder({ (stringDict: [String: Self]) -> Self in
                Self.dictionary(stringDict.reduce(into: [:], { $0[.string($1.key)] = $1.value }))
            }),
            Self.decoder({ (boolDict: [Bool: Self]) -> Self in
                Self.dictionary(boolDict.reduce(into: [:], { $0[.bool($1.key)] = $1.value }))
            }),
            Self.decoder({ (dataDict: [Data: Self]) -> Self in
                Self.dictionary(dataDict.reduce(into: [:], { $0[.data($1.key)] = $1.value }))
            }),
            Self.decoder({ (intDict: [Int: Self]) -> Self in
                Self.dictionary(intDict.reduce(into: [:], { $0[.int($1.key)] = $1.value }))
            }),
            Self.decoder({ (nothing: Empty) in .null }), // for null values
        ]

        for closure in cases {
            if let item = closure(container) {
                self = item
                return
            }
        }

        assertionFailure("Unexpected value encountered: \(String(describing: decoder))")
        self = .null
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encode(Self.nullValue)
        case let .int(int): try container.encode(int)
        case let .bool(bool): try container.encode(bool)
        case let .data(data): try container.encode(data)
        case let .double(double): try container.encode(double)
        case let .string(string): try container.encode(string)
        case let .list(list): try container.encode(list)
        case let .dictionary(dict):
            // Try to use a type that the encoder will find acceptable
            if dict.keys.allSatisfy(\.isString) {
                try container.encode(dict.reduce(into: [String: CodingCollection](), {
                    $0[$1.key.value as! String] = $1.value
                }))
            } else if dict.keys.allSatisfy(\.isBool) {
                try container.encode(dict.reduce(into: [Bool: CodingCollection](), {
                    $0[$1.key.value as! Bool] = $1.value
                }))
            } else if dict.keys.allSatisfy(\.isData) {
                try container.encode(dict.reduce(into: [Data: CodingCollection](), {
                    $0[$1.key.value as! Data] = $1.value
                }))
            } else if dict.keys.allSatisfy(\.isInt) {
                try container.encode(dict.reduce(into: [Int: CodingCollection](), {
                    $0[$1.key.value as! Int] = $1.value
                }))
            } else {
                throw CodingCollectionError.unsupportedEncodingValue(dict)
            }
        }
    }
}
