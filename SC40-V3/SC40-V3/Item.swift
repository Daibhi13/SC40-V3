//
//  Item.swift
//  SC40-V3
//
//  Created by David O'Connell on 17/10/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
