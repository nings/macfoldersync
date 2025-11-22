//
//  Item.swift
//  FolderSyncPro
//
//  Created by Ning on 2025/11/22.
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
