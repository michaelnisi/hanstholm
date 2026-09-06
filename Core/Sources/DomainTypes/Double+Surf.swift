import Foundation

extension Double {
    public func feet(width: Measurement<UnitLength>.FormatStyle.UnitWidth = .abbreviated) -> String {
        let value = ceil(Measurement<UnitLength>(value: self, unit: .meters).converted(to: .feet).value)
        guard width == .narrow else {
            return Measurement<UnitLength>(value: value, unit: .feet)
                .formatted(.measurement(width: width, usage: .asProvided))
        }
        return "\(Int(value))ft"
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

extension Optional where Wrapped == Double {
    public func knots(width: Measurement<UnitSpeed>.FormatStyle.UnitWidth = .abbreviated) -> String {
        self?.knots(width: width) ?? "–"
    }
}
