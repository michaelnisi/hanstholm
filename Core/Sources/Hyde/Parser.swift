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
        String(data: self, encoding: .isoLatin1)
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
    func stripOutHtml() throws  -> String {
        guard let data = self.data(using: .unicode) else {
            throw Hyde.Fault.parsing
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] = [
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
    func middleWaveHeight() -> Substring? {
        substring(after: "Middel Bølgehøjde")
    }
    
    func maxWaveHeight() -> Substring? {
        substring(after: "Max Bølgehøjde")
    }
    
    func wavePeriod() -> Substring? {
        substring(after: "Bølgeperiode")
    }
    
    func waveDirection() -> Substring? {
        substring(after: "Bølgeretning")
    }

    func currentDirection() -> Substring? {
        substring(after: "Strømretning")
    }
    
    func windGust() -> Substring? {
        substring(after: "Vindstød")
    }
    
    func windMiddle() -> Substring? {
        substring(after: "Middel vindhastighed")
    }
    
    func windCurrent() -> Substring? {
        substring(after: "Aktuel vindhastighed")
    }
    
    func windDirection() -> Substring? {
        substring(after: "Middel vindretning")
    }
    
    func substring(after label: Substring) -> Substring? {
        guard let labelIndex = firstIndex(of: label) else {
            return nil
        }
        
        let index = labelIndex + 1
        
        return self[index]
    }
}

private let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = NumberFormatter.Style.decimal
    formatter.locale = Locale(identifier: Locale.LanguageCode.danish.identifier)
    
    return formatter
}()

extension Substring {
    func double() -> Double? {
        guard let number = decimalFormatter.number(from: String(self)) else {
            return nil
        }
        
        return Double(truncating: number)
    }
}
