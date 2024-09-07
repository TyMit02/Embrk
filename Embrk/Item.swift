//
//  Item.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/7/24.
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
