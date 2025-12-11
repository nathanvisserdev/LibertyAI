//
//  HashPublication.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import SwiftData

@Model
final class HashPublication {
    var id: UUID
    var transcriptID: UUID
    var service: PublicationService
    var publishedAt: Date
    var publicURL: String?
    var transactionID: String? // For blockchain services
    var confirmationStatus: ConfirmationStatus
    var errorMessage: String?
    
    init(
        transcriptID: UUID,
        service: PublicationService,
        publicURL: String? = nil,
        transactionID: String? = nil
    ) {
        self.id = UUID()
        self.transcriptID = transcriptID
        self.service = service
        self.publishedAt = Date()
        self.publicURL = publicURL
        self.transactionID = transactionID
        self.confirmationStatus = .pending
    }
}

enum PublicationService: String, Codable {
    case githubGist = "GitHub Gist"
    case email = "Email"
    case openTimestamps = "OpenTimestamps"
    case bitcoinOpReturn = "Bitcoin OP_RETURN"
    case customWebhook = "Custom Webhook"
}

enum ConfirmationStatus: String, Codable {
    case pending
    case confirmed
    case failed
}
