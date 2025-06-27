import SwiftUI

// MARK: - Updated AddContentCarousel

struct AddContentCarousel: View {
    @ObservedObject var note: AppNote
    @ObservedObject var audioService: AudioService
    @Binding var isPresented: Bool
    
    // Bindings to control the image pickers in the parent view
    @Binding var showingImagePicker: Bool
    @Binding var showingCameraPicker: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background overlay
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 0) {
                // Recording indicator
                if audioService.isRecording {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(audioService.isRecording ? 1.0 : 0.1)
                            .animation(.easeInOut(duration: 0.5).repeatForever(), value: audioService.isRecording)
                        
                        Text("Recording... \(String(format: "%.1f", audioService.recordingTime))s")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Content type selection carousel
                VStack(spacing: 20) {
                    Text("Add Content")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 30) {
                            // Text Button
                            ContentTypeButton(
                                icon: "text.cursor",
                                title: "Text",
                                color: .green
                            ) {
                                note.addTextItem(text: "")
                                withAnimation(.spring()) {
                                    isPresented = false
                                }
                            }
                            
                            // Voice Button
                            ContentTypeButton(
                                icon: audioService.isRecording ? "stop.fill" : "mic.fill",
                                title: audioService.isRecording ? "Stop" : "Voice",
                                color: audioService.isRecording ? .red : .blue
                            ) {
                                if audioService.isRecording {
                                    audioService.stopRecording { data, duration in
                                        if let data = data, let duration = duration {
                                            note.addVoiceItem(data: data, duration: duration)
                                        }
                                        DispatchQueue.main.async {
                                            withAnimation(.spring()) {
                                                isPresented = false
                                            }
                                        }
                                    }
                                } else {
                                    audioService.startRecording()
                                }
                            }
                            
                            // Photo Library Button
                            ContentTypeButton(
                                icon: "photo.on.rectangle",
                                title: "Photos",
                                color: .purple
                            ) {
                                showingImagePicker = true
                                withAnimation(.spring()) {
                                    isPresented = false
                                }
                            }
                            
                            // Camera Button
                            ContentTypeButton(
                                icon: "camera.fill",
                                title: "Camera",
                                color: .orange
                            ) {
                                showingCameraPicker = true
                                withAnimation(.spring()) {
                                    isPresented = false
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // Cancel button
                    Button("Cancel") {
                        if audioService.isRecording {
                            audioService.forceStopRecording()
                        }
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .shadow(radius: 10)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - ContentTypeButton

struct ContentTypeButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                action()
            }) {
                ZStack {
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 70, height: 70)
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}
