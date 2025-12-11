//
//  ImportTranscriptView.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI

struct ImportTranscriptView: View {
    @Bindable var viewModel: TranscriptViewModel
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var content = ""
    @State private var sourceURL = ""
    @State private var sourcePlatform = "ChatGPT"
    @State private var exportFormat: ExportFormat = .plaintext
    
    let platforms = ["ChatGPT", "Claude", "Gemini", "Copilot", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transcript Information") {
                    TextField("Title", text: $title)
                    
                    Picker("Source Platform", selection: $sourcePlatform) {
                        ForEach(platforms, id: \.self) { platform in
                            Text(platform).tag(platform)
                        }
                    }
                    
                    TextField("Source URL (optional)", text: $sourceURL)
                        .textContentType(.URL)
                    
                    Picker("Export Format", selection: $exportFormat) {
                        Text("Plain Text").tag(ExportFormat.plaintext)
                        Text("Markdown").tag(ExportFormat.markdown)
                        Text("PDF").tag(ExportFormat.pdf)
                    }
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .font(.system(.body, design: .monospaced))
                }
                
                Section {
                    HStack {
                        Text("Characters: \(content.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("Lines: \(content.components(separatedBy: .newlines).count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Import Transcript")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        importTranscript()
                    }
                    .disabled(!isValid)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
    }
    
    private var isValid: Bool {
        !title.isEmpty && !content.isEmpty && !sourcePlatform.isEmpty
    }
    
    private func importTranscript() {
        Task {
            await viewModel.importTranscript(
                title: title,
                content: content,
                sourceURL: sourceURL.isEmpty ? nil : sourceURL,
                sourcePlatform: sourcePlatform,
                exportFormat: exportFormat
            )
            isPresented = false
        }
    }
}
