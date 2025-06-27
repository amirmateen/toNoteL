import SwiftUI

// MARK: - NoteListView

struct NoteListView: View {
    @ObservedObject var noteList: NoteList
    @State private var showingAddNoteAlert = false
    @State private var newNoteTitle = ""

    var body: some View {
        // Use a ScrollView to allow for the custom card layout.
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // Header section that matches the desired UI.
                Text(noteList.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(noteList.notes.count) Pages")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Notes are now displayed in a grid of cards.
                ForEach(noteList.notes) { note in
                    NavigationLink(value: note) {
                        NoteCardView(note: note)
                    }
                    .buttonStyle(PlainButtonStyle()) // Removes default button styling from the link.
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
        .navigationTitle("") // Hide the default navigation bar title.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Custom toolbar items to match the screenshot.
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}) {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .principal) {
                Button(action: {}) {
                    Text("123") // As per the image.
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(for: AppNote.self) { note in
             NoteDetailView(note: note)
        }
        .safeAreaInset(edge: .bottom) {
            // Floating Add Button, properly aligned.
            HStack {
                Spacer()
                Button(action: { showingAddNoteAlert = true }) {
                    Image(systemName: "plus")
                        .font(.title.weight(.semibold))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 5, x: 0, y: 5)
                }
                .padding(.trailing)
            }
        }
        .alert("New Note", isPresented: $showingAddNoteAlert) {
            TextField("Note Title", text: $newNoteTitle)
            Button("Add") {
                if !newNoteTitle.isEmpty {
                    noteList.addNote(title: newNoteTitle)
                    newNoteTitle = ""
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

