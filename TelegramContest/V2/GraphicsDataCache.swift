//
//  GraphicsDataCache.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 14/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit
import Accelerate

class StackGraphicsDataCache {
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
            let anotherPoint = CGPoint(x: x + 1, y: CGFloat(value))
            self.points.append(anotherPoint)
        }
    }

    func transformStack(range: Range<CGFloat>, size: CGSize, max: Int) -> CGPath {
        let fullWidth = round(size.width / range.interval)

        let newRange = (range.lowerBound - 0.1)..<(range.upperBound + 0.1)
        let newPoints = converValues(values: self.points, range: newRange, rounded: false)
        let xScale = fullWidth / CGFloat(self.points.count) * 2
        let offset = range.lowerBound * fullWidth

        let path = CGMutablePath()

        let firstTransform = CGAffineTransform(scaleX: xScale, y: (1 / CGFloat(max)))
        let secondTransform = CGAffineTransform(translationX: -offset, y: -1)
        let lastTransform = CGAffineTransform(scaleX: 1, y: -size.height)

        let transform = firstTransform.concatenating(secondTransform).concatenating(lastTransform)
        path.addLines(between: newPoints, transform: transform)
        let lastPoint = CGPoint(x: (newPoints.last?.x ?? 0) + 1, y: 0)
        let preLastPoint = CGPoint(x: lastPoint.x, y: (newPoints.last?.y ?? 0))
        let firstPoint = CGPoint(x: (newPoints.first?.x ?? 0), y: 0)
        path.addLine(to: preLastPoint, transform: transform)
        path.addLine(to: lastPoint, transform: transform)
        path.addLine(to: firstPoint, transform: transform)

        return path
    }
}

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

        let newPoints = converValues(values: self.points, range: range, rounded: false)
        let xScale = fullWidth / CGFloat(self.points.count)

        let path = CGMutablePath()

        let firstTransform = CGAffineTransform(scaleX: xScale, y: (1 / CGFloat(max)))
        let secondTransform = CGAffineTransform(translationX: -offset, y: -1)
        let lastTransform = CGAffineTransform(scaleX: 1, y: -size.height)

        let transform = firstTransform.concatenating(secondTransform).concatenating(lastTransform)
        path.addLines(between: newPoints, transform: transform)

        return path
    }

}
