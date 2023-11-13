//
//  Eval.swift
//  
//
//  Created by John Biggs on 13.11.23.
//

import Foundation
import ArgumentParser
import CodingCollection

final class Eval: PlistUtilSubcommandWithInputAndOutputFile {
    static let configuration = CommandConfiguration(
        abstract: "Evaluate a series of dictionary rules, starting with a set of initial values.",
        usage: "eval --format json info.json rules1.json rules2.json",
        discussion: """
            Yo' mama.
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

    @Flag(inversion: .prefixedNo)
    var preserveInitialValues: Bool = true

    @Option(help: "The path where the file should be created.")
    var outputFile: String

    @Argument()
    var files: [String]

    var evalFile: String? = nil
    var inputFile: String {
        evalFile ?? files.first ?? outputFile
    }

    func validate() throws {
        guard files.count > 1 else {
            throw FatalError.noInputFilesSpecified
        }
    }

    func mutate(_ contents: Any) throws -> Any? {
        var arguments = CodingCollection(value: contents)

        for file in files[1...] {
            evalFile = file
            let (contents, _) = try self.contents()
            guard let fileContents = CodingCollection(value: contents) else {
                throw FatalError.couldNotGetContents(of: URL(string: file)!)
            }

            try arguments?.apply(caseDict: fileContents, preservingOriginalValues: preserveInitialValues)
            preserveInitialValues = false
        }

        return arguments?.value
    }
}
