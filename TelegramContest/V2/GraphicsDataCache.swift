//
//  GraphicsDataCache.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 14/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphicsDataCache {
    var values: [Int]
    var points: [CGPoint] = []
    var max = 0

    init(values: [Int]) {
        self.values = values
    }

    func isThisCache(values: [Int]) -> Bool {
        return values.count == self.values.count && self.values.first == values.first && self.values.last == values.last
    }

    func calculate() {
        self.max = self.values.max() ?? 0
        for (index, value) in self.values.enumerated() {
            let x = CGFloat(index)
            let point = CGPoint(x: x, y: CGFloat(value))
            self.points.append(point)
        }
    }

    func transform(range: Range<CGFloat>, size: CGSize, max: Int, min: Int) -> CGPath {
        let delta = max - min
        let devide = CGFloat(min) / CGFloat(delta) + 1

        let fullWidth = round(size.width / range.interval)
        let offset = range.lowerBound * fullWidth

        let newRange = (range.lowerBound - 0.1)..<(range.upperBound + 0.1)
        let newPoints = converValues(values: self.points, range: newRange, rounded: false)
        let xScale = fullWidth / CGFloat(self.points.count)

        let path = CGMutablePath()

        let firstTransform = CGAffineTransform(scaleX: xScale, y: (1 / CGFloat(delta)))
        let secondTransform = CGAffineTransform(translationX: -offset, y: -devide)
        let lastTransform = CGAffineTransform(scaleX: 1, y: -size.height)

        let transform = firstTransform.concatenating(secondTransform).concatenating(lastTransform)
        path.addLines(between: newPoints, transform: transform)

        return path
    }

}
