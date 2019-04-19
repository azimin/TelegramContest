//
//  AnimationCounter.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class AnimationCounter {
    var timer: Timer?
    var currentValue: Int = 0
    private var cachedFrom: Int = 0
    private var cachedTo: Int = 0
    private var progress: CGFloat = 0
    private var block: ((Int) -> Void)?
    private var isQuality: Bool

    init(isQuality: Bool) {
        self.isQuality = isQuality
    }

    func reset() {
        self.cachedFrom = 0
        self.cachedTo = 0
        self.progress = 0
    }

    func animate(from: Int, to: Int, block: @escaping (Int) -> Void) {
        guard to != self.cachedTo, (from - to) != 0 else {
            return
        }

        self.invalidate()
        self.cachedFrom = from
        self.cachedTo = to
        self.progress = 0
        self.block = block

        if isQuality {
            self.timer = Timer(timeInterval: 1 / 60, target: self, selector: #selector(self.fireTimerQuality), userInfo: nil, repeats: true)
        } else {
            self.timer = Timer(timeInterval: 1 / 60, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
        }
        RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
    }

    @objc
    func fireTimer() {
        self.progress += 1 / 15
        if self.progress >= 1 {
            OperationQueue.main.addOperation {
                self.block?(self.cachedTo)
            }
            self.timer?.invalidate()
        }
        let progress = self.quadraticEaseOut(self.progress)
        let delta = self.cachedTo - self.cachedFrom
        self.currentValue = self.cachedFrom + Int(CGFloat(delta) * progress)
        self.block?(self.currentValue)
    }

    @objc
    func fireTimerQuality() {
        self.progress += 1 / 15
        if self.progress >= 1 {
            OperationQueue.main.addOperation {
                self.block?(self.cachedTo)
            }
            self.timer?.invalidate()
        }
        let progress = self.quadraticEaseOut(self.progress)
        let delta = self.cachedTo - self.cachedFrom
        self.currentValue = self.cachedFrom + Int(round(CGFloat(delta) * progress))
        if abs(delta) <= 1 {
            self.block?(self.cachedTo)
            self.timer?.invalidate()
            return
        } else {
            self.block?(self.currentValue)
        }
    }

    func invalidate() {
        self.timer?.invalidate()
    }

    private func quadraticEaseOut(_ x: CGFloat) -> CGFloat {
        return -x * (x - 2)
    }
}


class PairAnimationCounter {
    typealias Pair = (Int, Int)

    var currentValue: Pair = (0, 0)
    private var cachedFrom: Pair = (0, 0)
    private var cachedTo: Pair = (0, 0)
    private var progress: CGFloat = 0
    private var block: ((Pair) -> Void)?

    private var displayLink: CADisplayLink?
    private var startTime = 0.0

    func reset() {
        self.cachedFrom = (0, 0)
        self.cachedTo = (0, 0)
        self.progress = 0
    }

    func animate(from: Pair, to: Pair, block: @escaping (Pair) -> Void) {
        guard to != self.cachedTo, ((from.0 - to.0) != 0 || (from.1 - to.1) != 0) else {
            return
        }

        self.invalidate()
        self.cachedFrom = from
        self.cachedTo = to
        self.progress = 0
        self.block = block

        self.startTime = CACurrentMediaTime()
        self.displayLink = CADisplayLink(target: self, selector: #selector(self.fireTimer))
        self.displayLink?.add(to: .main, forMode: .common)
    }

    @objc
    func fireTimer() {
        var elapsed = CACurrentMediaTime() - self.startTime
        elapsed = min(elapsed, 0.03)
        self.progress += CGFloat(elapsed) * 8
        self.startTime = CACurrentMediaTime()
        if self.progress >= 1 {
            OperationQueue.main.addOperation {
                self.block?(self.cachedTo)
            }
            self.displayLink?.invalidate()
        }
        let progress = self.quadraticEaseOut(self.progress)
        let delta1 = self.cachedTo.0 - self.cachedFrom.0
        let delta2 = self.cachedTo.1 - self.cachedFrom.1
        let currentValue1 = self.cachedFrom.0 + Int(CGFloat(delta1) * progress)
        let currentValue2: Int

        if delta2 != 0 {
             currentValue2 = self.cachedFrom.1 + Int(CGFloat(delta2) * progress)
        } else {
            currentValue2 = self.cachedTo.1
        }

        self.currentValue = (currentValue1, currentValue2)
        self.block?(self.currentValue)
    }

    func invalidate() {
        self.displayLink?.invalidate()
    }

    private func quadraticEaseOut(_ x: CGFloat) -> CGFloat {
        return -x * (x - 2)
    }
}
