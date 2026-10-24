#if DEBUG
import DomainTypes
import MockData

struct PreviewState {
    let name: String
    let entry: SurfEntry
}

extension PreviewState {
    static let typical = PreviewState(
        name: "Typical",
        entry: MockData.SurfEntry.makeSurfEntry()
    )

    static let longPlaceName = PreviewState(
        name: "Long place name",
        entry: MockData.SurfEntry.makeSurfEntry(
            place: Place(pluginID: "mock", key: "long", name: "Hvide Sande Nordre Strand")
        )
    )

    static let noGust = PreviewState(
        name: "No gust",
        entry: SurfEntry(
            date: .now,
            place: MockData.SurfEntry.makePlace(),
            status: .ok,
            wave: MockData.SurfEntry.makeWave(),
            wind: .init(
                speed: .init(gust: nil, middle: 7, current: 5),
                direction: .init(cardinal: .southWest)
            )
        )
    )

    static let highSurf = PreviewState(
        name: "High surf",
        entry: SurfEntry(
            date: .now,
            place: MockData.SurfEntry.makePlace(),
            status: .ok,
            wave: .init(max: 6.5, middle: 4.8, period: 14, direction: .init(cardinal: .northWest)),
            wind: .init(
                speed: .init(gust: 32, middle: 24, current: 21),
                direction: .init(cardinal: .north)
            )
        )
    )

    static let noData = PreviewState(
        name: "No data",
        entry: MockData.SurfEntry.makeSurfEntry(status: .error)
    )
}

extension SurfEntry {
    static var typical: SurfEntry { PreviewState.typical.entry }
    static var longPlaceName: SurfEntry { PreviewState.longPlaceName.entry }
    static var noGust: SurfEntry { PreviewState.noGust.entry }
    static var highSurf: SurfEntry { PreviewState.highSurf.entry }
    static var noData: SurfEntry { PreviewState.noData.entry }
}
#endif
