import ConditionsPlugin
import DomainTypes
import Foundation
import Hyde

struct Finding: Encodable {
    enum Status: String, Encodable {
        case healthy
        case broken
        case unavailable
        case unreachable
    }

    let place: String
    let status: Status
    let detail: String
}

let plugins: [any DeferredDownloadable] = [
    Hyde()
]

struct HTTPFailure: Error, CustomStringConvertible {
    let statusCode: Int

    var isClientError: Bool {
        (400..<500).contains(statusCode)
    }

    var description: String {
        "HTTP \(statusCode)"
    }
}

struct Arguments {
    let savedPagesDirectory: URL
    let replayDirectory: URL?

    init(_ arguments: [String]) throws {
        guard arguments.count >= 2 else {
            throw Usage()
        }

        savedPagesDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
        replayDirectory =
            arguments.count >= 4 && arguments[2] == "--replay"
            ? URL(fileURLWithPath: arguments[3], isDirectory: true)
            : nil
    }

    struct Usage: Error, CustomStringConvertible {
        let description = "usage: probe <saved-pages-directory> [--replay <directory>]"
    }
}

func page(for place: Place, plugin: any DeferredDownloadable, arguments: Arguments) async throws
    -> (data: Data, mimeType: String?)
{
    let file = "\(place.key).html"

    if let replayDirectory = arguments.replayDirectory {
        let data = try Data(contentsOf: replayDirectory.appendingPathComponent(file))

        return (data, "text/html")
    }

    let (data, response) = try await URLSession.shared.data(
        for: try plugin.deferredRequest(for: place))

    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        throw HTTPFailure(statusCode: http.statusCode)
    }

    return (data, response.mimeType)
}

func label(for place: Place) -> String {
    "\(place.pluginID.rawValue)/\(place.key)"
}

func finding(for place: Place, plugin: any DeferredDownloadable, arguments: Arguments) async
    -> Finding
{
    let fetched: (data: Data, mimeType: String?)

    do {
        fetched = try await page(for: place, plugin: plugin, arguments: arguments)
    } catch let failure as HTTPFailure where failure.isClientError {
        return Finding(place: label(for: place), status: .broken, detail: "\(failure)")
    } catch {
        return Finding(place: label(for: place), status: .unreachable, detail: "\(error)")
    }

    try? fetched.data.write(
        to: arguments.savedPagesDirectory.appendingPathComponent("\(place.key).html"))

    do {
        let entry = try await plugin.decodeDeferred(
            fetched.data, mimeType: fetched.mimeType, for: place)

        return Finding(place: label(for: place), status: .healthy, detail: "\(entry)")
    } catch ConditionsFault.unavailable(let readings) {
        return Finding(place: label(for: place), status: .unavailable, detail: readings)
    } catch {
        return Finding(place: label(for: place), status: .broken, detail: "\(error)")
    }
}

do {
    let arguments = try Arguments(CommandLine.arguments)

    try FileManager.default.createDirectory(
        at: arguments.savedPagesDirectory, withIntermediateDirectories: true)

    let encoder = JSONEncoder()
    var anyBroken = false

    for plugin in plugins {
        for place in plugin.places {
            let result = await finding(for: place, plugin: plugin, arguments: arguments)

            print(String(decoding: try encoder.encode(result), as: UTF8.self))

            anyBroken = anyBroken || result.status == .broken
        }
    }

    exit(anyBroken ? 1 : 0)
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(2)
}
