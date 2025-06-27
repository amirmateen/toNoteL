import SwiftUI

// MARK: - NoteCardView (New View)

struct NoteCardView: View {
    @ObservedObject var note: AppNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)
                .lineLimit(3)

            if let firstItem = note.items.first, case .text(let previewText) = firstItem {
                Text(previewText)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

