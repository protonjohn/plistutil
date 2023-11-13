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

struct Print: PlistUtilSubcommandWithInputFile {
    static let configuration = CommandConfiguration(
        abstract: "Print the contents of a plist.",
        usage: """
            print example.plist
            """,
        discussion: """
            Keys are printed in alphabetical order.
            """
    )

    @Argument(help: PlistUtil.filePathUsage)
    var file: String

    @Option(name: .long, help: Format.usage)
    var inputFormat: Format?

    var inputFile: String { file }

    func mutate(_ contents: Any) -> Any? {
        contents
    }

    func write(_ plist: Any?, originalFormat: Format?) throws {
        if let originalFormat {
            Console.print("format: \(originalFormat.rawValue)")
        }

        Console.print(String(describing: plist as AnyObject))
    }
}
