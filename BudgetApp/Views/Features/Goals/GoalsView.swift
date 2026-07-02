import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: BudgetStore

    var body: some View {
        ListViewContainer(
            items: $store.goals,
            rowContent: { goal in
                GoalRowView(goal: goal)
                    .eraseToAnyView()
            },
            detailContent: { goal in
                GoalDetailSheet(goal: goal)
                    .eraseToAnyView()
            },
            editorContent: { goal in
                if let goal {
                    GoalEditorSheet(mode: .edit(goal)) { updated in
                        store.updateGoal(updated)
                    }
                    .eraseToAnyView()
                } else {
                    GoalEditorSheet(mode: .add) { newGoal in
                        store.addGoal(newGoal)
                    }
                    .eraseToAnyView()
                }
            },
            onAdd: store.addGoal,
            onUpdate: store.updateGoal,
            onDelete: store.deleteGoal
        )
    }
}

#if DEBUG
struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView()
            .environmentObject(BudgetStore.preview)
    }
}
#endif
