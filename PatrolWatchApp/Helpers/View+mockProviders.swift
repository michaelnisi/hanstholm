import SwiftUI

extension View {
    func withMockProviders() -> some View {
        #if DEBUG
        self.environment(SurfProvider.mock)
            .environment(LocationAuthorizer.shared)
        #else
        self
        #endif
    }
}
