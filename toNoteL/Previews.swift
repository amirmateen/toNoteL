//
//  Previews.swift
//  toNoteL
//
//  Created by Amir Mateen on 26/06/25.
//
import SwiftUI


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let previewDataStore = AppDataStore()
        ContentView().environmentObject(previewDataStore)
        if let firstList = previewDataStore.noteLists.first, !firstList.notes.isEmpty {
            NavigationStack { NoteDetailView(note: firstList.notes[0]) }.previewDisplayName("Note Detail View")
        }
    }
}
