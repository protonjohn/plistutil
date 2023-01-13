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
    @Argument(help: PlistUtil.filePathUsage)
    var file: String

    var inputFile: String { file }

    func mutate(_ contents: Any) -> Any? {
        contents
    }

    func write(_ plist: Any?, originalFormat: PropertyListSerialization.PropertyListFormat?) throws {
        if let originalFormat {
            let format = Format(from: originalFormat)
            Console.print("format: \(format.rawValue)")
        }

        Console.print(String(describing: plist as AnyObject))
    }
}