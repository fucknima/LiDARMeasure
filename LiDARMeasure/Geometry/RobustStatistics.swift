import Accelerate
import Foundation

enum RobustStatistics {
    static func median(_ values: [Float]) -> Float? {
        let finite = values.filter(\.isFinite)
        guard !finite.isEmpty else { return nil }
        let sorted = finite.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }

    static func mad(_ values: [Float]) -> Float? {
        guard let median = median(values) else { return nil }
        return median(values.map { abs($0 - median) })
    }

    static func quartiles(_ values: [Float]) -> (q1: Float, q3: Float)? {
        let finite = values.filter(\.isFinite).sorted()
        guard finite.count >= 4 else { return nil }
        let middle = finite.count / 2
        let lower = Array(finite[..<middle])
        let upper = Array(finite[(finite.count + 1) / 2...])
        guard let q1 = median(lower), let q3 = median(upper) else { return nil }
        return (q1, q3)
    }

    static func iqr(_ values: [Float]) -> Float? {
        guard let quartiles = quartiles(values) else { return nil }
        return quartiles.q3 - quartiles.q1
    }

    static func filterByMAD(_ values: [Float], multiplier: Float = 3) -> [Float] {
        guard let center = median(values), let mad = mad(values), mad > .ulpOfOne else {
            return values.filter(\.isFinite)
        }
        let scale = 1.4826 * mad
        return values.filter { $0.isFinite && abs($0 - center) <= multiplier * scale }
    }

    static func filterByIQR(_ values: [Float], multiplier: Float = 1.5) -> [Float] {
        guard let quartiles = quartiles(values) else {
            return values.filter(\.isFinite)
        }
        let range = quartiles.q3 - quartiles.q1
        let lower = quartiles.q1 - multiplier * range
        let upper = quartiles.q3 + multiplier * range
        return values.filter { $0.isFinite && $0 >= lower && $0 <= upper }
    }

    static func mean(_ values: [Float]) -> Float? {
        let finite = values.filter(\.isFinite)
        guard !finite.isEmpty else { return nil }
        var result: Float = 0
        vDSP_meanv(finite, 1, &result, vDSP_Length(finite.count))
        return result
    }
}

