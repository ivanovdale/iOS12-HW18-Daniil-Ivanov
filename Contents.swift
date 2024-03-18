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

    public func enqueue(_ value: T) {
        mutex.lock()
        elements.append(value)
        mutex.unlock()
    }

    public func dequeue() -> T? {
        mutex.lock()
        guard !elements.isEmpty else {
            return nil
        }
        let result = elements.removeFirst()
        mutex.unlock()
        return result
    }
}

// MARK: - Data handling threads

final class GenerationThread: Thread {
    private enum Constants {
        static let generationTime = 2
        static let endTime = 20
    }

    private let semaphore: DispatchSemaphore
    private let chipQueueStorage: SafeQueue<Chip>
    private var timer: Timer?
    private var currentTime = 0

    init(semaphore: DispatchSemaphore, chipQueueStorage: SafeQueue<Chip>) {
        self.semaphore = semaphore
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
            defer {
                self.semaphore.signal()
            }

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
    private let semaphore: DispatchSemaphore
    private let chipQueueStorage: SafeQueue<Chip>
    private let generationThread: GenerationThread
    private var chipCount = 0

    init(
        semaphore: DispatchSemaphore,
        chipQueueStorage: SafeQueue<Chip>,
        generationThread: GenerationThread
    ) {
        self.semaphore = semaphore
        self.chipQueueStorage = chipQueueStorage
        self.generationThread = generationThread
    }

    override func main() {
        while chipQueueStorage.count != 0 || !generationThread.isFinished {
            semaphore.wait()
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

let semaphore = DispatchSemaphore(value: 0)
let generationThread = GenerationThread(semaphore: semaphore, chipQueueStorage: chipStorage)
let workThread = WorkThread(
    semaphore: semaphore,
    chipQueueStorage: chipStorage,
    generationThread: generationThread
)

generationThread.start()
workThread.start()
