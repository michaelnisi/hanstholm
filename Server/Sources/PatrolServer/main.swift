import Foundation
import Server

let environment = ProcessInfo.processInfo.environment

let host = environment["HOST"] ?? "127.0.0.1"
let port = environment["PORT"].flatMap(Int.init) ?? 8080

try await buildApplication(host: host, port: port).runService()
