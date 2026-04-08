import SwiftUI

struct TodoListView: View {
    @EnvironmentObject var store: TodoStore
    @State private var newTitle: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
                TextField("New todo…", text: $newTitle)
                    .textFieldStyle(.plain)
                    .focused($inputFocused)
                    .font(.system(size: 14))
                    .onSubmit(add)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .textBackgroundColor))

            Divider()

            if store.todos.isEmpty {
                Spacer()
                Text("Nothing to do.")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                Spacer()
            } else {
                List {
                    ForEach($store.todos) { $todo in
                        TodoRow(todo: $todo) {
                            store.delete(todo.id)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                    }
                    .onMove { source, destination in
                        store.move(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 320, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { inputFocused = true }
    }

    private func add() {
        store.add(newTitle)
        newTitle = ""
        inputFocused = true
    }
}

private struct TodoRow: View {
    @Binding var todo: Todo
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                todo.done.toggle()
            } label: {
                Image(systemName: todo.done ? "checkmark.square.fill" : "square")
                    .font(.system(size: 15))
                    .foregroundStyle(todo.done ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            TextField("", text: $todo.title)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .strikethrough(todo.done)
                .foregroundStyle(todo.done ? .secondary : .primary)

            Spacer(minLength: 0)

            if hovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}
