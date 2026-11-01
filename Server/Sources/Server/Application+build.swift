import Hummingbird

public func buildApplication(host: String, port: Int) -> some ApplicationProtocol {
    let router = Router()

    router.get("health") { _, _ in
        HTTPResponse.Status.ok
    }

    return Application(
        router: router,
        configuration: .init(address: .hostname(host, port: port))
    )
}
