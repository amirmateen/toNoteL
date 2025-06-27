//
//  FullPageNoteView.swift
//  toNoteL
//
//  Created by Amir Mateen on 27/06/25.
//

import SwiftUI
import PhotosUI

// MARK: - FullPageNoteView

struct FullPageNoteView: View {
    @ObservedObject var note: AppNote
    @StateObject private var audioService = AudioService()
    
    @State private var isCarouselPresented = false
    @State private var editingTextItemId: UUID? = nil
    @State private var currentEditText: String = ""
    
    // State for image pickers
    @State private var showingImagePicker = false
    @State private var showingCameraPicker = false
    @State private var selectedImageItems: [PhotosPickerItem] = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Note title - always at the top
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Untitled Note", text: $note.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .textFieldStyle(PlainTextFieldStyle())
                            .multilineTextAlignment(.leading)
                        
                        Text(note.timestamp, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60) // Account for status bar
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Note content items
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(note.items.enumerated()), id: \.element.id) { index, item in
                            VStack(alignment: .leading) {
                                switch item {
                                case .text(let textContent):
                                    if editingTextItemId == item.id {
                                        TextEditor(text: $currentEditText)
                                            .frame(minHeight: 120)
                                            .padding(12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .onDisappear {
                                                // Update the item with new text
                                                if let itemIndex = note.items.firstIndex(where: { $0.id == item.id }) {
                                                    note.items[itemIndex] = .text(currentEditText)
                                                }
                                                editingTextItemId = nil
                                            }
                                    } else {
                                        Text(textContent.isEmpty ? "Tap to add text..." : textContent)
                                            .font(.body)
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(textContent.isEmpty ? Color(.systemGray6) : Color.clear)
                                            .cornerRadius(8)
                                            .foregroundColor(textContent.isEmpty ? .gray : .primary)
                                            .onTapGesture {
                                                currentEditText = textContent
                                                editingTextItemId = item.id
                                            }
                                    }
                                    
                                case .imageData(let data):
                                    if let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(12)
                                            .shadow(radius: 2)
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 200)
                                            .overlay(
                                                VStack {
                                                    Image(systemName: "exclamationmark.triangle")
                                                        .font(.title)
                                                    Text("Unable to load image")
                                                        .font(.caption)
                                                }
                                                .foregroundColor(.gray)
                                            )
                                    }
                                    
                                case .voiceRecording(let data, let duration):
                                    VoiceNoteView(
                                        data: data,
                                        duration: duration,
                                        audioService: audioService
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .onDelete { offsets in
                            note.items.remove(atOffsets: offsets)
                        }
                    }
                    
                    // Add some bottom padding so content doesn't get hidden behind the add button
                    Color.clear.frame(height: 100)
                }
            }
            
            // Add content button
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        withAnimation(.spring()) {
                            isCarouselPresented.toggle()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            
            // Content addition carousel
            if isCarouselPresented {
                AddContentCarousel(
                    note: note,
                    audioService: audioService,
                    isPresented: $isCarouselPresented,
                    showingImagePicker: $showingImagePicker,
                    showingCameraPicker: $showingCameraPicker
                )
            }
        }
        .background(Color(.systemBackground))
        .onDisappear {
            audioService.stopPlayback()
            if audioService.isRecording {
                audioService.forceStopRecording()
            }
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedImageItems,
            maxSelectionCount: 5,
            matching: .images
        )
        .onChange(of: selectedImageItems) { newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            note.addImageItem(data: data)
                        }
                    }
                }
                await MainActor.run {
                    selectedImageItems = []
                }
            }
        }
    }
}

// MARK: - VoiceNoteView

struct VoiceNoteView: View {
    let data: Data
    let duration: TimeInterval
    @ObservedObject var audioService: AudioService
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                audioService.togglePlayback(for: data)
            }) {
                Image(systemName: audioService.isPlaying(data: data) ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice Note")
                    .font(.headline)
                
                HStack {
                    Text("\(String(format: "%.1f", duration))s")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if audioService.isPlaying(data: data) {
                        Text("• Playing")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Waveform visualization (placeholder)
            HStack(spacing: 2) {
                ForEach(0..<15, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 3, height: CGFloat.random(in: 8...24))
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
