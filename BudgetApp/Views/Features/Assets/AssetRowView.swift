import SwiftUI

struct AssetRowView: View {
    let asset: Asset
    @EnvironmentObject private var store: BudgetStore

    var body: some View {
        HStack {
            Text(asset.emoji)
                .font(.headline)

            VStack(alignment: .leading) {
                Text(asset.name)
                    .font(.body)
                Text(asset.kind.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                MoneyView(money: store.display(asset.money))
                    .font(.body)
                Text(asset.money.currency.code)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppConfig.UI.listItemPadding)
    }
}

#if DEBUG
struct AssetRowView_Previews: PreviewProvider {
    static var previews: some View {
        AssetRowView(
            asset: Asset(
                name: "Test Asset",
                emoji: "💳",
                kind: .cash,
                money: .uah(1000),
                sortOrder: 0
            )
        )
        .environmentObject(BudgetStore.preview)
    }
}
#endif
