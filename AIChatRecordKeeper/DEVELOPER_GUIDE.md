# AI Chat Record Keeper - Developer Guide

## Project Structure

This macOS application follows the **MVVM (Model-View-ViewModel)** architecture pattern with SwiftUI and SwiftData.

```
AIChatRecordKeeper/
├── Models/                      # Data models (SwiftData)
│   ├── ChatTranscript.swift    # Main transcript model
│   ├── HashPublication.swift   # Hash publication records
│   ├── ChainOfCustodyEntry.swift # Audit trail entries
│   └── StorageLocation.swift   # Storage configuration
│
├── ViewModels/                  # Business logic layer
│   └── TranscriptViewModel.swift # Main view model
│
├── Views/                       # SwiftUI views
│   ├── TranscriptListView.swift      # List of transcripts
│   ├── TranscriptDetailView.swift    # Transcript details & actions
│   ├── ImportTranscriptView.swift    # Import dialog
│   ├── PublishHashView.swift         # Hash publication dialog
│   └── ChainOfCustodyView.swift      # Audit trail viewer
│
├── Services/                    # Service layer
│   ├── CryptographyService.swift     # SHA-256 hashing
│   ├── StorageService.swift          # File operations
│   ├── PublicationService.swift      # Hash publishing
│   └── ChainOfCustodyService.swift   # Audit logging
│
├── ContentView.swift            # Main app view
└── AIChatRecordKeeperApp.swift  # App entry point
```

## Architecture Overview

### MVVM Pattern

**Models** (`@Model` classes with SwiftData)
- Define the data structure
- Persist to CoreData via SwiftData
- No business logic

**ViewModels** (`@Observable` classes)
- Coordinate between Views and Services
- Handle user actions
- Manage loading states and errors
- Update UI through observation

**Views** (SwiftUI)
- Display data from ViewModels
- Capture user input
- No direct service calls
- Reactive to ViewModel changes

**Services** (Singletons)
- Encapsulate specific functionality
- Stateless operations
- Reusable across the app

## Core Features Implementation

### 1. Transcript Import & Export

**Flow:**
1. User imports transcript via `ImportTranscriptView`
2. `TranscriptViewModel.importTranscript()` processes the import
3. `StorageService` saves file to disk
4. `CryptographyService` computes SHA-256 hash
5. `ChainOfCustodyService` logs the import action
6. SwiftData persists the `ChatTranscript` model

**Key Classes:**
- `TranscriptViewModel` - Coordinates the import
- `StorageService.saveTranscript()` - File I/O
- `CryptographyService.sha256Hash()` - Hashing

### 2. Cryptographic Hashing

**Implementation:**
- Uses CryptoKit's SHA256
- Hash computed immediately after file save
- Stored with transcript for future verification
- Logged in chain of custody

**Key Classes:**
- `CryptographyService` - Hash computation and verification
- `sha256Hash(from:)` - Multiple overloads for Data, String, and File URL

### 3. Hash Publication

**Supported Services:**
- **GitHub Gist** - Public, timestamped Git commits
- **OpenTimestamps** - Bitcoin blockchain timestamping
- **Custom Webhook** - POST to any HTTP endpoint

**Flow:**
1. User selects publication service in `PublishHashView`
2. Enters credentials (GitHub token, webhook URL, etc.)
3. `TranscriptViewModel.publishHash()` calls service
4. `PublicationService` makes HTTP request
5. `HashPublication` record created and linked to transcript
6. Chain of custody entry logged

**Key Classes:**
- `PublicationService` - HTTP API calls
- `HashPublication` model - Publication records
- `PublishHashView` - UI for service selection

### 4. Storage & Backup

**Storage Layers:**
1. **Local** - Documents/AIChatTranscripts/
2. **iCloud Drive** - Automatic sync if enabled
3. **External** - Manual backup to drives/optical media

**Flow:**
1. Primary save to local storage
2. Optional iCloud backup via `backupToICloud()`
3. Hash verified after each save
4. All locations tracked in transcript model

**Key Classes:**
- `StorageService` - File operations
- `getAppDirectory()` - Local storage path
- `getICloudDirectory()` - iCloud container
- `backupFile()` - Copy to multiple destinations

### 5. Chain of Custody

**Audit Trail:**
- Every action logged as `ChainOfCustodyEntry`
- Includes: timestamp, action type, file hash, location
- Immutable record (SwiftData persistence)
- Exportable as text report

**Actions Tracked:**
- Imported, Exported, Hashed, Published, Backed Up, Verified, Modified

**Flow:**
1. Action performed (import, publish, etc.)
2. `ChainOfCustodyService.logEntry()` creates entry
3. Entry linked to transcript by UUID
4. Displayed in timeline view
5. Report generation for third-party verification

**Key Classes:**
- `ChainOfCustodyService` - Logging and reporting
- `ChainOfCustodyEntry` model - Audit records
- `ChainOfCustodyView` - Timeline visualization

### 6. Verification

**Integrity Check:**
1. User triggers verification
2. File hash recomputed from disk
3. Compared to stored hash
4. Result logged in chain of custody
5. UI displays verification status

**Implementation:**
```swift
let currentHash = try CryptographyService.shared.sha256Hash(ofFileAt: fileURL)
let isValid = currentHash == transcript.fileHash
```

**Key Classes:**
- `ChainOfCustodyService.verifyIntegrity()` - Verification logic
- `VerificationResult` - Result structure

## Data Flow Examples

### Import Transcript Flow

```
User Input (ImportTranscriptView)
    ↓
TranscriptViewModel.importTranscript()
    ↓
StorageService.saveTranscript() → File saved
    ↓
CryptographyService.sha256Hash() → Hash computed
    ↓
ChainOfCustodyService.logEntry() → Action logged
    ↓
ModelContext.insert() → SwiftData persists
    ↓
UI updates (via @Observable)
```

### Publish Hash Flow

```
User selects service (PublishHashView)
    ↓
TranscriptViewModel.publishHash()
    ↓
PublicationService.publishToGitHubGist() → HTTP POST
    ↓
GitHub API responds with gist URL
    ↓
HashPublication created and linked
    ↓
ChainOfCustodyService.logEntry()
    ↓
ModelContext.save() → Persisted
    ↓
UI updates
```

## Key Design Decisions

### 1. SwiftData for Persistence
- Modern, type-safe CoreData wrapper
- Declarative with `@Model` macro
- Automatic relationship management
- Query with `@Query` property wrapper

### 2. Service Layer Pattern
- Separates business logic from UI
- Services are stateless singletons
- Easy to test and mock
- Reusable across ViewModels

### 3. Observable ViewModels
- New Swift 5.9+ `@Observable` macro
- Fine-grained change tracking
- Better performance than `@ObservableObject`
- Cleaner syntax with `@Bindable`

### 4. Async/Await for Services
- Network calls are async
- File I/O can be async for large files
- UI remains responsive
- Error handling with throws

### 5. UUID for Relationships
- Transcripts have UUID primary key
- Chain of custody entries reference transcript by UUID
- Hash publications linked by UUID
- Allows for independent queries

## Security Considerations

### Hash Integrity
- SHA-256 is cryptographically secure
- Hash stored separately from content
- Published independently to prevent tampering
- Verification detects any modification

### Credential Storage
- GitHub tokens entered per-session (not persisted)
- Future: Use Keychain for secure storage
- Webhook URLs validated before use

### File Access
- App sandbox on macOS
- User grants access via file picker
- iCloud requires user consent

## Testing Strategy

### Unit Tests
- Test each service independently
- Mock file system for `StorageService`
- Verify hash computation with known inputs
- Test chain of custody logging

### Integration Tests
- Test ViewModel + Services
- Use in-memory SwiftData container
- Verify complete import/export flows

### UI Tests
- Test user workflows
- Import → Verify → Publish → Export
- Accessibility compliance

## Future Enhancements

1. **Email Integration**
   - Compose email with hash in default mail client
   - SMTP direct send (optional)

2. **Blockchain Verification**
   - Bitcoin OP_RETURN direct integration
   - Ethereum smart contract timestamping

3. **PDF Generation**
   - Proper PDF export with PDFKit
   - Embed metadata and hash

4. **Diff Viewer**
   - Compare transcript versions
   - Highlight changes if tampering detected

5. **Batch Operations**
   - Import multiple transcripts
   - Bulk publish to services
   - Scheduled backups

6. **Cloud Sync**
   - Full iCloud sync of database
   - Conflict resolution

7. **Search & Filter**
   - Full-text search across transcripts
   - Filter by platform, date, hash status

## Building & Running

### Requirements
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+

### Build
```bash
cd AIChatRecordKeeper
xcodebuild -scheme AIChatRecordKeeper -configuration Debug
```

### Run
Open `AIChatRecordKeeper.xcodeproj` in Xcode and press Cmd+R

## Contributing

This project is focused on user sovereignty over AI interaction records. Contributions that enhance:
- Verification mechanisms
- Decentralization
- User control
- Privacy & security

...are welcome.

## License

[To be determined]
