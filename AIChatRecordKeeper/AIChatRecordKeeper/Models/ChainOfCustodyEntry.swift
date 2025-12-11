//
//  ChainOfCustodyEntry.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import SwiftData

@Model
final class ChainOfCustodyEntry {
    var id: UUID
    var transcriptID: UUID
    var timestamp: Date
    var action: CustodyAction
    var details: String
    var fileHash: String
    var storageLocation: String?
    var verificationStatus: VerificationStatus
    
    init(
        transcriptID: UUID,
        action: CustodyAction,
        details: String,
        fileHash: String,
        storageLocation: String? = nil
    ) {
        self.id = UUID()
        self.transcriptID = transcriptID
        self.timestamp = Date()
        self.action = action
        self.details = details
        self.fileHash = fileHash
        self.storageLocation = storageLocation
        self.verificationStatus = .verified
    }
}

enum CustodyAction: String, Codable {
    case imported = "Imported"
    case exported = "Exported"
    case hashed = "Hashed"
    case published = "Published"
    case backedUp = "Backed Up"
    case verified = "Verified"
    case modified = "Modified"
}

enum VerificationStatus: String, Codable {
    case verified
    case unverified
    case tampered
}
