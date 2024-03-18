import Foundation

// MARK: - Data

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }

    public let chipType: ChipType

    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }

        return Chip(chipType: chipType)
    }

    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
    }
}

// MARK: - Data storage

public final class SafeQueue<T> {
    private let mutex = NSLock()

    private var elements: [T] = []

    public var count: Int {
        mutex.lock()
        let result = elements.count
        mutex.unlock()
        return result
    }

    func enqueue(_ value: T) {
        mutex.lock()
        elements.append(value)
        mutex.unlock()
    }

    func dequeue() -> T? {
        mutex.lock()
        guard !elements.isEmpty else {
            return nil
        }
        let result = elements.removeFirst()
        mutex.unlock()
        return result
    }
}
