import DomainTypes
import SwiftUI

public struct DirectionIndicator: View {
    let direction: Direction

    public init(direction: Direction) {
        self.direction = direction
    }

    public var body: some View {
        VStack {
            Image(systemName: "location.fill")
                .rotationEffect(.degrees(direction.degrees - 45))
                .accessibilityHidden(true)
            Text(direction.formatted())
                .font(.caption2)
        }
    }
}
