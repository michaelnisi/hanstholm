import SwiftUI
import DomainTypes
import MockData

struct WindView: View {
    let name: String
    let date: Date
    let wind: SurfEntry.Wind
    
    var body: some View {
        ZStack {
            ProgressView(value: wind.speed.middle, total: wind.speed.gust ?? wind.speed.middle)
                .progressViewStyle(GaugeProgressStyle(strokeColor: .teal))

            WindInfo(
                name: name,
                date: date,
                speed: wind.speed.current,
                degrees: wind.direction.degrees
            )
        }
        .overlay(alignment: .bottom) {
            wind.speed.gust.knotsText()
                .font(.headline)
        }
        .fontDesign(.rounded)
    }
}

struct WindInfo: View {
    let name: String
    let date: Date
    let speed: Double
    let degrees: Double

    var locationDegrees: Double {
        degrees - 45
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "location.fill")
                    .rotationEffect(.degrees(locationDegrees))
                
                Text(name)
                    .font(.caption)
            }
            
            speed.knotsText()
                .font(.title2)
                .fontWeight(.bold)
            
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.teal)
        }
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
