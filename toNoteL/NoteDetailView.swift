import SwiftUI
import PhotosUI // For modern image picking

// MARK: - NoteDetailView

struct NoteDetailView: View {
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
            List {
                Section("Title") {
                    TextField("Note Title", text: $note.title).font(.title2).bold()
                }
                Section("Content") {
                    ForEach($note.items) { $item in
                        VStack(alignment: .leading) {
                            switch item {
                            case .text(let textContent):
                                if editingTextItemId == item.id {
                                    TextEditor(text: $currentEditText)
                                        .frame(minHeight: 100).border(Color.gray.opacity(0.5))
                                        .onDisappear {
                                            if case .text(_) = item { item = .text(currentEditText) }
                                            editingTextItemId = nil
                                        }
                                } else {
                                    Text(textContent).padding(.vertical, 4)
                                        .onTapGesture {
                                            self.currentEditText = textContent
                                            self.editingTextItemId = item.id
                                        }
                                }
                            case .imageData(let data):
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().scaledToFit().cornerRadius(8).padding(.vertical, 4)
                                } else {
                                    Text("Error loading image").foregroundColor(.red)
                                }
                            case .voiceRecording(let data, let duration):
                                HStack {
                                    Button(action: { audioService.togglePlayback(for: data) }) {
                                        Image(systemName: audioService.isPlaying(data: data) ? "stop.fill" : "play.fill")
                                    }
                                    Text("Voice Memo (\(String(format: "%.1f", duration))s)")
                                    Spacer()
                                    if audioService.isPlaying(data: data) { Text("Playing...").font(.caption) }
                                }
                                .padding(.vertical, 4)
                            }
                        }.id(item.id)
                    }
                    .onDelete { offsets in note.items.remove(atOffsets: offsets) }
                }
                Color.clear.frame(height: 100)
            }
            .navigationTitle(note.title).navigationBarTitleDisplayMode(.inline)
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { withAnimation { isCarouselPresented.toggle() } }) {
                        Image(systemName: "plus").font(.title.weight(.semibold)).padding()
                            .background(Color.blue).foregroundColor(.white).clipShape(Circle()).shadow(radius: 4, x: 0, y: 4)
                    }
                    .padding()
                }
            }
            
            // Carousel View
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
        .onDisappear {
            audioService.stopPlayback()
            if audioService.isRecording { audioService.forceStopRecording() }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImageItems, maxSelectionCount: 5, matching: .images)
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

