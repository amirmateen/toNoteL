import SwiftUI

// MARK: - AppDataStore (ObservableObject)

class AppDataStore: ObservableObject {
    @Published var noteLists: [NoteList]

    init() {
        self.noteLists = [
            NoteList(name: "Journal", notes: [
                AppNote(title: "Morning thoughts about creativity and finding inspiration in everyday...", items: [.text("Today, 9:30 AM")]),
                AppNote(title: "Coffee shop sketching session", items: [.text("Yesterday, 2:15 PM")]),
                AppNote(title: "Design inspiration from Behance", items: [.text("behance.net/gallery/somet...")]),
            ]),
            NoteList(name: "Work", notes: [
                AppNote(title: "Meeting Q3", items: [.text("Discussed Q3 roadmap.")]),
            ]),
            NoteList(name: "Ideas", notes: [])
        ]
    }

    func addNoteList(name: String) {
        let newList = NoteList(name: name)
        noteLists.append(newList)
    }
}

