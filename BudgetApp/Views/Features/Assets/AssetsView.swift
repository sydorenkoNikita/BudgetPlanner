import SwiftUI

struct AssetsView: View {
    @EnvironmentObject private var store: BudgetStore

    var body: some View {
        ListViewContainer(
            items: $store.assets,
            rowContent: { asset in
                AssetRowView(asset: asset)
                    .eraseToAnyView()
            },
            detailContent: { asset in
                AssetDetailSheet(asset: asset)
                    .eraseToAnyView()
            },
            editorContent: { asset in
                if let asset {
                    AssetEditorSheet(mode: .edit(asset)) { updated in
                        store.updateAsset(updated)
                    }
                    .eraseToAnyView()
                } else {
                    AssetEditorSheet(mode: .add) { newAsset in
                        store.addAsset(newAsset)
                    }
                    .eraseToAnyView()
                }
            },
            onAdd: store.addAsset,
            onUpdate: store.updateAsset,
            onDelete: store.deleteAsset
        )
    }
}

#if DEBUG
struct AssetsView_Previews: PreviewProvider {
    static var previews: some View {
        AssetsView()
            .environmentObject(BudgetStore.preview)
    }
}
#endif
