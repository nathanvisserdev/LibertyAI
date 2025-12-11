//
//  CryptographyService.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import CryptoKit

class CryptographyService {
    static let shared = CryptographyService()
    
    private init() {}
    
    /// Computes SHA-256 hash of the given data
    func sha256Hash(from data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Computes SHA-256 hash of the given string
    func sha256Hash(from string: String) -> String {
        guard let data = string.data(using: .utf8) else {
            return ""
        }
        return sha256Hash(from: data)
    }
    
    /// Computes SHA-256 hash of a file at the given URL
    func sha256Hash(ofFileAt url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return sha256Hash(from: data)
    }
    
    /// Verifies if the computed hash matches the expected hash
    func verifyHash(_ computedHash: String, matches expectedHash: String) -> Bool {
        return computedHash.lowercased() == expectedHash.lowercased()
    }
    
    /// Verifies the integrity of a file against its stored hash
    func verifyFileIntegrity(fileURL: URL, expectedHash: String) throws -> Bool {
        let computedHash = try sha256Hash(ofFileAt: fileURL)
        return verifyHash(computedHash, matches: expectedHash)
    }
}
