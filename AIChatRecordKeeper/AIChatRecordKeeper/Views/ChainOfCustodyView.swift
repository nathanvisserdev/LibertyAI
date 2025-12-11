//
//  ChainOfCustodyView.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

struct ChainOfCustodyView: View {
    let transcript: ChatTranscript
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var entries: [ChainOfCustodyEntry] = []
    @State private var reportText = ""
    @State private var showingReport = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(transcript.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Complete audit trail of all actions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                
                // Timeline
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            ChainOfCustodyEntryRow(
                                entry: entry,
                                isFirst: index == 0,
                                isLast: index == entries.count - 1
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Chain of Custody")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        generateReport()
                        showingReport = true
                    } label: {
                        Label("Generate Report", systemImage: "doc.text")
                    }
                }
            }
            .sheet(isPresented: $showingReport) {
                ReportView(reportText: reportText)
            }
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
        .onAppear {
            loadEntries()
        }
    }
    
    private func loadEntries() {
        entries = ChainOfCustodyService.shared.getEntries(
            for: transcript.id,
            modelContext: modelContext
        )
    }
    
    private func generateReport() {
        reportText = ChainOfCustodyService.shared.generateReport(
            for: transcript.id,
            transcript: transcript,
            modelContext: modelContext
        )
    }
}

struct ChainOfCustodyEntryRow: View {
    let entry: ChainOfCustodyEntry
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                ZStack {
                    Circle()
                        .fill(actionColor)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: actionIcon)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.action.rawValue)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(entry.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(entry.details)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                if let location = entry.storageLocation {
                    Label(location, systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // Hash
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(entry.fileHash)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Verification Status
                HStack {
                    Image(systemName: verificationIcon)
                        .foregroundColor(verificationColor)
                    
                    Text(entry.verificationStatus.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(verificationColor)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var actionColor: Color {
        switch entry.action {
        case .imported:
            return .blue
        case .exported:
            return .green
        case .hashed:
            return .purple
        case .published:
            return .orange
        case .backedUp:
            return .cyan
        case .verified:
            return .green
        case .modified:
            return .red
        }
    }
    
    private var actionIcon: String {
        switch entry.action {
        case .imported:
            return "arrow.down.circle"
        case .exported:
            return "arrow.up.circle"
        case .hashed:
            return "number"
        case .published:
            return "network"
        case .backedUp:
            return "externaldrive"
        case .verified:
            return "checkmark"
        case .modified:
            return "exclamationmark"
        }
    }
    
    private var verificationIcon: String {
        switch entry.verificationStatus {
        case .verified:
            return "checkmark.shield.fill"
        case .unverified:
            return "questionmark.shield"
        case .tampered:
            return "xmark.shield.fill"
        }
    }
    
    private var verificationColor: Color {
        switch entry.verificationStatus {
        case .verified:
            return .green
        case .unverified:
            return .orange
        case .tampered:
            return .red
        }
    }
}

struct ReportView: View {
    let reportText: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(reportText)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("Chain of Custody Report")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        saveReport()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
    }
    
    private func saveReport() {
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.plainText]
        savePanel.nameFieldStringValue = "chain_of_custody_report.txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? reportText.write(to: url, atomically: true, encoding: .utf8)
            }
        }
        #else
        // iOS: Use share sheet
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("chain_of_custody_report.txt")
        try? reportText.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
}
