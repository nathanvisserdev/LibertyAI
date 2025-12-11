//
//  Item.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
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
