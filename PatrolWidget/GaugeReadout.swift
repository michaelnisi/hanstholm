#if !os(watchOS)
import DomainTypes
import SurfUI
import SwiftUI
import WidgetKit

struct GaugeReadout: View {
    var symbol: String
    var value: String
    var caption: String
    var direction: Direction

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.black)
            HStack(spacing: 3) {
                DirectionIndicator(
                    degrees: direction.degrees,
                    formatted: direction.formatted()
                )
                Text(caption)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .cappedDynamicType()
    }
}

#Preview("Wave", as: .systemSmall) {
    PatrolWidget()
} timeline: {
    SurfEntry.typical
    SurfEntry.highSurf
}
#endif
