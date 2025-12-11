//
//  ChainOfCustodyService.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import SwiftData

class ChainOfCustodyService {
    static let shared = ChainOfCustodyService()
    
    private init() {}
    
    /// Logs a chain of custody entry
    func logEntry(
        transcriptID: UUID,
        action: CustodyAction,
        details: String,
        fileHash: String,
        storageLocation: String? = nil,
        modelContext: ModelContext
    ) {
        let entry = ChainOfCustodyEntry(
            transcriptID: transcriptID,
            action: action,
            details: details,
            fileHash: fileHash,
            storageLocation: storageLocation
        )
        
        modelContext.insert(entry)
        try? modelContext.save()
    }
    
    /// Retrieves all entries for a specific transcript
    func getEntries(
        for transcriptID: UUID,
        modelContext: ModelContext
    ) -> [ChainOfCustodyEntry] {
        let descriptor = FetchDescriptor<ChainOfCustodyEntry>(
            predicate: #Predicate { $0.transcriptID == transcriptID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Generates a chain of custody report for a transcript
    func generateReport(
        for transcriptID: UUID,
        transcript: ChatTranscript,
        modelContext: ModelContext
    ) -> String {
        let entries = getEntries(for: transcriptID, modelContext: modelContext)
        
        var report = """
        ═══════════════════════════════════════════════════════════
        CHAIN OF CUSTODY REPORT
        ═══════════════════════════════════════════════════════════
        
        Transcript: \(transcript.title)
        Transcript ID: \(transcript.id.uuidString)
        Platform: \(transcript.sourcePlatform)
        Created: \(formatDate(transcript.createdAt))
        Current Hash: \(transcript.fileHash)
        
        ───────────────────────────────────────────────────────────
        CUSTODY HISTORY
        ───────────────────────────────────────────────────────────
        
        """
        
        for (index, entry) in entries.enumerated() {
            report += """
            
            [\(index + 1)] \(entry.action.rawValue)
            Timestamp: \(formatDate(entry.timestamp))
            Hash: \(entry.fileHash)
            Status: \(entry.verificationStatus.rawValue)
            Details: \(entry.details)
            """
            
            if let location = entry.storageLocation {
                report += "\nLocation: \(location)"
            }
            
            report += "\n"
        }
        
        report += """
        
        ───────────────────────────────────────────────────────────
        HASH PUBLICATIONS
        ───────────────────────────────────────────────────────────
        
        """
        
        for (index, publication) in transcript.hashPublications.enumerated() {
            report += """
            
            [\(index + 1)] \(publication.service.rawValue)
            Published: \(formatDate(publication.publishedAt))
            Status: \(publication.confirmationStatus.rawValue)
            """
            
            if let url = publication.publicURL {
                report += "\nURL: \(url)"
            }
            
            if let txID = publication.transactionID {
                report += "\nTransaction ID: \(txID)"
            }
            
            report += "\n"
        }
        
        report += """
        
        ═══════════════════════════════════════════════════════════
        END OF REPORT
        Generated: \(formatDate(Date()))
        ═══════════════════════════════════════════════════════════
        """
        
        return report
    }
    
    /// Verifies the integrity of a transcript
    func verifyIntegrity(
        transcript: ChatTranscript,
        fileURL: URL,
        modelContext: ModelContext
    ) throws -> VerificationResult {
        let currentHash = try CryptographyService.shared.sha256Hash(ofFileAt: fileURL)
        let storedHash = transcript.fileHash
        
        let isValid = CryptographyService.shared.verifyHash(currentHash, matches: storedHash)
        
        let action: CustodyAction = isValid ? .verified : .modified
        let details = isValid
            ? "File integrity verified - hash matches"
            : "ALERT: File integrity compromised - hash mismatch"
        
        logEntry(
            transcriptID: transcript.id,
            action: action,
            details: details,
            fileHash: currentHash,
            storageLocation: fileURL.path,
            modelContext: modelContext
        )
        
        return VerificationResult(
            isValid: isValid,
            storedHash: storedHash,
            computedHash: currentHash,
            verifiedAt: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct VerificationResult {
    let isValid: Bool
    let storedHash: String
    let computedHash: String
    let verifiedAt: Date
    
    var statusMessage: String {
        if isValid {
            return "✓ File integrity verified"
        } else {
            return "⚠ WARNING: File has been modified or corrupted"
        }
    }
}
