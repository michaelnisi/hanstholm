import SwiftUI

@MainActor
public struct SurfGauge<Label: View>: View {
    let value: Double
    let total: Double
    let tint: Color
    let label: () -> Label

    public init(value: Double, total: Double, tint: Color, @ViewBuilder label: @escaping () -> Label) {
        self.value = value
        self.total = total
        self.tint = tint
        self.label = label
    }

    public var body: some View {
        ProgressView(
            value: max(0, min(value, total)),
            total: total > 0 ? total : 1
        )
        .progressViewStyle(GaugeProgressStyle(strokeColor: tint))
        .overlay { label() }
    }
}
