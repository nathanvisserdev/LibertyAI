//
//  StorageService.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation

class StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    private let fileManager = FileManager.default
    
    // MARK: - Directory Management
    
    /// Gets the main app directory for storing transcripts
    func getAppDirectory() throws -> URL {
        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = documentsDirectory.appendingPathComponent("AIChatTranscripts", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }
        
        return appDirectory
    }
    
    /// Gets the iCloud Drive directory if available
    func getICloudDirectory() -> URL? {
        guard let ubiquityURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }
        let iCloudDirectory = ubiquityURL.appendingPathComponent("Documents/AIChatTranscripts", isDirectory: true)
        
        if !fileManager.fileExists(atPath: iCloudDirectory.path) {
            try? fileManager.createDirectory(at: iCloudDirectory, withIntermediateDirectories: true)
        }
        
        return iCloudDirectory
    }
    
    // MARK: - File Operations
    
    /// Saves transcript content to a file
    func saveTranscript(_ transcript: ChatTranscript, to directory: URL, format: ExportFormat) throws -> URL {
        let fileName = sanitizeFileName(transcript.title)
        let fileExtension = fileExtension(for: format)
        let fileURL = directory.appendingPathComponent("\(fileName)_\(transcript.id.uuidString).\(fileExtension)")
        
        let content = formatContent(transcript.content, as: format)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    /// Saves transcript as PDF
    func saveTranscriptAsPDF(_ transcript: ChatTranscript, to directory: URL) throws -> URL {
        let fileName = sanitizeFileName(transcript.title)
        let fileURL = directory.appendingPathComponent("\(fileName)_\(transcript.id.uuidString).pdf")
        
        // PDF generation would go here - for now, saving as text
        // In production, use PDFKit or similar
        try transcript.content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    /// Copies file to multiple backup locations
    func backupFile(from sourceURL: URL, to destinations: [StorageLocation]) throws -> [URL] {
        var copiedURLs: [URL] = []
        
        for destination in destinations where destination.isEnabled {
            let destinationURL = URL(fileURLWithPath: destination.path)
                .appendingPathComponent(sourceURL.lastPathComponent)
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            copiedURLs.append(destinationURL)
        }
        
        return copiedURLs
    }
    
    /// Verifies a file exists at the given path
    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    /// Deletes a file
    func deleteFile(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    // MARK: - Helper Methods
    
    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    private func fileExtension(for format: ExportFormat) -> String {
        switch format {
        case .plaintext:
            return "txt"
        case .pdf:
            return "pdf"
        case .markdown:
            return "md"
        }
    }
    
    private func formatContent(_ content: String, as format: ExportFormat) -> String {
        switch format {
        case .plaintext, .markdown:
            return content
        case .pdf:
            return content // PDF formatting would be handled in saveTranscriptAsPDF
        }
    }
}
