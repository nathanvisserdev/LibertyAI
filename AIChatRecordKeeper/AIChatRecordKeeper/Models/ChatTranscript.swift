//
//  ChatTranscript.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import SwiftData

@Model
final class ChatTranscript {
    var id: UUID
    var title: String
    var content: String
    var sourceURL: String?
    var sourcePlatform: String // ChatGPT, Claude, etc.
    var createdAt: Date
    var importedAt: Date
    var fileHash: String // SHA-256 hash
    var exportFormat: ExportFormat
    var localFilePath: String?
    var cloudStoragePath: String?
    var offlineBackupPath: String?
    var hashPublications: [HashPublication]
    var chainOfCustodyEntries: [ChainOfCustodyEntry]
    
    init(
        title: String,
        content: String,
        sourceURL: String? = nil,
        sourcePlatform: String,
        exportFormat: ExportFormat = .plaintext
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.sourceURL = sourceURL
        self.sourcePlatform = sourcePlatform
        self.createdAt = Date()
        self.importedAt = Date()
        self.fileHash = ""
        self.exportFormat = exportFormat
        self.hashPublications = []
        self.chainOfCustodyEntries = []
    }
}

enum ExportFormat: String, Codable {
    case plaintext
    case pdf
    case markdown
}
