import Foundation

struct MeasurementSmoother {
    let windowSize: Int
    let relativeTolerance: Float
    let stableFrameCount: Int

    private(set) var samples: [MeasurementDimensions] = []
    private(set) var consecutiveStableFrames = 0

    init(windowSize: Int = 15, relativeTolerance: Float = 0.02, stableFrameCount: Int = 5) {
        self.windowSize = max(3, windowSize)
        self.relativeTolerance = relativeTolerance
        self.stableFrameCount = max(1, stableFrameCount)
    }

    mutating func add(_ value: MeasurementDimensions) -> MeasurementDimensions? {
        guard value.isValid else { return current }
        samples.append(value)
        if samples.count > windowSize { samples.removeFirst(samples.count - windowSize) }

        guard let result = current else { return value }
        let change = Self.relativeChange(from: result, to: value)
        if change < relativeTolerance { consecutiveStableFrames += 1 }
        else { consecutiveStableFrames = 0 }
        return result
    }

    var current: MeasurementDimensions? {
        guard !samples.isEmpty else { return nil }
        return MeasurementDimensions(
            width: RobustStatistics.median(samples.map(\.width)) ?? 0,
            height: RobustStatistics.median(samples.map(\.height)) ?? 0,
            depth: RobustStatistics.median(samples.map(\.depth)) ?? 0
        )
    }

    var isStable: Bool { consecutiveStableFrames >= stableFrameCount && samples.count >= stableFrameCount }

    var stabilityScore: Float {
        guard samples.count >= 2, let current else { return 0 }
        let changes = samples.dropLast().map { Self.relativeChange(from: current, to: $0) }
        let mean = RobustStatistics.mean(changes) ?? 1
        return max(0, min(1, 1 - mean / max(relativeTolerance, .ulpOfOne)))
    }

    mutating func reset() {
        samples.removeAll(keepingCapacity: true)
        consecutiveStableFrames = 0
    }

    static func relativeChange(from old: MeasurementDimensions, to new: MeasurementDimensions) -> Float {
        let oldVector = [old.width, old.height, old.depth]
        let newVector = [new.width, new.height, new.depth]
        return zip(oldVector, newVector).map { old, new in
            abs(new - old) / max(abs(old), 0.001)
        }.max() ?? 0
    }
}

