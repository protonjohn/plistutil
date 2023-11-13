//
//  EvalTests.swift
//  
//
//  Created by John Biggs on 13.11.23.
//

import Foundation
import CodingCollection
import Yams
import XCTest

@testable import PlistUtil

@available(macOS 13, *)
class EvalTests: PlistUtilTestCase {
    func testEval() throws {
        var initialValues: CodingCollection = [
            "hello": "world",
            "config": "value",
            "setting": true,
        ]

        let evalDict: CodingCollection = [
            ".cases": [
                [
                    ".if": "hello",
                    "world": [
                        "world": "goodbye",
                    ],
                ],
                [
                    ".ifSet": "setting",
                    "theOtherSetting": ["is", "a", "list"]
                ],
            ],
            ".contexts": [
                "test": [
                    ".map": [
                        "config": "sub_config",
                    ],
                    ".include": [
                        "hello"
                    ]
                ],
                "redact": [
                    ".exclude": [
                        "world",
                        "hello"
                    ]
                ]
            ]
        ]

        let initialValuesData = try YAMLEncoder().encode(initialValues).data(using: .utf8)
        let evalDictData = try YAMLEncoder().encode(evalDict).data(using: .utf8)
        fs.createFile("/initialValues.yaml", initialValuesData, nil)
        fs.createFile("/evalDict.yaml", evalDictData, nil)

        func getProperties(at path: String = "/initialValues.yaml") -> CodingCollection? {
            guard let contents = fs.contents(atPath: path) else {
                XCTFail("Should have created contents at \(path)")
                return nil
            }

            let properties = try? YAMLDecoder().decode(CodingCollection.self, from: contents)
            return properties
        }

        Eval.main(["--output-file", "/finalValues.yaml", "--format", "yaml", "/initialValues.yaml", "/evalDict.yaml"])

        let finalValues = getProperties(at: "/finalValues.yaml")

        let expectedResult: CodingCollection = [
            "hello": "world",
            "world": "goodbye",
            "config": "value",
            "theOtherSetting": ["is", "a", "list"],
            "setting": true,
            "context_test": [
                "sub_config": "value",
                "hello": "world"
            ],
            "context_redact": [
                "config": "value",
                "theOtherSetting": ["is", "a", "list"],
                "setting": true
            ]
        ]
        XCTAssertEqual(finalValues!.value as! [String: AnyHashable], expectedResult.value as! [String: AnyHashable])

    }
}
