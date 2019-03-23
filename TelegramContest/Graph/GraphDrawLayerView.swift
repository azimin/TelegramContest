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
    var isHidding: Bool = false
    var graphContext: GraphContext? {
        didSet {
            self.pathLayer.path = self.generatePath(graphContext: self.graphContext)
        }
    }

    var pathLayer: CAShapeLayer = CAShapeLayer()
    var selectedPath: CAShapeLayer = CAShapeLayer()

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.selectedPath.fillColor = config.backgroundColor.cgColor
        }
    }

    var lineWidth: CGFloat = 2 {
        didSet {
            self.pathLayer.lineWidth = self.lineWidth
        }
    }

    var offset: CGFloat = 0 {
        didSet {
            self.updateFrame()
        }
    }

    init() {
        super.init(frame: .zero)

        self.pathLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: self.frame.width,
            height: self.frame.height
        )
        self.layer.addSublayer(self.pathLayer)
        self.layer.addSublayer(self.selectedPath)

        self.pathLayer.lineJoin = CAShapeLayerLineJoin.bevel
        self.pathLayer.strokeColor = UIColor.red.cgColor
        self.pathLayer.fillColor = UIColor.clear.cgColor
        self.pathLayer.lineWidth = self.lineWidth

        self.selectedPath.fillColor = UIColor.white.cgColor
        self.selectedPath.lineWidth = self.lineWidth
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            if self.frame != oldValue {
                self.updateFrame()
            }
        }
    }

    var availbleFrame: CGRect = .zero

    func updateFrame() {
        self.availbleFrame = CGRect(x: 0, y: self.offset, width: self.frame.width, height: self.frame.height - self.offset)
        self.pathLayer.frame = self.availbleFrame
        self.selectedPath.frame = self.availbleFrame
        self.pathLayer.path = self.generatePath(graphContext: self.graphContext)
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
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return CGMutablePath()
        }

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth

        let steps = graphContext.stepsBaseOn(width: fullWidth)
        let path = CGMutablePath()
        var isMoved: Bool = false

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index] // FIXME
            let x = round(steps.pixels * CGFloat(index)) - offset
            let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)
            if x > (-1.1 * self.availbleFrame.width) && x < (self.availbleFrame.width * 1.1) {
                if !isMoved {
                    path.move(to: CGPoint(x: x, y: (1 - yPercent) * self.availbleFrame.height))
                    isMoved = true
                }
                path.addLine(to: CGPoint(x: x, y: (1 - yPercent) * self.availbleFrame.height))
            }
        }

        return path
    }

    // MARK: Labels

    struct LabelPosition {
        var position: CGFloat
        var index: Int
        var alpha: CGFloat
    }

    private func getValue(baseOn value: Int) -> Int {
        return Int(pow(2, CGFloat(Int(round(log2(CGFloat(value)))))))
    }

    private func findNear(value: Int, step: Int, positive: Bool, devidedBy: Int) -> Int {
        if (value + step) % devidedBy == 0 {
            return value + step
        }
        if positive {
            return findNear(value: value, step: step + 1, positive: positive, devidedBy: devidedBy)
        } else {
            return findNear(value: value, step: step - 1, positive: positive, devidedBy: devidedBy)
        }
    }

    typealias ConverResult = (lower: Int, upper: Int, step: CGFloat, progress: CGFloat)

    private func convert(range: Range<CGFloat>, count: Int, defineLow: Int? = nil, defineUpper: Int? = nil, defineStep: Int? = nil, middleStep: Int? = nil) -> ConverResult {
        let maxValue = pow(2, CGFloat(Int(log2(CGFloat(count)))))
        let step = CGFloat(count) / CGFloat(maxValue)

        let lower = Int((CGFloat(count) * range.lowerBound) / step)
        let upper = Int((CGFloat(count) * range.upperBound) / step)
        let interval = upper - lower

        let value = middleStep ?? getValue(baseOn: interval)
//        let progress = ceil(log2(CGFloat(value))) - log2(CGFloat(interval))

        var newLower = findNear(value: lower, step: 0, positive: false, devidedBy: value)
        if let defineLow = defineLow, let defineStep = defineStep {
            var value: Int = defineLow
            while newLower > value + defineStep {
                value += defineStep
            }
            newLower = value
        }

        let newUpper: Int
        if let middleStep = middleStep {
            newUpper = newLower + middleStep * 2
        } else {
            newUpper = defineUpper ?? findNear(value: upper, step: 0, positive: true, devidedBy: value)
        }

        let anotherProgress = CGFloat(newUpper - upper) / CGFloat(value)

//        let progress = ceil(log2(CGFloat(upper - lower))) - log2(CGFloat(interval))]

        print(newLower, newUpper, anotherProgress)

        return (newLower, newUpper, step, anotherProgress)
    }

    typealias ReportLabelResult = (points: [LabelPosition], step: Int)

    func reportLabelPoints(graphContext: GraphContext?, startingRange: Range<CGFloat>?, zooming: Bool, zoomStep: Int?) -> ReportLabelResult {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return ([], 0)
        }

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let steps = graphContext.stepsBaseOn(width: fullWidth)
        let offset = graphContext.range.lowerBound * fullWidth

        let count = (graphContext.values.count / steps.points)
        let currentPair: ConverResult
        if let startingRange = startingRange {
            let startingPair = self.convert(range: startingRange, count: count)
            let step = (startingPair.upper - startingPair.lower) / 4
            if startingRange.lowerBound == graphContext.range.lowerBound {
                currentPair = self.convert(range: graphContext.range, count: count, defineLow: startingPair.lower)
            } else {
                currentPair = self.convert(range: graphContext.range, count: count, defineUpper: startingPair.upper)
            }
        } else {
            currentPair = self.convert(range: graphContext.range, count: count, middleStep: zoomStep)
        }

        let lower = currentPair.lower
        let upper = currentPair.upper

        let center = (upper - lower) / 2
        let secondLevel = center / 2
        let thirdLevel = secondLevel / 2

        let newValues: [Int]
        if zooming {
            newValues = [lower, lower + thirdLevel, lower + secondLevel, lower + secondLevel + thirdLevel, lower + center, lower + center + thirdLevel, lower + center + secondLevel, lower + center + thirdLevel + secondLevel, upper]
        } else {
            newValues = [lower, lower + secondLevel, lower + center, lower + center + secondLevel, upper, upper + secondLevel, upper + center]
        }
        var indexes = newValues.map({ Int(CGFloat($0) * currentPair.step) })

        for (index, value) in indexes.enumerated() {
            if value == graphContext.values.count {
                indexes[index] = value - 1
            }
        }

        var positivePoints: [(Int, CGFloat)] = []
        for index in 0..<(graphContext.values.count / steps.points) {
            if indexes.contains(index) {
                let x = round(steps.pixels * CGFloat(index)) - offset
                positivePoints.append(((index * steps.points), x))
            }
        }

        var points: [LabelPosition] = []
        for (index, pair) in positivePoints.enumerated() {
            let alpha = (index % 2 == 1) ? currentPair.progress : 1
            let point = LabelPosition(position: pair.1, index: pair.0, alpha: zooming ? alpha : 1)
            points.append(point)
        }

        return (points, currentPair.progress > 0.5 ? secondLevel : center)
    }

    func hidePosition() {
        self.selectedPath.path = nil
    }

    func selectPosition(graphContext: GraphContext?, position: CGFloat, animationDuration: TimeInterval) -> (CGFloat, Int) {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return (0, 0)
        }

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth
        let steps = graphContext.stepsBaseOn(width: fullWidth)

        var delta: CGFloat = 10000
        var cachedPosition: CGFloat = 0
        var cachedYPosition: CGFloat = 0
        var cachedIndex = 0

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index] * steps.points
            let x = round(steps.pixels * CGFloat(index)) - offset
            let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)

            if abs(x - position) < delta {
                delta = abs(x - position)
                cachedPosition = x
                cachedYPosition = (1 - yPercent) * self.availbleFrame.height
                cachedIndex = index * steps.points
            }
        }

        let newPath = UIBezierPath(ovalIn:
            CGRect(x: cachedPosition - 4,
                   y: cachedYPosition - 4,
                   width: 8,
                   height: 8)
            ).cgPath

        if animationDuration > 0, selectedPath.path != nil {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = self.selectedPath.path
            animation.toValue = newPath
            animation.duration = animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.selectedPath.add(animation, forKey: "path")
        }
        self.selectedPath.path = newPath

        return (cachedPosition, cachedIndex)
    }
}

