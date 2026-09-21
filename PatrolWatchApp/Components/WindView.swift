import SwiftUI
import DomainTypes
import MockData
import SurfUI

struct WindView: View {
    let name: String
    let date: Date
    let wind: SurfEntry.Wind
    
    var body: some View {
        SurfGauge(value: wind.speed.middle, total: wind.speed.gust ?? wind.speed.middle, tint: .teal) {
            WindInfo(
                date: date,
                speed: wind.speed.current,
                direction: wind.direction
            )
        }
        .overlay(alignment: .bottom) {
            wind.speed.gust.knotsText()
                .font(.headline)
        }
        .fontDesign(.rounded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = "\(name). \(wind.spoken)"

        if let gust = wind.speed.gust {
            label += ", gusting \(gust.knots(width: .wide))"
        }

        label += ". Updated \(date.formatted(date: .omitted, time: .shortened))."

        return label
    }
}

struct WindInfo: View {
    let date: Date
    let speed: Double
    let direction: Direction

    var body: some View {
        VStack {
            DirectionIndicator(
                degrees: direction.degrees,
                formatted: direction.formatted(),
                spoken: direction.spoken()
            )

            speed.knotsText()
                .font(.title2)
                .fontWeight(.bold)
            
            TimestampCaption(date: date)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

#Preview {
    WindView(
        name: "Hanstholm",
        date: .now,
        wind: MockData.SurfEntry.makeWind()
    )
}

#Preview("No Gust") {
    WindView(
        name: "Thorsminde",
        date: .now,
        wind: .init(
            speed: .init(gust: nil, middle: 7, current: 5),
            direction: .init(cardinal: .southWest)
        )
    )
}
