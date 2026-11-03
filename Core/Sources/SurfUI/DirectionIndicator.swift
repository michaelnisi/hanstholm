import SwiftUI

public struct DirectionIndicator: View {
    private let degrees: Double
    private let direction: String

    public init(degrees: Double, direction: String) {
        self.degrees = degrees
        self.direction = direction
    }

    public var body: some View {
        VStack {
            Image(systemName: "location.fill")
                .rotationEffect(.degrees(degrees - 45))
                .accessibilityHidden(true)
            Text(direction)
                .font(.caption2)
        }
    }
}
