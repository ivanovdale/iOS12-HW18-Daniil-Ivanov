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
    private let condition = NSCondition()
    private var elements: [T] = []

    public var count: Int {
        condition.lock()
        let result = elements.count
        condition.unlock()
        return result
    }

    public func enqueue(_ value: T) {
        condition.lock()
        elements.append(value)
        condition.unlock()
    }

    public func dequeue() -> T? {
        condition.lock()
        guard !elements.isEmpty else {
            condition.unlock()
            return nil
        }
        let result = elements.removeFirst()
        condition.unlock()
        return result
    }
}

// MARK: - Data handling threads

final class GenerationThread: Thread {
    private enum Constants {
        static let generationTime = 2
        static let endTime = 20
    }

    private let chipQueueStorage: SafeQueue<Chip>
    private var timer: Timer?
    private var currentTime = 0

    init(chipQueueStorage: SafeQueue<Chip>) {
        self.chipQueueStorage = chipQueueStorage
    }

    override func main() {
        initializeTimer()
        guard let timer else { return }
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run()
    }

    private func initializeTimer() {
        timer = Timer.scheduledTimer(
            withTimeInterval: Double(Constants.generationTime),
            repeats: true
        ) { _ in
            let chip = Chip.make()
            self.chipQueueStorage.enqueue(chip)
            print("Chip \(self.currentTime / 2) was made. Time \(self.currentTime) seconds")

            if self.currentTime == Constants.endTime {
                self.timer?.invalidate()
                self.timer = nil
                print("Generation finished ✅")
                return
            }
            self.currentTime += Constants.generationTime
        }
    }
}

final class WorkThread: Thread {
    private let chipQueueStorage: SafeQueue<Chip>
    private let generationThread: GenerationThread
    private var chipCount = 0

    init(chipQueueStorage: SafeQueue<Chip>, generationThread: GenerationThread) {
        self.chipQueueStorage = chipQueueStorage
        self.generationThread = generationThread
    }

    override func main() {
        while chipQueueStorage.count != 0 || !generationThread.isFinished {
            guard let chip = chipQueueStorage.dequeue() else { continue }
            chip.sodering()
            print("Chip \(chipCount) was soldered")
            chipCount += 1
        }

        print("Soldering finished ✅")
    }
}

// MARK: - Use case

let chipStorage = SafeQueue<Chip>()

let generationThread = GenerationThread(chipQueueStorage: chipStorage)
let workThread = WorkThread(chipQueueStorage: chipStorage, generationThread: generationThread)

generationThread.start()
workThread.start()
