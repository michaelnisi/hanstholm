import Foundation

#if canImport(os)
import os.log

let logger = Logger(subsystem: "ink.codes.Patrol", category: "Hyde")
#else
struct Logger {
    func debug(_ message: String) {}

    func error(_ message: String) {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
    }
}

let logger = Logger()
#endif
