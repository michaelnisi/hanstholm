import SwiftUI

@MainActor
public struct TimestampCaption: View {
    public nonisolated static let textColor = ContrastColor(red: 1, green: 1, blue: 1)
    public nonisolated static let scrimColor = ContrastColor(red: 0, green: 0, blue: 0)

    let date: Date

    public init(date: Date) {
        self.date = date
    }

    public var body: some View {
        Text(date.formatted(date: .omitted, time: .shortened))
            .font(.caption)
            .foregroundStyle(Self.textColor.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Self.scrimColor.color, in: Capsule())
    }
}

#Preview {
    TimestampCaption(date: .now)
        .padding()
        .background(Color.accentColor.gradient)
}
