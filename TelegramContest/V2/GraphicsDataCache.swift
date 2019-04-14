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

    func calculate() {
        self.max = self.values.max() ?? 0
        for (index, value) in self.values.enumerated() {
            let x = CGFloat(index)
            let yPercent = CGFloat(value) / CGFloat(self.max)
            let point = CGPoint(x: x, y: (1 - yPercent))
            self.points.append(point)
        }
    }

    func transform(range: Range<CGFloat>, size: CGSize, max: Int) -> CGPath {
        let width = size.width
        let offset = range.lowerBound * CGFloat(self.values.count)

        let newValues = converValues(values: self.values, range: range, rounded: false)
        let newPoints = converValues(values: self.points, range: range, rounded: false)

        let newMax = newValues.max() ?? 0
        var yScale = CGFloat(newMax) / CGFloat(self.max)
        yScale = yScale / (CGFloat(newMax) / CGFloat(max))
        let xScale = width /  CGFloat(newPoints.count)

//        let tansformedPoints = self.tansfromPoints(points: newPoints, xScale: xScale, yScale: yScale, offset: offset, height: size.height)

        let path = CGMutablePath()
        path.addLines(between: newPoints, transform: CGAffineTransform.init(scaleX: xScale, y: yScale * size.height).translatedBy(x: -offset, y: 0))
//        let firstPoint = tansformedPoints[0]
//        path.move(to: firstPoint)
//        for point in tansformedPoints {
//            path.addLine(to: point)
//        }

        return path
    }

    func tansfromPoints(points: [CGPoint], xScale: CGFloat, yScale: CGFloat, offset: CGFloat, height: CGFloat) -> [CGPoint] {
        return points.map({ (point) -> CGPoint in
            return CGPoint(x: (point.x - offset), y: point.y)
        })
    }
}
