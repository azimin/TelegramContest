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

    func animate(from: Int, to: Int, block: @escaping (Int) -> Void) {
        guard to != self.cachedTo, (from - to) != 0 else {
            return
        }

        self.invalidate()
        self.cachedFrom = from
        self.cachedTo = to
        self.progress = 0

        self.timer = Timer(timeInterval: 1 / 60, repeats: true, block: { (_) in
            self.progress += 1 / 15
            if self.progress >= 1 {
                self.timer?.invalidate()
            }
            let progress = self.quadraticEaseOut(self.progress)
            let delta = self.cachedTo - self.cachedFrom
            self.currentValue = self.cachedFrom + Int(CGFloat(delta) * progress)
            block(self.currentValue)
        })
        RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
    }

    func invalidate() {
        self.timer?.invalidate()
    }

    private func quadraticEaseOut(_ x: CGFloat) -> CGFloat {
        return -x * (x - 2)
    }
}
