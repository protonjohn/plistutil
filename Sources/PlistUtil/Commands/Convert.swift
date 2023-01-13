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

struct Convert: PlistUtilSubcommandWithInputAndOutputFile {
    @Option(name: .long, help: Format.usage)
    var format: Format?

    @Option(name: .shortAndLong, help: "An optional file to use as output. Certain formats require this option to avoid data loss.")
    var outFile: String?

    @Argument(help: "The plist file to use.")
    var file: String

    var inputFile: String { file }
    var outputFile: String { outFile ?? file }

    func validate() throws {
        guard format != nil else {
            throw FatalError.didNotSpecify(argument: "format")
        }

        guard !(format == .swift && outFile == nil) else {
            throw FatalError.wontConvertLossily(to: .swift)
        }
    }

    func mutate(_ contents: Any) -> Any? {
        contents // no need to mutate, we're just converting :)
    }
}
