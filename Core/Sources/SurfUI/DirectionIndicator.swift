import SwiftUI

@MainActor
public struct DirectionIndicator: View {
    let degrees: Double
    let formatted: String

    public init(degrees: Double, formatted: String) {
        self.degrees = degrees
        self.formatted = formatted
    }

    public var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "location.fill")
                .rotationEffect(.degrees(degrees - 45))
            Text(formatted)
        }
        .accessibilityHidden(true)
    }
}
