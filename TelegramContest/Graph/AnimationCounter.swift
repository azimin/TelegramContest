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

        self.timer = Timer(timeInterval: 1 / 60, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
    }

    @objc
    func fireTimer() {
        self.progress += 1 / 15
        if self.progress >= 1 {
            self.timer?.invalidate()
        }
        let progress = self.quadraticEaseOut(self.progress)
        let delta = self.cachedTo - self.cachedFrom
        self.currentValue = self.cachedFrom + Int(CGFloat(delta) * progress)
        self.block?(self.currentValue)
    }

    func invalidate() {
        self.timer?.invalidate()
    }

    private func quadraticEaseOut(_ x: CGFloat) -> CGFloat {
        return -x * (x - 2)
    }
}
