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

enum ArrayLocation: CustomStringConvertible {
    case start
    case end
    case index(Int)

    init?(key: String) {
        if let index = Int(key) {
            self = .index(index)
        } else if key == "^" {
            self = .start
        } else if key == "$" {
            self = .end
        } else {
            return nil
        }
    }

    var description: String {
        switch self {
        case .start:
            return "start"
        case .end:
            return "end"
        case .index(let index):
            return "index \(index)"
        }
    }
}

extension Array {
    var second: Element? {
        guard count > 1 else { return nil }
        return self[1]
    }
}
