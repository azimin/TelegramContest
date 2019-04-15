//
//  ThresholdOptimization.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 20/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ThresholdOptimization {
    static let memorySize: MemorySize = MemorySize.current

    enum MemorySize {
        case low, medium, high

        static var current: MemorySize {
            if ProcessInfo.processInfo.physicalMemory < 838860800 {
                return .low
            } else if ProcessInfo.processInfo.physicalMemory < 1572864000 {
                return .medium
            } else {
                return .high
            }
        }

        var isImmidiate: Bool {
            return self == .high
        }
    }

    private var action: (() -> Void)?
    private var startTime = 0.0
    private var displayLink: CADisplayLink?
    private let memorySize = MemorySize.current

    let elapsedTime: TimeInterval
    init(elapsedTime: TimeInterval) {
        self.elapsedTime = elapsedTime
    }

    func update(with action: @escaping () -> Void) {
        if self.memorySize.isImmidiate {
            action()
            return
        }

        self.action = {
            action()
            self.cancel()
        }

        if displayLink == nil {
            self.startTime = CACurrentMediaTime()
            self.displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidFire(_:)))
            self.displayLink?.add(to: .main, forMode: .common)
        }
    }

    func cancel() {
        self.action = nil
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    @objc
    func displayLinkDidFire(_ displayLink: CADisplayLink) {
        let elapsed = CACurrentMediaTime() - self.startTime
        var elapsedSpeed = self.elapsedTime

        switch self.memorySize {
        case .low:
            break
        case .medium:
            elapsedSpeed /= 2
        case .high:
            elapsedSpeed /= 4
        }

        if elapsed > self.elapsedTime {
            OperationQueue.main.addOperation {
                self.action?()
            }
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
    }
}
