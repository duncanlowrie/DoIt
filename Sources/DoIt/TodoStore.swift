import Foundation
import SwiftUI

struct Todo: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var done: Bool = false
}

@MainActor
final class TodoStore: ObservableObject {
    @Published var todos: [Todo] = [] {
        didSet { save() }
    }

    private let fileURL: URL
    private var loading = false

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("DoIt", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("todos.json")
        load()
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todos.insert(Todo(title: trimmed), at: 0)
    }

    func delete(_ id: Todo.ID) {
        todos.removeAll { $0.id == id }
    }

    func move(from source: IndexSet, to destination: Int) {
        todos.move(fromOffsets: source, toOffset: destination)
    }

    private func load() {
        loading = true
        defer { loading = false }
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Todo].self, from: data) else { return }
        todos = decoded
    }

    private func save() {
        guard !loading else { return }
        guard let data = try? JSONEncoder().encode(todos) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
