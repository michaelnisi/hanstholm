#if !os(watchOS)
import DomainTypes
import SurfUI
import SwiftUI
import WidgetKit

struct GaugeReadout: View {
    let element: Double.Element
    var value: Double
    var direction: Direction

    var body: some View {
        VStack {
            value.text(element: element)
                .font(.title2)
                .fontWeight(.black)
            DirectionIndicator(
                degrees: direction.degrees,
                formatted: direction.formatted()
            )
            Text(direction.formatted())
                .font(.caption2)
        }
        .padding()
        .cappedDynamicType()
    }
}
#endif
