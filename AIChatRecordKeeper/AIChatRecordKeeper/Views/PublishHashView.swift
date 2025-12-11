//
//  PublishHashView.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI

struct PublishHashView: View {
    @Bindable var viewModel: TranscriptViewModel
    let transcript: ChatTranscript
    @Binding var isPresented: Bool
    
    @State private var selectedService: PublicationService = .githubGist
    @State private var githubToken = ""
    @State private var webhookURL = ""
    @State private var isPublishing = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Hash to Publish") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SHA-256 Hash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(transcript.fileHash)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                Section("Publication Service") {
                    Picker("Service", selection: $selectedService) {
                        Text("GitHub Gist").tag(PublicationService.githubGist)
                        Text("OpenTimestamps").tag(PublicationService.openTimestamps)
                        Text("Custom Webhook").tag(PublicationService.customWebhook)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Credentials") {
                    switch selectedService {
                    case .githubGist:
                        SecureField("GitHub Personal Access Token", text: $githubToken)
                        
                        Link(destination: URL(string: "https://github.com/settings/tokens/new")!) {
                            Label("Create Token on GitHub", systemImage: "link")
                                .font(.caption)
                        }
                        
                    case .openTimestamps:
                        Text("No credentials required")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        
                        Text("OpenTimestamps is a free, decentralized timestamping service using the Bitcoin blockchain.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                    case .customWebhook:
                        TextField("Webhook URL", text: $webhookURL)
                            .textContentType(.URL)
                        
                        Text("The hash will be POSTed as JSON to this endpoint.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                    default:
                        EmptyView()
                    }
                }
                
                Section {
                    Text("Publishing creates an immutable, timestamped record of your transcript's hash. This proves the file existed in its current form at this moment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Publish Hash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") {
                        publishHash()
                    }
                    .disabled(!isValid || isPublishing)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var isValid: Bool {
        switch selectedService {
        case .githubGist:
            return !githubToken.isEmpty
        case .openTimestamps:
            return true
        case .customWebhook:
            return !webhookURL.isEmpty && webhookURL.starts(with: "http")
        default:
            return false
        }
    }
    
    private func publishHash() {
        isPublishing = true
        
        Task {
            let credentials: PublicationCredentials
            
            switch selectedService {
            case .githubGist:
                credentials = .github(token: githubToken)
            case .openTimestamps:
                credentials = .openTimestamps
            case .customWebhook:
                credentials = .webhook(url: webhookURL)
            default:
                return
            }
            
            await viewModel.publishHash(
                transcript,
                to: PublicationService.shared,
                credentials: credentials
            )
            
            isPublishing = false
            isPresented = false
        }
    }
}
