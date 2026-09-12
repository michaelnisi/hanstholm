import SwiftUI

@MainActor
public struct SurfGauge<Label: View>: View {
    public var value: Double
    public var total: Double
    public var tint: Color
    public var strokeWidth: Double
    @ViewBuilder public var label: () -> Label

    public init(
        value: Double,
        total: Double,
        tint: Color,
        strokeWidth: Double = 14,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.value = value
        self.total = total
        self.tint = tint
        self.strokeWidth = strokeWidth
        self.label = label
    }

    public var body: some View {
        ProgressView(
            value: max(0, min(value, total)),
            total: total > 0 ? total : 1
        )
        .progressViewStyle(GaugeProgressStyle(strokeColor: tint, strokeWidth: strokeWidth))
        .overlay { label() }
        .frame(idealWidth: 160, idealHeight: 160)
    }
}

@MainActor
public struct GaugeReadout: View {
    public var symbol: String
    public var value: String
    public var caption: String
    public var degrees: Double

    public init(symbol: String, value: String, caption: String, degrees: Double) {
        self.symbol = symbol
        self.value = value
        self.caption = caption
        self.degrees = degrees
    }

    public var body: some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.black)
            HStack(spacing: 3) {
                Image(systemName: "location.fill")
                    .rotationEffect(.degrees(degrees - 45))
                Text(caption)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}
