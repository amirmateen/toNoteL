import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Enhanced DataModels

// Represents an individual piece of content within a note
enum NoteContentItem: Identifiable, Codable, Hashable {
    case text(String)
    case imageData(Data)
    case voiceRecording(Data, TimeInterval)

    var id: UUID { UUID() }

    var typeName: String {
        switch self {
        case .text: return "Text"
        case .imageData: return "Image"
        case .voiceRecording: return "Voice"
        }
    }
    
    var textValue: String? {
        if case .text(let str) = self {
            return str
        }
        return nil
    }
    
    // Preview text for the note (first few characters)
    var previewText: String? {
        if case .text(let str) = self, !str.isEmpty {
            return String(str.prefix(100))
        }
        return nil
    }

    // MARK: Codable Conformance
    private enum CodingKeys: String, CodingKey {
        case text, imageData, voiceRecording
    }
    
    private enum VoiceCodingKeys: String, CodingKey {
        case data, duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try? container.decode(String.self, forKey: .text) {
            self = .text(text)
            return
        }
        if let imageData = try? container.decode(Data.self, forKey: .imageData) {
            self = .imageData(imageData)
            return
        }
        if let voiceContainer = try? container.nestedContainer(keyedBy: VoiceCodingKeys.self, forKey: .voiceRecording) {
            let data = try voiceContainer.decode(Data.self, forKey: .data)
            let duration = try voiceContainer.decode(TimeInterval.self, forKey: .duration)
            self = .voiceRecording(data, duration)
            return
        }
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Data doesn't match any cases"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode(text, forKey: .text)
        case .imageData(let data):
            try container.encode(data, forKey: .imageData)
        case .voiceRecording(let data, let duration):
            var voiceContainer = container.nestedContainer(keyedBy: VoiceCodingKeys.self, forKey: .voiceRecording)
            try voiceContainer.encode(data, forKey: .data)
            try voiceContainer.encode(duration, forKey: .duration)
        }
    }
}

// Represents a single note
class AppNote: Identifiable, ObservableObject, Codable, Hashable {
    static func == (lhs: AppNote, rhs: AppNote) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var id: UUID
    @Published var title: String
    @Published var items: [NoteContentItem]
    @Published var timestamp: Date
    @Published var lastModified: Date

    init(id: UUID = UUID(), title: String, items: [NoteContentItem] = [], timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.items = items
        self.timestamp = timestamp
        self.lastModified = timestamp
    }
    
    // Computed property for note preview
    var preview: String {
        if !title.isEmpty {
            return title
        }
        
        // Find the first text item with content
        for item in items {
            if let text = item.previewText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
        }
        
        // If no text, describe the content
        let textCount = items.compactMap { $0.textValue }.count
        let imageCount = items.filter { if case .imageData = $0 { return true }; return false }.count
        let voiceCount = items.filter { if case .voiceRecording = $0 { return true }; return false }.count
        
        var components: [String] = []
        if textCount > 0 { components.append("\(textCount) text") }
        if imageCount > 0 { components.append("\(imageCount) image\(imageCount > 1 ? "s" : "")") }
        if voiceCount > 0 { components.append("\(voiceCount) voice note\(voiceCount > 1 ? "s" : "")") }
        
        return components.isEmpty ? "Empty note" : components.joined(separator: ", ")
    }
    
    // MARK: Codable Conformance
    enum CodingKeys: String, CodingKey {
        case id, title, items, timestamp, lastModified
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        items = try container.decode([NoteContentItem].self, forKey: .items)
        
        // 1. Decode and assign timestamp first.
        let decodedTimestamp = try container.decode(Date.self, forKey: .timestamp)
        timestamp = decodedTimestamp
        
        // 2. Now that timestamp is initialized, it's safe to use it as a fallback.
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? decodedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(items, forKey: .items)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(lastModified, forKey: .lastModified)
    }
    
    // MARK: Content Management
    func addTextItem(text: String = "") {
        items.append(.text(text))
        updateLastModified()
    }
    
    func addImageItem(data: Data) {
        items.append(.imageData(data))
        updateLastModified()
    }
    
    func addVoiceItem(data: Data, duration: TimeInterval) {
        items.append(.voiceRecording(data, duration))
        updateLastModified()
    }
    
    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        updateLastModified()
    }
    
    private func updateLastModified() {
        lastModified = Date()
    }
    
    // Check if note is empty
    var isEmpty: Bool {
        return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               items.allSatisfy { item in
                   if case .text(let text) = item {
                       return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                   }
                   return false
               }
    }
}

// Represents a list of notes
class NoteList: Identifiable, ObservableObject, Codable, Hashable {
    static func == (lhs: NoteList, rhs: NoteList) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    var id: UUID
    @Published var name: String
    @Published var notes: [AppNote]

    init(id: UUID = UUID(), name: String, notes: [AppNote] = []) {
        self.id = id
        self.name = name
        self.notes = notes
    }
    
    // MARK: Codable Conformance
    enum CodingKeys: String, CodingKey {
        case id, name, notes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        notes = try container.decode([AppNote].self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(notes, forKey: .notes)
    }
    
    // MARK: Note Management
    func addNote(title: String) {
        let newNote = AppNote(title: title)
        notes.insert(newNote, at: 0) // Insert at beginning for most recent first
    }
    
    func removeNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
    
    func removeNote(_ note: AppNote) {
        notes.removeAll { $0.id == note.id }
    }
    
    // Sort notes by last modified date
    func sortNotesByLastModified() {
        notes.sort { $0.lastModified > $1.lastModified }
    }
}
