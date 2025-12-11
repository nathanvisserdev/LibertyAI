//
//  TranscriptListView.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI

struct TranscriptListView: View {
    @Bindable var viewModel: TranscriptViewModel
    @State private var showingImportSheet = false
    
    var body: some View {
        List(selection: $viewModel.selectedTranscript) {
            ForEach(viewModel.transcripts) { transcript in
                TranscriptRowView(transcript: transcript)
                    .tag(transcript)
            }
            .onDelete(perform: deleteTranscripts)
        }
        .navigationTitle("AI Chat Transcripts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingImportSheet = true
                } label: {
                    Label("Import Transcript", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    viewModel.loadTranscripts()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportTranscriptView(viewModel: viewModel, isPresented: $showingImportSheet)
        }
    }
    
    private func deleteTranscripts(at offsets: IndexSet) {
        for index in offsets {
            let transcript = viewModel.transcripts[index]
            viewModel.deleteTranscript(transcript)
        }
    }
}

struct TranscriptRowView: View {
    let transcript: ChatTranscript
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transcript.title)
                .font(.headline)
            
            HStack {
                Text(transcript.sourcePlatform)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(platformColor.opacity(0.2))
                    .foregroundColor(platformColor)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(transcript.importedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !transcript.hashPublications.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("\(transcript.hashPublications.count) publication(s)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var platformColor: Color {
        switch transcript.sourcePlatform.lowercased() {
        case "chatgpt":
            return .green
        case "claude":
            return .orange
        case "gemini":
            return .blue
        default:
            return .gray
        }
    }
}
