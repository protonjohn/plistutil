//
//  CodingCollectionTests.swift
//  
//
//  Created by John Biggs on 13.11.23.
//

import Foundation

import XCTest

@testable import CodingCollection

class CodingCollectionTests: XCTestCase {
    func testBasicEval() throws {
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

        try initialValues.apply(caseDict: evalDict, preservingOriginalValues: true)
        XCTAssertEqual(initialValues.value as! [String: AnyHashable], expectedResult.value as! [String: AnyHashable])
    }
}
