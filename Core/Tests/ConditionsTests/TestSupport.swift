import Foundation
import DomainTypes
import ConditionsPlugin

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    var count: Int {
        lock.lock()

        defer {
            lock.unlock()
        }

        return value
    }
}

let stubPluginID: PluginID = "test.stub"

func makePlace(key: String = "testville", name: String = "Testville") -> Place {
    Place(pluginID: stubPluginID, key: key, name: name)
}

func makeEntry(date: Date = .now, place: Place = makePlace()) -> SurfEntry {
    SurfEntry(
        date: date,
        place: place,
        status: .ok,
        wave: .init(max: 1.2, middle: 0.8, period: 8, direction: .init(cardinal: .west)),
        wind: .init(speed: .init(gust: 12, middle: 9, current: 10), direction: .init(cardinal: .west))
    )
}

struct StubPlugin: ConditionsPlugin, DeferredDownloadable {
    let id: PluginID
    let places: [Place]
    let region: GeoRegion
    let fetches = Counter()
    let decodes = Counter()
    let entry: @Sendable (Place) async throws -> SurfEntry

    func conditions(for place: Place, using session: URLSession) async throws -> SurfEntry {
        fetches.increment()

        return try await entry(place)
    }

    func deferredRequest(for place: Place) throws -> URLRequest {
        URLRequest(url: URL(string: "https://example.invalid/\(place.key)")!)
    }

    func decodeDeferred(_ data: Data, mimeType: String?, for place: Place) async throws -> SurfEntry {
        decodes.increment()

        return try await entry(place)
    }
}

struct StubFault: Error {}

func makePlugin(
    id: PluginID = stubPluginID,
    places: [Place] = [makePlace()],
    region: GeoRegion = GeoRegion(latitude: 0, longitude: 0, radius: 0),
    entry: (@Sendable (Place) async throws -> SurfEntry)? = nil
) -> StubPlugin {
    StubPlugin(
        id: id,
        places: places,
        region: region,
        entry: entry ?? { place in makeEntry(place: place) }
    )
}
