import SwiftUI

extension View {
    /// Type-erases the view to `AnyView`. Used by generic container components
    /// (e.g. `ListViewContainer`) that store heterogeneous view builders.
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
