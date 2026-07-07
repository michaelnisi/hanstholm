//
//  Double+Surf.swift
//  Hanstholm
//
//  Created by Michael Nisi on 01.05.24.
//

import Foundation

extension Double {
    public func feet(width: Measurement<UnitLength>.FormatStyle.UnitWidth = .abbreviated) -> String {
        let converted = Measurement<UnitLength>(value: self, unit: .meters)
            .converted(to: .feet)
        return Measurement<UnitLength>(value: ceil(converted.value), unit: .feet)
            .formatted(.measurement(width: width, usage: .asProvided))
    }
    
    public func seconds(width: Measurement<UnitDuration>.FormatStyle.UnitWidth = .abbreviated) -> String {
        Measurement<UnitDuration>(value: self, unit: .seconds)
            .formatted(.measurement(width: width))
    }
    
    public func knots(width: Measurement<UnitSpeed>.FormatStyle.UnitWidth = .abbreviated) -> String {
        let converted = Measurement<UnitSpeed>(value: self, unit: .metersPerSecond)
            .converted(to: .knots)
        return Measurement<UnitSpeed>(value: ceil(converted.value), unit: .knots)
            .formatted(.measurement(width: width, usage: .asProvided))
    }
}
