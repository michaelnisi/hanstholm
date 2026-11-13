import Hummingbird

public func buildApplication() -> some ApplicationProtocol {
    let router = Router()

    router.get("health") { _, _ in
        HTTPResponse.Status.ok
    }

    return Application(router: router)
}
