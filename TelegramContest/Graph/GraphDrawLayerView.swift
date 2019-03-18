//
//  GraphDrawLayerView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

struct GraphContext {
    var range: Range<CGFloat>
    var values: [Int]
    var maxValue: Int
    var minValue: Int

    var interval: CGFloat {
        let interval = range.upperBound - range.lowerBound
        return interval
    }

    func stepsBaseOn(width: CGFloat) -> (pixels: CGFloat, points: Int) {
        let point: Int
        let count = self.values.count
        if count > Int(width) {
            point = (count / Int(width)) + 1
        } else {
            point = 1
        }
        let pixels = width / CGFloat(((count) / point) - 1)
        return (pixels, point)
    }
}

class GraphDrawLayerView: UIView {
    var graphContext: GraphContext? {
        didSet {
            self.pathLayer.path = self.generatePath(graphContext: self.graphContext)
        }
    }

    var pathLayer: CAShapeLayer = CAShapeLayer()

    init() {
        super.init(frame: .zero)

        self.pathLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: self.frame.width,
            height: self.frame.height
        )
        self.layer.addSublayer(self.pathLayer)
        self.pathLayer.strokeColor = UIColor.red.cgColor
        self.pathLayer.fillColor = UIColor.clear.cgColor
        self.pathLayer.lineWidth = 2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            if self.frame != oldValue {
                self.pathLayer.frame.size = self.frame.size
                self.pathLayer.path = self.generatePath(graphContext: self.graphContext)
            }
        }
    }

    func update(graphContext: GraphContext?, animationDuration: TimeInterval) {
        if animationDuration > 0 {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = self.pathLayer.path
            animation.toValue = self.generatePath(graphContext: graphContext)
            animation.duration = animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.pathLayer.add(animation, forKey: "path")
        }
        self.graphContext = graphContext
    }

    func generatePath(graphContext: GraphContext?) -> CGPath {
        guard let graphContext = graphContext, self.frame.width > 0 else {
            return CGMutablePath()
        }

        let fullWidth = round(self.frame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth

        let steps = graphContext.stepsBaseOn(width: fullWidth)
        let path = CGMutablePath()

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index] // FIXME
            let x = round(steps.pixels * CGFloat(index)) - offset
            let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: (1 - yPercent) * self.frame.height))
            } else {
                path.addLine(to: CGPoint(x: x, y: (1 - yPercent) * self.frame.height))
            }
        }

        return path
    }

    func reportPoints(graphContext: GraphContext?) -> [(Int, CGFloat)] {
        guard let graphContext = graphContext, self.frame.width > 0 else {
            return []
        }

        let fullWidth = round(self.frame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth
        let numberOfLabels = Int(5 / graphContext.interval)
        let stepOfLabel = (graphContext.values.count / numberOfLabels)

        let steps = graphContext.stepsBaseOn(width: fullWidth)

        var positivePoints: [(Int, CGFloat)] = []
        for index in 0..<(graphContext.values.count / steps.points) {
            if (index * steps.points) % stepOfLabel == 0 {
                let x = round(steps.pixels * CGFloat(index)) - offset
                if x > (-1.5 * self.frame.width) && x < (self.frame.width * 1.5) {
                    positivePoints.append(((index * steps.points), x))
                }
            }
        }

        return positivePoints
    }
}

