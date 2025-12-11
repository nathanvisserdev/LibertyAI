//
//  TranscriptDetailView.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct TranscriptDetailView: View {
    @Bindable var viewModel: TranscriptViewModel
    let transcript: ChatTranscript
    
    @State private var showingPublishSheet = false
    @State private var showingChainOfCustody = false
    @State private var verificationResult: VerificationResult?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(transcript.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label(transcript.sourcePlatform, systemImage: "bubble.left.and.bubble.right")
                        
                        if let url = transcript.sourceURL {
                            Divider()
                                .frame(height: 12)
                            Link(destination: URL(string: url)!) {
                                Label("Source", systemImage: "link")
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Hash Information
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("File Hash (SHA-256)", systemImage: "number")
                            .font(.headline)
                        
                        Text(transcript.fileHash)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                        
                        HStack {
                            Text("Created: \(transcript.createdAt, style: .date)")
                            Spacer()
                            Text("Imported: \(transcript.importedAt, style: .date)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                // Actions
                GroupBox("Actions") {
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                verificationResult = await viewModel.verifyTranscript(transcript)
                            }
                        } label: {
                            Label("Verify Integrity", systemImage: "checkmark.shield")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await viewModel.backupToICloud(transcript)
                                }
                            } label: {
                                Label("Backup to iCloud", systemImage: "icloud.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                showingPublishSheet = true
                            } label: {
                                Label("Publish Hash", systemImage: "network")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button {
                            showingChainOfCustody = true
                        } label: {
                            Label("View Chain of Custody", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Verification Result
                if let result = verificationResult {
                    GroupBox {
                        HStack {
                            Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(result.isValid ? .green : .red)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(result.statusMessage)
                                    .font(.headline)
                                Text("Verified at \(result.verifiedAt, style: .time)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Publications
                if !transcript.hashPublications.isEmpty {
                    GroupBox("Hash Publications") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(transcript.hashPublications) { publication in
                                PublicationRowView(publication: publication)
                                
                                if publication.id != transcript.hashPublications.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                
                // Storage Locations
                GroupBox("Storage Locations") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let localPath = transcript.localFilePath {
                            StorageLocationRow(
                                icon: "folder",
                                title: "Local Storage",
                                path: localPath,
                                color: .blue
                            )
                        }
                        
                        if let cloudPath = transcript.cloudStoragePath {
                            StorageLocationRow(
                                icon: "icloud",
                                title: "iCloud Drive",
                                path: cloudPath,
                                color: .cyan
                            )
                        }
                        
                        if let offlinePath = transcript.offlineBackupPath {
                            StorageLocationRow(
                                icon: "externaldrive",
                                title: "Offline Backup",
                                path: offlinePath,
                                color: .green
                            )
                        }
                    }
                }
                
                // Content Preview
                GroupBox("Content Preview") {
                    ScrollView {
                        Text(transcript.content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                }
            }
            .padding()
        }
        .navigationTitle("Transcript Details")
        .sheet(isPresented: $showingPublishSheet) {
            PublishHashView(viewModel: viewModel, transcript: transcript, isPresented: $showingPublishSheet)
        }
        .sheet(isPresented: $showingChainOfCustody) {
            ChainOfCustodyView(transcript: transcript)
        }
    }
}

struct PublicationRowView: View {
    let publication: HashPublication
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(publication.service.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Published \(publication.publishedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let url = publication.publicURL {
                    Link(destination: URL(string: url)!) {
                        Text(url)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Text(publication.confirmationStatus.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(4)
        }
    }
    
    private var statusIcon: String {
        switch publication.confirmationStatus {
        case .pending:
            return "clock"
        case .confirmed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch publication.confirmationStatus {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .failed:
            return .red
        }
    }
}

struct StorageLocationRow: View {
    let icon: String
    let title: String
    let path: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            #if os(macOS)
            Button {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
            } label: {
                Image(systemName: "arrow.right.circle")
            }
            .buttonStyle(.plain)
            #else
            Button {
                // iOS: Show share sheet for the file
                if let url = URL(string: "file://" + path) {
                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            #endif
        }
        .padding(.vertical, 4)
    }
}
