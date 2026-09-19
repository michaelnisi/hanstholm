import SwiftUI

@MainActor
public struct DirectionIndicator: View {
    let degrees: Double
    let formatted: String
    let spoken: String

    public init(degrees: Double, formatted: String, spoken: String) {
        self.degrees = degrees
        self.formatted = formatted
        self.spoken = spoken
    }

    public var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "location.fill")
                .rotationEffect(.degrees(degrees - 45))
            Text(formatted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}
