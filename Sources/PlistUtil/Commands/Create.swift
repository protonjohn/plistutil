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
    @Option(name: .long, help: Format.usage)
    var format: Format?

    @Option(name: .long, help: "The type of the value to create.")
    var type: DataType

    @Argument(help: "The path where the file should be created.")
    var outputFile: String

    func contents() throws -> (Any, PropertyListSerialization.PropertyListFormat?) {
        switch type {
        case .list:
            return ([], nil)
        case .dict:
            return ([:], nil)
        default:
            throw FatalError.cantExpressType(type.rawValue)
        }
    }

    func mutate(_ contents: Any) -> Any? {
        contents
    }
}
