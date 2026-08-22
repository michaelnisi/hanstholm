import Foundation
import DomainTypes

public struct MockData {
    public struct SurfEntry {
        public static func makePlace() -> DomainTypes.Place {
            .init(pluginID: "mock", key: "hanstholm", name: "Hanstholm", icon: "water.waves")
        }

        public static func makePlaces() -> [DomainTypes.Place] {
            [
                makePlace(),
                .init(pluginID: "mock", key: "hvide-sande", name: "Hvide Sande", icon: "water.waves"),
                .init(pluginID: "mock", key: "thorsminde", name: "Thorsminde", icon: "water.waves")
            ]
        }

        public static func makeSurfEntry(status: DomainTypes.SurfEntry.Status = .ok) -> DomainTypes.SurfEntry {
            .init(
                date: .now,
                place: makePlace(),
                status: status,
                wave: makeWave(),
                wind: makeWind()
            )
        }
        
        public static func makeWind() -> DomainTypes.SurfEntry.Wind {
            .init(speed: .init(gust: 10, middle: 7, current: 5), direction: .init(cardinal: .southWest))
        }
        
        public static func makeWave() -> DomainTypes.SurfEntry.Wave {
            .init(max: 2.0, middle: 1.2, period: 8, direction: .init(cardinal: .northWest))
        }
    }
}
