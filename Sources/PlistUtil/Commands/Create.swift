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

struct Create: PlistUtilSubcommandWithOutputFile {
    static let configuration = CommandConfiguration(
        abstract: "Create an empty plist file.",
        usage: "create --output-format binary example.plist",
        discussion: """
            This command will create an empty list or dictionary at the specified file location.

            Note that since this command cannot read certain formats, like swift dictionaries, some \
            output formats may be more useful than others.
            """
    )

    @Option(name: .long, help: Format.usage)
    var outputFormat: Format?

    @Option(name: .long, help: "The type of the value to create.")
    var type: DataType = .dict

    @Argument(help: "The path where the file should be created.")
    var outputFile: String

    func contents() throws -> (Any, Format?) {
        switch type {
        case .list:
            return ([] as [Any], nil)
        case .dict:
            return ([:] as [String: Any], nil)
        default:
            throw FatalError.cantExpressType(type.rawValue)
        }
    }

    func mutate(_ contents: Any) -> Any? {
        contents
    }
}
