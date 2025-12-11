//
//  StorageLocation.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import SwiftData

@Model
final class StorageLocation {
    var id: UUID
    var name: String
    var type: StorageType
    var path: String
    var isEnabled: Bool
    var lastSyncedAt: Date?
    var syncStatus: SyncStatus
    
    init(
        name: String,
        type: StorageType,
        path: String,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.path = path
        self.isEnabled = isEnabled
        self.syncStatus = .idle
    }
}

enum StorageType: String, Codable {
    case local = "Local"
    case iCloudDrive = "iCloud Drive"
    case dropbox = "Dropbox"
    case googleDrive = "Google Drive"
    case externalDrive = "External Drive"
    case opticalDisc = "Optical Disc"
}

enum SyncStatus: String, Codable {
    case idle
    case syncing
    case synced
    case error
}
