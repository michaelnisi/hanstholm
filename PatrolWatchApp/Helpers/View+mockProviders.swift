import SwiftUI

extension View {
    func withMockProviders() -> some View {
        self
            .environment(SurfProvider.mock)
    }
}
