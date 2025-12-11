//
//  ContentView.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TranscriptViewModel?
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                MainView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TranscriptViewModel(modelContext: modelContext)
            }
        }
    }
}

struct MainView: View {
    @Bindable var viewModel: TranscriptViewModel
    
    var body: some View {
        NavigationSplitView {
            TranscriptListView(viewModel: viewModel)
        } detail: {
            if let transcript = viewModel.selectedTranscript {
                TranscriptDetailView(viewModel: viewModel, transcript: transcript)
            } else {
                EmptyStateView()
            }
        }
        #if os(macOS)
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        #endif
        .overlay(alignment: .top) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.top, 20)
            }
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.clearMessages()
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearMessages()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Transcript Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select a transcript from the list or import a new one")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "lock.shield",
                    title: "Cryptographic Verification",
                    description: "SHA-256 hashing ensures tamper detection"
                )
                
                FeatureRow(
                    icon: "network",
                    title: "Independent Publication",
                    description: "Publish to GitHub, blockchain, or custom services"
                )
                
                FeatureRow(
                    icon: "externaldrive.badge.checkmark",
                    title: "Redundant Backups",
                    description: "Local, cloud, and offline storage options"
                )
                
                FeatureRow(
                    icon: "doc.text.magnifyingglass",
                    title: "Chain of Custody",
                    description: "Complete audit trail of all actions"
                )
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .frame(maxWidth: 500)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ChatTranscript.self, HashPublication.self, ChainOfCustodyEntry.self, StorageLocation.self], inMemory: true)
}
