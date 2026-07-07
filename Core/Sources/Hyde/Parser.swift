//
//  Parser.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import Foundation
#if os(watchOS)
import WatchKit
#elseif os(iOS)
import SwiftUI
#elseif os(macOS)
import AppKit
#endif

extension Data {
    func string() -> String? {
        String(data: self, encoding: .utf8)
    }

    func parsed() throws -> [String.SubSequence] {
        guard let string = string() else {
            throw Hyde.Fault.parsing
        }

        return try string
            .stripOutHtml()
            .splitLines()
    }
}

extension String {
    func stripOutHtml() throws -> String {
        guard let data = self.data(using: .unicode) else {
            throw Hyde.Fault.parsing
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let attributed = try NSAttributedString(data: data, options: options, documentAttributes: nil)

        return attributed.string
    }

    func splitLines() -> [Self.SubSequence] {
        split(separator: "\n")
    }
}

extension Array where Element == String.SubSequence {

    // MARK: Wave

    func maxWaveHeight() -> Substring? {
        substring(after: "max", within: "Bølger")
    }

    func middleWaveHeight() -> Substring? {
        substring(after: "middel", within: "Bølger")
    }

    func wavePeriod() -> Substring? {
        substring(after: "Bølgeperiode")
    }

    func waveDirection() -> Substring? {
        substring(after: "Bølgeretning")
    }

    // MARK: Wind speed

    func windCurrent() -> Substring? {
        substring(after: "aktuelt", within: "Vindhastighed")
    }

    func windMiddle() -> Substring? {
        substring(after: "middel", within: "Vindhastighed")
    }

    func windGust() -> Substring? {
        substring(after: "vindstød")
    }

    // MARK: Wind direction

    func windDirection() -> Substring? {
        substring(after: "middel", within: "Vindretning")
    }

    // MARK: Lookup

    func substring(after label: Substring, within section: Substring? = nil) -> Substring? {
        let startIndex: Int

        if let section {
            guard let sectionIndex = firstIndex(of: section) else { return nil }
            startIndex = sectionIndex + 1
        } else {
            startIndex = 0
        }

        guard startIndex < count,
              let labelIndex = self[startIndex...].firstIndex(of: label),
              labelIndex + 1 < count else {
            return nil
        }

        return self[labelIndex + 1]
    }
}

private let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: Locale.LanguageCode.danish.identifier)
    return formatter
}()

extension Substring {
    func double() -> Double? {
        // Values include units ("3,88 m", "18,6 m/s") — take the numeric prefix only.
        let numeric = prefix(while: { !$0.isWhitespace })
        guard let number = decimalFormatter.number(from: String(numeric)) else {
            return nil
        }
        return Double(truncating: number)
    }
}
