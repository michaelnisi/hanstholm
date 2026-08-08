import Foundation

extension URLSession {
    public static let conditionsDefault: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForResource = 20

        return URLSession(configuration: configuration)
    }()
}
