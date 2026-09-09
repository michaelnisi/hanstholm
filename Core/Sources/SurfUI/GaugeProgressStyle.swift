import SwiftUI

@MainActor
public struct GaugeProgressStyle: ProgressViewStyle {
    let strokeColor: Color
    let strokeWidth: Double

    public init(strokeColor: Color, strokeWidth: Double = 20) {
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0
        let x = fractionCompleted * 0.766

        return ZStack {
            Circle()
                .trim(from: 0, to: 0.766)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .opacity(0.3)
                .rotationEffect(.degrees(135))

            Circle()
                .trim(from: 0, to: x)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
        }
    }
}
