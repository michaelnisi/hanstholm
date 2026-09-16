import SwiftUI

@MainActor
public struct GaugeProgressStyle: ProgressViewStyle {
    let strokeColor: Color

    public init(strokeColor: Color) {
        self.strokeColor = strokeColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0
        let x = fractionCompleted * 0.766

        return GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let strokeWidth = (.pi * diameter) / 8

            ZStack {
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
            .frame(width: diameter, height: diameter)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}
