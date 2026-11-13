import App

@main
struct Server {
    static func main() async throws {
        let application = buildApplication()

        try await application.runService()
    }
}
