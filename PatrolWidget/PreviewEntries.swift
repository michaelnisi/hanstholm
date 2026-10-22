#if DEBUG
import DomainTypes
import MockData

extension SurfEntry {
    static var typical: SurfEntry {
        MockData.SurfEntry.makeSurfEntry()
    }

    static var longPlaceName: SurfEntry {
        let place = Place(pluginID: "mock", key: "long", name: "Hvide Sande Nordre Strand")

        return MockData.SurfEntry.makeSurfEntry(place: place)
    }

    static var noGust: SurfEntry {
        SurfEntry(
            date: .now,
            place: MockData.SurfEntry.makePlace(),
            status: .ok,
            wave: MockData.SurfEntry.makeWave(),
            wind: .init(
                speed: .init(gust: nil, middle: 7, current: 5),
                direction: .init(cardinal: .southWest)
            )
        )
    }

    static var highSurf: SurfEntry {
        SurfEntry(
            date: .now,
            place: MockData.SurfEntry.makePlace(),
            status: .ok,
            wave: .init(max: 6.5, middle: 4.8, period: 14, direction: .init(cardinal: .northWest)),
            wind: .init(
                speed: .init(gust: 32, middle: 24, current: 21),
                direction: .init(cardinal: .north)
            )
        )
    }

    static var noData: SurfEntry {
        MockData.SurfEntry.makeSurfEntry(status: .error)
    }
}
#endif
