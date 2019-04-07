//
//  GraphDrawLayerView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphContext {
    enum Style {
        case graph
        case stack
    }

    let range: Range<CGFloat>
    let values: [Int]
    let maxValue: Int
    let minValue: Int
    let style: Style

    init(range: Range<CGFloat>, values: [Int], maxValue: Int, minValue: Int, style: Style = .graph) {
        self.range = range
        self.values = values
        self.maxValue = maxValue
        self.minValue = minValue
        self.style = style
    }

    var interval: CGFloat {
        let interval = range.upperBound - range.lowerBound
        return interval
    }

    func stepsBaseOn(width: CGFloat) -> (pixels: CGFloat, points: Int) {
        return (width / CGFloat(self.values.count), 1)
//        let point: Int
//        let count = self.values.count
//        if count > Int(width) {
//            point = (count / Int(width)) + 1
//        } else {
//            point = 1
//        }
//        let pixels = width / CGFloat(((count) / point) - 1)
//        return (pixels, point)
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

    var color: UIColor = .red {
        didSet {
            self.updateStyle()
        }
    }

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.selectedPath.fillColor = config.backgroundColor.cgColor
        }
    }

    var lineWidth: CGFloat = 2 {
        didSet {
            self.updateStyle()
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
        self.updateStyle()
    }

    func updateStyle() {
        switch self.graphContext?.style ?? .graph {
        case .graph:
            self.pathLayer.lineWidth = self.lineWidth
            self.pathLayer.strokeColor = color.cgColor
            self.selectedPath.strokeColor = color.cgColor
            self.pathLayer.fillColor = UIColor.clear.cgColor
            self.pathLayer.lineJoin = CAShapeLayerLineJoin.bevel
        case .stack:
            self.pathLayer.lineWidth = 0
            self.selectedPath.strokeColor = color.cgColor
            self.pathLayer.fillColor = color.cgColor
            self.pathLayer.lineJoin = CAShapeLayerLineJoin.miter
        }
    }

    func generatePath(graphContext: GraphContext?) -> CGPath {
        switch self.graphContext?.style ?? .graph {
        case .graph:
            return self.generatePathGraph(graphContext: graphContext)
        case .stack:
            return self.generatePathStack(graphContext: graphContext)
        }
    }

    func generatePathGraph(graphContext: GraphContext?) -> CGPath {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return CGMutablePath()
        }

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth

        let steps = graphContext.stepsBaseOn(width: fullWidth)
        let path = CGMutablePath()
        var isMoved: Bool = false

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index]
            let x = steps.pixels * CGFloat(index) - offset
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

    func generatePathStack(graphContext: GraphContext?) -> CGPath {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return CGMutablePath()
        }

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth

        let steps = graphContext.stepsBaseOn(width: fullWidth)
        let path = CGMutablePath()
        var isMoved: Bool = false

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index]
            let x = steps.pixels * CGFloat(index) - offset - (steps.pixels / 2)
            if index == 5 {
                print(self, offset, steps.pixels, x)
            }
            let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)
            let y = round((1 - yPercent) * self.availbleFrame.height)
            if x > (-1.1 * self.availbleFrame.width) && x < (self.availbleFrame.width * 1.1) {
                if !isMoved {
                    path.move(to: CGPoint(x: x, y: y))
                    isMoved = true
                }
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + steps.pixels, y: y))
            }
        }

        path.addLine(to: CGPoint(x: 400, y: self.availbleFrame.height))
        path.addLine(to: CGPoint(x: 0, y: self.availbleFrame.height))

        return path
    }

    // MARK: Labels

    struct LabelPosition {
        var position: CGFloat
        var index: Int
        var alpha: CGFloat
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

    typealias ConverResult = (lower: Int, upper: Int, step: CGFloat, progress: CGFloat, maxValue: Int)

    private func convert(range: Range<CGFloat>, count: Int, middleStep: Int? = nil) -> ConverResult {
        let maxValue = pow(2, CGFloat(Int(log2(CGFloat(count)))))
        let step = CGFloat(count) / maxValue

        let lower = Int((CGFloat(count) * range.lowerBound) / step)
        let upper = Int((CGFloat(count) * range.upperBound) / step)
        let interval = upper - lower

        let value = middleStep ?? Int(pow(2, CGFloat(Int(round(log2(CGFloat(interval)))))))

        let newLower = findNear(value: lower, step: 0, positive: false, devidedBy: value)
        let newUpper: Int
        if let middleStep = middleStep {
            newUpper = newLower + middleStep * 2
        } else {
            newUpper = findNear(value: upper, step: 0, positive: true, devidedBy: value)
        }

        let progress = (1 - CGFloat(interval) / CGFloat(newUpper - newLower)) * 2

        return (newLower, newUpper, step, progress, Int(maxValue))
    }

    private func converRange(range: Range<CGFloat>, isRight: Bool) -> Range<CGFloat> {
        if isRight {
            return 0..<range.upperBound - range.lowerBound
        } else {
            let lower = 1 - (range.upperBound - range.lowerBound)
            return lower..<1.0
        }
    }

    private func calculateMovement(startRange: Range<CGFloat>, range: Range<CGFloat>, count: Int, isRight: Bool) -> ConverResult {
        let newRange = converRange(range: range, isRight: isRight)
        let newValues = convert(range: newRange, count: count)
        if isRight {
            let lower = newValues.lower
            let upper = newValues.upper

            let space = range.lowerBound * CGFloat(newValues.maxValue)
            let offset = findNear(value: Int(space), step: 0, positive: false, devidedBy: (upper - lower) / 4)

            return (lower + offset, upper + offset, newValues.step, newValues.progress, newValues.maxValue)
        } else {
            let lower = newValues.lower
            let upper = newValues.upper
            let progress = newValues.progress

            let space = (1 - range.upperBound) * CGFloat(newValues.maxValue)
            let offset = findNear(value: Int(space), step: 0, positive: false, devidedBy: (upper - lower) / 4)

            return (lower - offset, upper - offset, newValues.step, progress, newValues.maxValue)
        }
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
            currentPair = self.calculateMovement(startRange: startingRange, range: graphContext.range, count: count, isRight: startingRange.lowerBound == graphContext.range.lowerBound)
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

    // MARK: - Position

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

