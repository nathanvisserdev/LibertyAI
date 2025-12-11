//
//  PublicationService.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation

class PublicationService {
    static let shared = PublicationService()
    
    private init() {}
    
    // MARK: - GitHub Gist Publication
    
    /// Publishes hash to GitHub Gist
    func publishToGitHubGist(
        hash: String,
        transcriptTitle: String,
        token: String
    ) async throws -> HashPublication {
        let gistContent = """
        # AI Chat Transcript Hash
        Title: \(transcriptTitle)
        SHA-256: \(hash)
        Timestamp: \(ISO8601DateFormatter().string(from: Date()))
        
        This hash cryptographically proves the existence and content of an AI chat transcript at this timestamp.
        """
        
        let gistData: [String: Any] = [
            "description": "AI Chat Transcript Hash - \(transcriptTitle)",
            "public": true,
            "files": [
                "transcript_hash.txt": [
                    "content": gistContent
                ]
            ]
        ]
        
        var request = URLRequest(url: URL(string: "https://api.github.com/gists")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: gistData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PublicationError.requestFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let gistURL = json?["html_url"] as? String
        
        let publication = HashPublication(
            transcriptID: UUID(), // Will be set by caller
            service: .githubGist,
            publicURL: gistURL
        )
        publication.confirmationStatus = .confirmed
        
        return publication
    }
    
    // MARK: - Email Publication
    
    /// Prepares an email with the hash information
    func prepareEmailPublication(
        hash: String,
        transcriptTitle: String,
        recipientEmail: String
    ) -> EmailPublicationData {
        let subject = "AI Chat Transcript Hash - \(transcriptTitle)"
        let body = """
        AI Chat Transcript Hash Verification
        
        Title: \(transcriptTitle)
        SHA-256 Hash: \(hash)
        Timestamp: \(ISO8601DateFormatter().string(from: Date()))
        
        This email serves as a timestamp proof for the AI chat transcript.
        The SHA-256 hash above cryptographically proves the content existed at this time.
        
        To verify: Compute the SHA-256 hash of your transcript file and compare to the hash above.
        """
        
        return EmailPublicationData(
            recipientEmail: recipientEmail,
            subject: subject,
            body: body,
            hash: hash
        )
    }
    
    // MARK: - OpenTimestamps
    
    /// Submits hash to OpenTimestamps service
    func publishToOpenTimestamps(hash: String) async throws -> HashPublication {
        // OpenTimestamps API implementation
        // This would integrate with opentimestamps.org
        
        let url = URL(string: "https://opentimestamps.org/api/v1/timestamp")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Convert hash to Data
        guard let hashData = Data(fromHexString: hash) else {
            throw PublicationError.invalidHash
        }
        
        request.httpBody = hashData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PublicationError.requestFailed
        }
        
        // Store the OTS proof file
        let otsProof = data.base64EncodedString()
        
        let publication = HashPublication(
            transcriptID: UUID(), // Will be set by caller
            service: .openTimestamps,
            transactionID: otsProof
        )
        publication.confirmationStatus = .pending // Will be confirmed once included in Bitcoin blockchain
        
        return publication
    }
    
    // MARK: - Custom Webhook
    
    /// Publishes hash to a custom webhook
    func publishToWebhook(
        hash: String,
        transcriptTitle: String,
        webhookURL: String
    ) async throws -> HashPublication {
        guard let url = URL(string: webhookURL) else {
            throw PublicationError.invalidURL
        }
        
        let payload: [String: Any] = [
            "title": transcriptTitle,
            "hash": hash,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "algorithm": "SHA-256"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PublicationError.requestFailed
        }
        
        let publication = HashPublication(
            transcriptID: UUID(), // Will be set by caller
            service: .customWebhook,
            publicURL: webhookURL
        )
        publication.confirmationStatus = .confirmed
        
        return publication
    }
}

// MARK: - Supporting Types

struct EmailPublicationData {
    let recipientEmail: String
    let subject: String
    let body: String
    let hash: String
}

enum PublicationError: LocalizedError {
    case requestFailed
    case invalidHash
    case invalidURL
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "Failed to publish hash to the service"
        case .invalidHash:
            return "Invalid hash format"
        case .invalidURL:
            return "Invalid URL provided"
        case .unauthorized:
            return "Unauthorized - check your credentials"
        }
    }
}

// MARK: - Data Extension

extension Data {
    init?(fromHexString string: String) {
        let len = string.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = string.index(string.startIndex, offsetBy: i*2)
            let k = string.index(j, offsetBy: 2)
            let bytes = string[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
