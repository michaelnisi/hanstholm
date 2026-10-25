import SwiftUI

@MainActor
public struct DirectionIndicator: View {
    let degrees: Double

    public init(degrees: Double) {
        self.degrees = degrees
    }

    public var body: some View {
        Image(systemName: "location.fill")
            .rotationEffect(.degrees(degrees - 45))
            .accessibilityHidden(true)
    }
}
