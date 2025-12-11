# AI Chat Record Keeper

## Purpose

**AI Chat Record Keeper** is a macOS application designed to preserve AI chat transcripts in a verifiable, tamper-evident format that cannot be silently altered and can be validated by independent third parties.

As AI assistants become increasingly integrated into professional and personal workflows, maintaining an authentic record of interactions is critical for accountability, reference, and dispute resolution. This tool addresses the fundamental problem that platform-hosted chat histories can be modified, deleted, or lost without your knowledge.

## The Problem

When you rely solely on AI platforms to store your conversation history:

- Chat transcripts can be altered or deleted by the platform
- You have no proof of what was originally said or when
- There's no independent verification mechanism
- Platform outages or policy changes can result in permanent data loss

## The Solution

This application implements a **multi-layered preservation strategy** combining:

1. **Regular Export** – Save transcripts locally as PDFs or plaintext files
2. **Cryptographic Timestamping** – Generate SHA-256 hashes to prove file integrity
3. **Independent Publication** – Publish hashes to third-party services you don't control
4. **Immutable Storage** – Store in write-once or versioned storage systems
5. **Redundant Backups** – Maintain multiple independent copies
6. **Chain of Custody** – Document the complete preservation process

## How It Works

### 1. Export Chat Transcripts
- Import conversations from AI platforms (ChatGPT, Claude, etc.)
- Save as PDF or plaintext files with standardized naming
- Never rely solely on platform retention

### 2. Cryptographic Timestamping
Each saved transcript is immediately processed:
- **SHA-256 hash** is computed from the exact file contents
- This hash serves as a unique "fingerprint" of the conversation
- Any modification, no matter how small, completely changes the hash
- The hash is published to services you don't control:
  - GitHub Gists (public, timestamped commits)
  - Email to yourself (email headers prove transmission time)
  - Blockchain timestamping (OpenTimestamps, Bitcoin OP_RETURN)

This creates **immutable proof** that the file existed in that exact form at that specific time.

### 3. Immutable Storage
Transcripts are stored using multiple strategies:
- **Read-only external media** (write-once optical discs, hardware write-protected USB)
- **Cloud storage with versioning** (Dropbox, Google Drive, iCloud Drive)
- These independent storage layers prevent simultaneous alteration of all copies

### 4. Redundant Backups
The application maintains **at least three independent copies**:
- **Local**: Primary working copy on your Mac
- **Cloud**: Synced to versioned cloud storage
- **Offline**: Archived to external media or air-gapped storage

### 5. Chain of Custody Documentation
Every preservation action is logged:
```
Date/Time | Chat Source | Original URL | File Hash (SHA-256) | Storage Locations
```

This audit trail demonstrates the complete lifecycle of each transcript.

## Why This Approach Works

### Cryptographic Proof
- SHA-256 hashes are computationally infeasible to forge
- Publishing the hash independently creates a "notarization" timestamp
- Anyone can verify file integrity by recomputing the hash

### Defense Against Tampering
- **Local changes** are detected when the hash no longer matches
- **Platform alterations** are proven by your independently timestamped copy
- **Multiple storage locations** prevent simultaneous compromise
- **Immutable publishing** (blockchain, email headers, git history) can't be retroactively modified

### Independent Verification
A third party can validate your transcript by:
1. Obtaining your saved file
2. Computing its SHA-256 hash
3. Comparing to the independently published hash
4. Verifying the publication timestamp

If they match, the transcript is proven authentic to that point in time.

## Key Principles

This project is built on the principle that **you cannot trust a single point of control**:

- ❌ Platform-only storage → Platform can modify or delete
- ❌ Local-only storage → Single point of failure
- ❌ Hash without publication → No proof of when it existed
- ✅ **Multi-layered, cryptographically verified, independently published** → Robust and verifiable

## Use Cases

- **Professional Records**: Preserve AI-assisted work product and consultation
- **Research Documentation**: Maintain verifiable records of AI interactions for academic work
- **Legal Protection**: Create admissible evidence of AI conversations
- **Personal Archive**: Build a permanent, searchable library of your AI interactions
- **Accountability**: Prove what an AI actually said vs. how it might be remembered

## Getting Started

1. Launch **AI Chat Record Keeper**
2. Import or paste a chat transcript
3. The app automatically:
   - Saves the file locally
   - Computes the SHA-256 hash
   - Offers to publish the hash to your chosen services
   - Logs the preservation action
4. Review the chain of custody log to verify all steps

## Technical Stack

- **Platform**: macOS (SwiftUI)
- **Hashing**: SHA-256 (CommonCrypto / CryptoKit)
- **Storage**: Local filesystem + iCloud Drive integration
- **Export**: PDF and plaintext formats
- **Timestamping**: GitHub API, SMTP, OpenTimestamps integration

## Security Model

**Threat Model**: Platform alteration, retroactive modification, data loss, false claims about conversation content

**Defenses**:
- Cryptographic hashing prevents undetected modification
- Independent publication proves earlier existence
- Multiple storage locations prevent total loss
- Chain of custody enables forensic verification

**Trust Assumptions**:
- SHA-256 remains cryptographically secure
- At least one publication service remains honest/immutable
- You maintain physical control of offline backup media

## License

[To be determined]

## Contributing

This is a Liberty AI project focused on user sovereignty over AI interaction records. Contributions that enhance verification, decentralization, and user control are welcome.

---

**Remember**: The best time to preserve a transcript was immediately after the conversation. The second-best time is now. This application makes that process automatic, verifiable, and trustworthy.
