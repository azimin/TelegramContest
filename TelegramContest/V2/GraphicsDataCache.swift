//
//  GraphicsDataCache.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 14/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit
import Accelerate

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


    func transform(range: Range<CGFloat>, size: CGSize, max: Int) -> CGPath {
        let fullWidth = round(size.width / range.interval)
        let offset = range.lowerBound * fullWidth

//        let width = size.width

//        let newValues = converValues(values: self.values, range: range, rounded: false)
        let newPoints = converValues(values: self.points, range: range, rounded: false)

//        let newMax = newValues.max() ?? 0
        let xScale = fullWidth / CGFloat(self.points.count)
//        let yScale = CGFloat(newMax) / CGFloat(max)
//        let globalIncrease = CGFloat(newMax) / CGFloat(self.max)

        let path = CGMutablePath()

//        let updatedPoints = self.points.map({ (point) -> CGPoint in
//            let y = point.y / CGFloat(max)
//            return CGPoint(x: (point.x * xScale - offset), y: size.height * (1 - y))
//        })
//        path.addLines(between: updatedPoints)


        let firstTransform = CGAffineTransform(scaleX: xScale, y: (1 / CGFloat(max)))
        let secondTransform = CGAffineTransform(translationX: -offset, y: -1)
        let lastTransform = CGAffineTransform(scaleX: 1, y: -size.height)

        let transform = firstTransform.concatenating(secondTransform).concatenating(lastTransform)
        path.addLines(between: newPoints, transform: transform)

        return path
    }

}
