//
//  OverlayGraphicsDataCache.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 15/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class OverlayGraphicsDataCache {
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

    func transformOverlay(range: Range<CGFloat>, size: CGSize, max: Int) -> CGPath {
        //        let steps = graphContext.stepsBaseOn(width: fullWidth)
        //        let path = CGMutablePath()
        //        var isMoved: Bool = false
        //
        //        var lastPoint: CGPoint = .zero
        //        for index in 0..<(graphContext.values.count / steps.points) {
        //            let value: Int = graphContext.values[index]
        //            let x = steps.pixels * CGFloat(index) - offset
        //            let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)
        //            let y = (1 - yPercent) * self.availbleFrame.height
        //            if x > (-0.1 * self.availbleFrame.width) && x < (self.availbleFrame.width * 1.1) {
        //                if !isMoved {
        //                    path.move(to: CGPoint(x: x, y: y))
        //                    if fakeDots.beggining > 2 {
        //                        for _ in 0..<fakeDots.beggining {
        //                            path.move(to: CGPoint(x: x, y: y))
        //                        }
        //                    }
        //                    isMoved = true
        //                }
        //                path.addLine(to: CGPoint(x: x, y: y))
        //                lastPoint = CGPoint(x: x, y: y)
        //            }
        //        }
        //
        //        if fakeDots.end > 2 {
        //            for _ in 0..<fakeDots.end {
        //                path.addLine(to: CGPoint(x: lastPoint.x, y: self.availbleFrame.height))
        //            }
        //        }
        //
        //        path.addLine(to: CGPoint(x: lastPoint.x, y: self.availbleFrame.height))
        //        path.addLine(to: CGPoint(x: 0, y: self.availbleFrame.height))
        //
        //        return path

        let fullWidth = round(size.width / range.interval)

        let newRange = (range.lowerBound - 0.1)..<(range.upperBound + 0.1)
        var newPoints = converValues(values: self.points, range: newRange, rounded: false)
        let xScale = fullWidth / CGFloat(self.points.count)
        let offset = range.lowerBound * fullWidth

        let path = CGMutablePath()

        let firstTransform = CGAffineTransform(scaleX: xScale, y: (1 / CGFloat(max)))
        let secondTransform = CGAffineTransform(translationX: -offset, y: -1)
        let lastTransform = CGAffineTransform(scaleX: 1, y: -size.height)

        let transform = firstTransform.concatenating(secondTransform).concatenating(lastTransform)
        let lastPoint = CGPoint(x: (newPoints.last?.x ?? 0), y: 0)
        let preLastPoint = CGPoint(x: lastPoint.x, y: (newPoints.last?.y ?? 0))
        let firstPoint = CGPoint(x: (newPoints.first?.x ?? 0), y: 0)

        newPoints.append(preLastPoint)
        newPoints.append(lastPoint)
        newPoints.append(firstPoint)

        path.addLines(between: newPoints, transform: transform)

        return path
    }
}
