//
//  Double+Surf.swift
//  Hanstholm
//
//  Created by Michael Nisi on 01.05.24.
//

import Foundation

extension Double {
    public func meters(width: Measurement<UnitLength>.FormatStyle.UnitWidth = .abbreviated) -> String {
        Measurement<UnitLength>(value: self, unit: .meters)
            .formatted(.measurement(width: width))
    }
    
    public func seconds(width: Measurement<UnitDuration>.FormatStyle.UnitWidth = .abbreviated) -> String {
        Measurement<UnitDuration>(value: self, unit: .seconds)
            .formatted(.measurement(width: width))
    }
    
    public func metersPerSecond(width: Measurement<UnitSpeed>.FormatStyle.UnitWidth = .abbreviated) -> String {
        Measurement<UnitSpeed>(value: self, unit: .metersPerSecond)
            .formatted(.measurement(width: width))
    }
}
