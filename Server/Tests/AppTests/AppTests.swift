import DomainTypes
import Foundation
import Hummingbird
import HummingbirdTesting
import Testing

@testable import App

@Suite("Application")
struct ApplicationTests {
    @Test("health check responds with 200")
    func healthResponds() async throws {
        let application = buildApplication()

        try await application.test(.router) { client in
            try await client.execute(uri: "/health", method: .get) { response in
                #expect(response.status == .ok)
            }
        }
    }

    @Test("DomainTypes encodes a Place on the server")
    func placeEncodes() throws {
        let place = Place(pluginID: "test", key: "spot", name: "Spot")

        let data = try JSONEncoder().encode(place)
        let decoded = try JSONDecoder().decode(Place.self, from: data)

        #expect(decoded == place)
    }
}
