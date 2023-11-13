//
//  File.swift
//  
//
//  Created by John Biggs on 13.11.23.
//

import Foundation

extension CodingCollection: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension CodingCollection: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension CodingCollection: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension CodingCollection: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension CodingCollection: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .double(value)
    }
}

extension CodingCollection: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CodingCollection...) {
        self = .list(elements)
    }
}

extension CodingCollection: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (CodingCollection, CodingCollection)...) {
        self = .dictionary(.init(
            elements,
            uniquingKeysWith: { lhs, rhs in
                fatalError("Specified the same key twice: \(lhs) and \(rhs)")
            }
        ))
    }
}
