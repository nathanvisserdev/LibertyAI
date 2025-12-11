//
//  TranscriptViewModel.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class TranscriptViewModel {
    private var modelContext: ModelContext
    
    var transcripts: [ChatTranscript] = []
    var selectedTranscript: ChatTranscript?
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTranscripts()
    }
    
    // MARK: - Data Loading
    
    func loadTranscripts() {
        let descriptor = FetchDescriptor<ChatTranscript>(
            sortBy: [SortDescriptor(\.importedAt, order: .reverse)]
        )
        
        do {
            transcripts = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load transcripts: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Import Transcript
    
    func importTranscript(
        title: String,
        content: String,
        sourceURL: String?,
        sourcePlatform: String,
        exportFormat: ExportFormat = .plaintext
    ) async {
        await MainActor.run { isLoading = true }
        
        do {
            // Create transcript
            let transcript = ChatTranscript(
                title: title,
                content: content,
                sourceURL: sourceURL,
                sourcePlatform: sourcePlatform,
                exportFormat: exportFormat
            )
            
            // Save to local storage
            let appDirectory = try StorageService.shared.getAppDirectory()
            let fileURL = try StorageService.shared.saveTranscript(
                transcript,
                to: appDirectory,
                format: exportFormat
            )
            
            transcript.localFilePath = fileURL.path
            
            // Compute hash
            let hash = try CryptographyService.shared.sha256Hash(ofFileAt: fileURL)
            transcript.fileHash = hash
            
            // Log chain of custody
            ChainOfCustodyService.shared.logEntry(
                transcriptID: transcript.id,
                action: .imported,
                details: "Transcript imported from \(sourcePlatform)",
                fileHash: hash,
                storageLocation: fileURL.path,
                modelContext: modelContext
            )
            
            ChainOfCustodyService.shared.logEntry(
                transcriptID: transcript.id,
                action: .hashed,
                details: "SHA-256 hash computed",
                fileHash: hash,
                modelContext: modelContext
            )
            
            // Save to database
            modelContext.insert(transcript)
            try modelContext.save()
            
            // Reload transcripts
            await MainActor.run {
                loadTranscripts()
                selectedTranscript = transcript
                successMessage = "Transcript imported successfully"
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to import transcript: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Export & Backup
    
    func exportTranscript(_ transcript: ChatTranscript, to url: URL) async {
        await MainActor.run { isLoading = true }
        
        do {
            let fileURL = try StorageService.shared.saveTranscript(
                transcript,
                to: url.deletingLastPathComponent(),
                format: transcript.exportFormat
            )
            
            ChainOfCustodyService.shared.logEntry(
                transcriptID: transcript.id,
                action: .exported,
                details: "Exported to \(url.path)",
                fileHash: transcript.fileHash,
                storageLocation: url.path,
                modelContext: modelContext
            )
            
            await MainActor.run {
                successMessage = "Transcript exported successfully"
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to export transcript: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func backupToICloud(_ transcript: ChatTranscript) async {
        await MainActor.run { isLoading = true }
        
        do {
            guard let iCloudDirectory = StorageService.shared.getICloudDirectory() else {
                await MainActor.run {
                    errorMessage = "iCloud Drive is not available"
                    isLoading = false
                }
                return
            }
            
            let fileURL = try StorageService.shared.saveTranscript(
                transcript,
                to: iCloudDirectory,
                format: transcript.exportFormat
            )
            
            transcript.cloudStoragePath = fileURL.path
            
            ChainOfCustodyService.shared.logEntry(
                transcriptID: transcript.id,
                action: .backedUp,
                details: "Backed up to iCloud Drive",
                fileHash: transcript.fileHash,
                storageLocation: fileURL.path,
                modelContext: modelContext
            )
            
            try modelContext.save()
            
            await MainActor.run {
                successMessage = "Backed up to iCloud successfully"
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to backup to iCloud: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Hash Publishing
    
    func publishHash(
        _ transcript: ChatTranscript,
        to service: PublicationService,
        credentials: PublicationCredentials
    ) async {
        await MainActor.run { isLoading = true }
        
        do {
            var publication: HashPublication?
            
            switch credentials {
            case .github(let token):
                publication = try await service.publishToGitHubGist(
                    hash: transcript.fileHash,
                    transcriptTitle: transcript.title,
                    token: token
                )
                
            case .openTimestamps:
                publication = try await service.publishToOpenTimestamps(
                    hash: transcript.fileHash
                )
                
            case .webhook(let url):
                publication = try await service.publishToWebhook(
                    hash: transcript.fileHash,
                    transcriptTitle: transcript.title,
                    webhookURL: url
                )
            }
            
            if var pub = publication {
                pub.transcriptID = transcript.id
                transcript.hashPublications.append(pub)
                
                ChainOfCustodyService.shared.logEntry(
                    transcriptID: transcript.id,
                    action: .published,
                    details: "Hash published to \(pub.service.rawValue)",
                    fileHash: transcript.fileHash,
                    storageLocation: pub.publicURL,
                    modelContext: modelContext
                )
                
                try modelContext.save()
            }
            
            await MainActor.run {
                successMessage = "Hash published successfully"
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to publish hash: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Verification
    
    func verifyTranscript(_ transcript: ChatTranscript) async -> VerificationResult? {
        await MainActor.run { isLoading = true }
        
        guard let filePath = transcript.localFilePath else {
            await MainActor.run {
                errorMessage = "File path not found"
                isLoading = false
            }
            return nil
        }
        
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            let result = try ChainOfCustodyService.shared.verifyIntegrity(
                transcript: transcript,
                fileURL: fileURL,
                modelContext: modelContext
            )
            
            await MainActor.run {
                if result.isValid {
                    successMessage = "✓ File integrity verified"
                } else {
                    errorMessage = "⚠ WARNING: File has been modified"
                }
                isLoading = false
            }
            
            return result
            
        } catch {
            await MainActor.run {
                errorMessage = "Verification failed: \(error.localizedDescription)"
                isLoading = false
            }
            return nil
        }
    }
    
    // MARK: - Delete
    
    func deleteTranscript(_ transcript: ChatTranscript) {
        modelContext.delete(transcript)
        try? modelContext.save()
        loadTranscripts()
    }
    
    // MARK: - Clear Messages
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Supporting Types

enum PublicationCredentials {
    case github(token: String)
    case openTimestamps
    case webhook(url: String)
}
