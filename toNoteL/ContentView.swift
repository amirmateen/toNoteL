import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var dataStore: AppDataStore
    @State private var currentNoteIndex = 0
    @State private var showingAddNoteAlert = false
    @State private var newNoteTitle = ""
    
    // Get all notes from all lists combined
    var allNotes: [AppNote] {
        dataStore.noteLists.flatMap { $0.notes }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if allNotes.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Notes Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Tap the + button to create your first note")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // Full-page horizontal scrolling notes
                    TabView(selection: $currentNoteIndex) {
                        ForEach(Array(allNotes.enumerated()), id: \.element.id) { index, note in
                            FullPageNoteView(note: note)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .ignoresSafeArea()
                }
                
                // Floating Add Button - Always visible
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddNoteAlert = true }) {
                            Image(systemName: "plus")
                                .font(.title.weight(.semibold))
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
                }
                
                // Page indicator dots (optional)
                if !allNotes.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            ForEach(0..<allNotes.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentNoteIndex ? Color.primary : Color.gray.opacity(0.4))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == currentNoteIndex ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: currentNoteIndex)
                            }
                        }
                        .padding(.bottom, 120) // Above the add button
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("New Note", isPresented: $showingAddNoteAlert) {
            TextField("Note Title", text: $newNoteTitle)
            Button("Add") {
                if !newNoteTitle.isEmpty {
                    addNewNote(title: newNoteTitle)
                    newNoteTitle = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newNoteTitle = ""
            }
        } message: {
            Text("Enter a title for your new note")
        }
    }
    
    private func addNewNote(title: String) {
        // Add to the first list, or create a default list if none exists
        if dataStore.noteLists.isEmpty {
            dataStore.addNoteList(name: "Notes")
        }
        
        dataStore.noteLists[0].addNote(title: title)
        
        // Navigate to the new note (it will be at index 0 since we insert at the beginning)
        currentNoteIndex = 0
    }
}
