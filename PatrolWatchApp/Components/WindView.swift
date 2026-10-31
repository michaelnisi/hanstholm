import DomainTypes
import MockData
import SurfUI
import SwiftUI

struct WindView: View {
    let name: String
    let date: Date
    let wind: SurfEntry.Wind

    var body: some View {
        SurfGauge(
            value: wind.speed.middle,
            total: wind.speed.gust ?? wind.speed.middle,
            tint: .teal
        ) {
            wind.speed.middle.knotsText()
                .font(.title2)
                .fontWeight(.black)
        }
        .overlay(alignment: .bottom) {
            DirectionIndicator(direction: wind.direction)
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
