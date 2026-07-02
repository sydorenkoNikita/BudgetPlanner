# Task 4: Create ListViewContainer Generic Component - FULL CONTENT

## Create BudgetApp/Views/Components/ListViewContainer.swift

Copy this exact content:

```swift
import SwiftUI

struct ListViewContainer<Item: Identifiable>: View {
    @Binding var items: [Item]
    @State private var selectedItem: Item?
    @State private var editingItem: Item?
    @State private var isEditorShowing = false
    @State private var itemToDelete: Item?
    
    let rowContent: (Item) -> AnyView
    let detailContent: ((Item) -> AnyView)?
    let editorContent: ((Item?) -> AnyView)?
    let onAdd: ((Item) -> Void)?
    let onUpdate: ((Item) -> Void)?
    let onDelete: ((Item) -> Void)?
    
    var body: some View {
        NavigationSplitView {
            List(items, id: \.id, selection: $selectedItem) { item in
                Button(action: { selectedItem = item }) {
                    rowContent(item)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive, action: { itemToDelete = item }) {
                        Label(Strings.Common.delete, systemImage: "trash")
                    }
                    Button(action: { editingItem = item; isEditorShowing = true }) {
                        Label(Strings.Common.edit, systemImage: "pencil")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { editingItem = nil; isEditorShowing = true }) {
                        Label(Strings.Common.add, systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selected = selectedItem, let detailContent = detailContent {
                detailContent(selected)
            } else {
                ContentUnavailableView(
                    Strings.Common.noData,
                    systemImage: "text.page"
                )
            }
        }
        .sheet(isPresented: $isEditorShowing, onDismiss: { editingItem = nil }) {
            if let editorContent = editorContent {
                editorContent(editingItem)
            }
        }
        .confirmationDialog(
            Strings.Common.delete,
            isPresented: .constant(itemToDelete != nil),
            presenting: itemToDelete
        ) { item in
            Button(Strings.Common.delete, role: .destructive) {
                onDelete?(item)
                itemToDelete = nil
                selectedItem = nil
            }
        } message: { item in
            Text("Вы уверены?")
        }
    }
}

// MARK: - Preview
#if DEBUG
struct ListViewContainer_Previews: PreviewProvider {
    struct SimpleItem: Identifiable {
        let id = UUID()
        var name: String
    }
    
    static var previews: some View {
        @State var items: [SimpleItem] = [
            SimpleItem(name: "Item 1"),
            SimpleItem(name: "Item 2"),
        ]
        
        return ListViewContainer(
            items: $items,
            rowContent: { item in
                Text(item.name).eraseToAnyView()
            },
            detailContent: nil,
            editorContent: nil,
            onAdd: nil,
            onUpdate: nil,
            onDelete: nil
        )
    }
}
#endif
```

## Success Criteria
- File created at correct path
- Compiles without errors
- Single commit: "feat: add generic ListViewContainer component"

## Dependencies
- Task 1 (folder structure) complete
- Task 2 (Strings.swift) complete
