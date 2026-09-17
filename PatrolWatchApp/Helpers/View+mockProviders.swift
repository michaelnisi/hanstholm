import SwiftUI

extension View {
    func withMockProviders() -> some View {
        #if DEBUG
        self.environment(SurfProvider.mock)
        #else
        self
        #endif
    }
}
