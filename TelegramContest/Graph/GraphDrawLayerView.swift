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
        case bar
        case area
    }

    let range: Range<CGFloat>
    let values: [Int]
    let maxValue: Int
    let minValue: Int
    let style: Style

    init(range: Range<CGFloat>, values: [Int], maxValue: Int, minValue: Int, style: Style = .area) {
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
            self.pathLayer.path = self.generatePath(graphContext: self.graphContext, fakeDots: (0, 0))
        }
    }

    var pathLayer: CAShapeLayer = CAShapeLayer()
    var selectedPath: CAShapeLayer = CAShapeLayer()

    var color: UIColor = .red {
        didSet {
            self.updateStyle()
        }
    }

    var theme: Theme = .default {
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

        self.pathLayer.lineJoin = CAShapeLayerLineJoin.round
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
        self.pathLayer.path = self.generatePath(graphContext: self.graphContext, fakeDots: (0, 0))
    }

//    var zoomView = UIView()

    func animateZoom() {
//        let snapshotImage = self.takeScreenshot()
//        let snapshotImageView = UIImageView(image: snapshotImage)
//        self.addSubview(snapshotImageView)
//        snapshotImageView.frame = self.bounds
//        snapshotImageView.backgroundColor = UIColor.white
//        UIView.animate(withDuration: 0.25, animations: {
//            snapshotImageView.alpha = 0
//            snapshotImageView.transform = CGAffineTransform.init(scaleX: 3, y: 1)
//        }) { (_) in
//            snapshotImageView.removeFromSuperview()
//        }
    }


//    var counter = AnimationCounter()
//    func transformFrom(point: Int) {
//        guard let graphContext = self.graphContext else {
//            return
//        }
//        let maxValue = 30
//        counter.reset()
//        counter.animate(from: 1, to: maxValue) { (value) in
//            let range = graphContext.range
//            let progress = CGFloat(value) / CGFloat(maxValue)
//            let newInterval = range.interval * (1 - progress)
//            let newRange: Range<CGFloat> = range.lowerBound + (newInterval / 2)..<range.upperBound - (newInterval / 2)
//            let newGraphContext = GraphContext(range: newRange, values: graphContext.values, maxValue: graphContext.maxValue, minValue: graphContext.minValue)
//            self.update(graphContext: newGraphContext, animationDuration: 0)
//        }
////        self.pathLayer.path = self.generatePointGraph(graphContext: self.graphContext, point: point)
////        self.update(graphContext: self.graphContext, animationDuration: 0.5)
//    }

    typealias FakeDots = (beggining: Int, end: Int)

    func update(graphContext: GraphContext?, animationDuration: TimeInterval, zoomingIndex: ZoomIndex?) {
        if animationDuration > 0 {
            var fakeDotsBefore: FakeDots?
            var fakeDotsAfter: FakeDots?
            let oldContext = self.graphContext
            if let zoomingIndex = zoomingIndex, let firstGraph = self.graphContext, let secondGraph = graphContext {
                let index: Int
                let oldGraphContext: GraphContext
                let newGraphContext: GraphContext
                switch zoomingIndex {
                case .inside(let value):
                    index = value
                    oldGraphContext = firstGraph
                    newGraphContext = secondGraph
                case .outside(let value):
                    index = value
                    oldGraphContext = secondGraph
                    newGraphContext = firstGraph
                }
                //  let oldGraphContext = self.graphContext, let newGraphContext = graphContext
                let fullWidth1 = round(self.availbleFrame.width / oldGraphContext.interval)

                let lowerIndex = Int(CGFloat(oldGraphContext.values.count) * oldGraphContext.range.lowerBound)
                let upperIndex = Int(CGFloat(oldGraphContext.values.count) * oldGraphContext.range.upperBound)
                let interval = upperIndex - lowerIndex
                let bottomPercentage = max(CGFloat(index - lowerIndex) / CGFloat(interval), 0)
                let topPercentage = max(CGFloat(upperIndex - index) / CGFloat(interval), 0)

                let steps1 = oldGraphContext.stepsBaseOn(width: fullWidth1)
                let numberOfDots1 = self.availbleFrame.width / steps1.pixels

                let fullWidth2 = round(self.availbleFrame.width / newGraphContext.interval)
                let steps2 = newGraphContext.stepsBaseOn(width: fullWidth2)
                let numberOfDots2 = self.availbleFrame.width / steps2.pixels

                let lowerFakeDots = (Int(CGFloat(numberOfDots1) * bottomPercentage) - Int(numberOfDots2 / 2))
                let upperFakeDots = (Int(CGFloat(numberOfDots1) * topPercentage) - Int(numberOfDots2 / 2))

                switch zoomingIndex {
                case .inside(_):
                    fakeDotsBefore = (-lowerFakeDots, -upperFakeDots)
                    fakeDotsAfter = (lowerFakeDots, upperFakeDots)
                case .outside(_):
                    fakeDotsAfter = (-lowerFakeDots, -upperFakeDots)
                    fakeDotsBefore = (lowerFakeDots, upperFakeDots)
                }
            }

            let animation = CABasicAnimation(keyPath: "path")
            if let fakeDotsBefore = fakeDotsBefore, let fakeDotsAfter = fakeDotsAfter {
                animation.fromValue = self.generatePath(graphContext: oldContext, fakeDots: fakeDotsBefore)
                animation.toValue = self.generatePath(graphContext: graphContext, fakeDots: fakeDotsAfter)
            } else {
                animation.fromValue = self.pathLayer.path
                animation.toValue = self.generatePath(graphContext: graphContext, fakeDots: (0, 0))
            }
            animation.duration = animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.pathLayer.add(animation, forKey: "path")
        }
        self.graphContext = graphContext
        self.updateStyle()
    }

    func updateStyle(graphContext: GraphContext? = nil) {
        switch graphContext?.style ?? self.graphContext?.style ?? .graph {
        case .graph:
            self.pathLayer.lineWidth = self.lineWidth
            self.selectedPath.lineWidth = self.lineWidth
            self.pathLayer.strokeColor = color.cgColor
            self.selectedPath.strokeColor = color.cgColor
            self.pathLayer.fillColor = UIColor.clear.cgColor
            self.pathLayer.lineJoin = CAShapeLayerLineJoin.round
        case .bar:
            self.selectedPath.lineWidth = 0
            self.pathLayer.lineWidth = 0
            self.selectedPath.fillColor = color.cgColor
            self.selectedPath.lineJoin = CAShapeLayerLineJoin.round
            self.pathLayer.fillColor = color.cgColor
            self.pathLayer.lineJoin = CAShapeLayerLineJoin.round
        case .area:
            self.pathLayer.lineWidth = 0
            self.selectedPath.strokeColor = color.cgColor
            self.pathLayer.fillColor = color.cgColor
            self.pathLayer.lineJoin = CAShapeLayerLineJoin.round
        }
    }

    func generateFakePath(count: Int) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -10, y: self.availbleFrame.height / 2))
        path.addLine(to: CGPoint(x: -10, y: self.availbleFrame.height / 2))
        for _ in 0..<count {
            path.addLine(to: CGPoint(x: self.availbleFrame.width / 2, y: self.availbleFrame.height / 2))
        }
        path.addLine(to: CGPoint(x: self.availbleFrame.width + 10, y: self.availbleFrame.height / 2))
        path.addLine(to: CGPoint(x: self.availbleFrame.width + 10, y: self.availbleFrame.height / 2))
        return path
    }

    func generatePath(graphContext: GraphContext?, fakeDots: FakeDots) -> CGPath {
        switch graphContext?.style ?? .graph {
        case .graph:
            return self.generatePathGraph(graphContext: graphContext, fakeDots: fakeDots)
        case .bar:
            return self.generatePathStack(graphContext: graphContext)
        case .area:
            return self.generatePathOverlay(graphContext: graphContext)
        }
    }

    func generatePointGraph(graphContext: GraphContext?, point: Int) -> CGPath {
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
            if x > (-0.1 * self.availbleFrame.width) && x < (self.availbleFrame.width * 1.1) {
                let newValue = graphContext.values[point]
                let newX = steps.pixels * CGFloat(point) - offset
                let newYPercent = CGFloat(newValue) / CGFloat(graphContext.maxValue)
                if !isMoved {
                    path.move(to: CGPoint(x: x, y: (1 - yPercent) * self.availbleFrame.height))
                    isMoved = true
                }
                path.addLine(to: CGPoint(x: newX, y: (1 - newYPercent) * self.availbleFrame.height))
            }
        }

        return path
    }

    func generatePathGraph(graphContext: GraphContext?, fakeDots: FakeDots) -> CGPath {
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
            if x > (-0.1 * self.availbleFrame.width) && x < (self.availbleFrame.width * 1.1) {
                let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)
                if !isMoved {
                    path.move(to: CGPoint(x: x, y: (1 - yPercent) * self.availbleFrame.height))
                    if fakeDots.beggining > 2 {
                        for _ in 0..<fakeDots.beggining {
                            path.addLine(to: CGPoint(x: x, y: (1 - yPercent) * self.availbleFrame.height))
                        }
                    }
                    isMoved = true
                }
                path.addLine(to: CGPoint(x: x, y: (1 - yPercent) * self.availbleFrame.height))
            }
        }


        if fakeDots.end > 2 {
            for _ in 0..<fakeDots.end {
                path.addLine(to: CGPoint(x: self.availbleFrame.width * 1.1, y: self.availbleFrame.height / 2))
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

        var firstPoint: CGPoint = .zero
        var lastPoint: CGPoint = .zero
        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index]
            let x = steps.pixels * CGFloat(index) - offset - (steps.pixels / 2)
            let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)
            let y = round((1 - yPercent) * self.availbleFrame.height)
            if x > (-0.1 * self.availbleFrame.width) && x < (self.availbleFrame.width * 1.1) {
                if !isMoved {
                    path.move(to: CGPoint(x: x, y: y))
                    firstPoint = CGPoint(x: x, y: y)
                    isMoved = true
                }
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + steps.pixels, y: y))
                lastPoint = CGPoint(x: x + steps.pixels, y: y)
            }
        }

        path.addLine(to: CGPoint(x: lastPoint.x, y: self.availbleFrame.height)) // FIXME
        path.addLine(to: CGPoint(x: firstPoint.x, y: self.availbleFrame.height))

        return path
    }

    func generatePathOverlay(graphContext: GraphContext?) -> CGPath {
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
            let y = round((1 - yPercent) * self.availbleFrame.height)
            if x > (-0.1 * self.availbleFrame.width) && x < (self.availbleFrame.width * 1.1) {
                if !isMoved {
                    path.move(to: CGPoint(x: x, y: y))
                    isMoved = true
                }
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.addLine(to: CGPoint(x: 400, y: self.availbleFrame.height)) // FIXME
        path.addLine(to: CGPoint(x: 0, y: self.availbleFrame.height))

        return path
    }

    // MARK: Labels

    struct LabelPosition {
        var position: CGFloat
        var index: Int
        var alpha: CGFloat
    }

    typealias ConverResult = (lower: Int, upper: Int, step: CGFloat, progress: CGFloat, maxValue: Int)

    private func convert(range: Range<CGFloat>, count: Int, middleStep: Int? = nil) -> ConverResult {
        let maxValue = pow(2, CGFloat(Int(log2(CGFloat(count)))))
        let step = CGFloat(count) / maxValue

        let lower = Int((CGFloat(count) * range.lowerBound) / step)
        let upper = Int((CGFloat(count) * range.upperBound) / step)
        let interval = upper - lower

        let value = middleStep ?? Int(pow(2, CGFloat(Int(round(log2(CGFloat(interval)))))))

        let newLower = findNear(value: lower, positive: false, devidedBy: value)
        let newUpper: Int
        if let middleStep = middleStep {
            newUpper = newLower + middleStep * 2
        } else {
            newUpper = findNear(value: upper, positive: true, devidedBy: value)
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
            let offset = findNear(value: Int(space), positive: false, devidedBy: (upper - lower) / 4)

            return (lower + offset, upper + offset, newValues.step, newValues.progress, newValues.maxValue)
        } else {
            let lower = newValues.lower
            let upper = newValues.upper
            let progress = newValues.progress

            let space = (1 - range.upperBound) * CGFloat(newValues.maxValue)
            let offset = findNear(value: Int(space), positive: false, devidedBy: (upper - lower) / 4)

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

    func selectPosition(graphContext: GraphContext?, position: CGFloat, animationDuration: TimeInterval) -> Selection {
        switch self.graphContext?.style ?? .graph {
        case .graph, .area:
            return self.selectLine(graphContext: graphContext, position: position, animationDuration: animationDuration)
        case .bar:
            return self.selectSquare(graphContext: graphContext, position: position, animationDuration: animationDuration)
        }
    }

    typealias Selection = (position: CGFloat, index: Int, height: CGFloat, rect: CGRect?)

    func selectSquare(graphContext: GraphContext?, position: CGFloat, animationDuration: TimeInterval) -> Selection {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return (0, 0, 0, nil)
        }

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth
        let steps = graphContext.stepsBaseOn(width: fullWidth)

        var delta: CGFloat = 10000
        var cachedPosition: CGFloat = 0
        var cachedHeight: CGFloat = 0
        var cachedIndex = 0

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index] * steps.points
            let x = round(steps.pixels * CGFloat(index)) - offset
            let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)

            if abs(x - position) < delta {
                delta = abs(x - position)
                cachedPosition = x
                cachedHeight = yPercent * self.availbleFrame.height
                cachedIndex = index * steps.points
            }
        }

        let value: Int = graphContext.values[cachedIndex]
        let x = steps.pixels * CGFloat(cachedIndex) - offset - (steps.pixels / 2)
        let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)
        let y = round((1 - yPercent) * self.availbleFrame.height)
        let height = (self.availbleFrame.height - y)

        let rect = CGRect(x: x, y: self.availbleFrame.height - height + self.offset, width: steps.pixels, height: height)

        return (cachedPosition, cachedIndex, cachedHeight, rect)
    }

    func selectLine(graphContext: GraphContext?, position: CGFloat, animationDuration: TimeInterval) -> Selection {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return (0, 0, 0, nil)
        }

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth
        let steps = graphContext.stepsBaseOn(width: fullWidth)

        var delta: CGFloat = 10000
        var cachedPosition: CGFloat = 0
        var cachedHeight: CGFloat = 0
        var cachedYPosition: CGFloat = 0
        var cachedIndex = 0

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index] * steps.points
            let x = round(steps.pixels * CGFloat(index)) - offset
            let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)

            if abs(x - position) < delta {
                delta = abs(x - position)
                cachedPosition = x
                cachedHeight = yPercent * self.availbleFrame.height
                cachedYPosition = (1 - yPercent) * self.availbleFrame.height
                cachedIndex = index * steps.points
            }
        }

        if graphContext.style == .graph {
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
        }

        return (cachedPosition, cachedIndex, cachedHeight, nil)
    }
}

extension Range where Bound: FloatingPoint {
    var interval: Bound {
        return self.upperBound - self.lowerBound
    }
}

func findNear(value: Int, positive: Bool, devidedBy: Int) -> Int {
    if value % devidedBy == 0 {
        return value
    }

    if positive {
        return ((value + devidedBy) / devidedBy) * devidedBy
    } else {
        return (value / devidedBy) * devidedBy
    }
}

extension UIColor {
    public var tapButtonChangeColor: UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            // Special formula
            if (red * 300 + green * 590 + blue * 115) / 1000 < 0.3 {
                return self.lighterColorForColor()
            }
        }
        return self.darkerColorForColor()
    }

    private func darkerColorForColor() -> UIColor {
        return self.changeColor(value: -0.2)
    }

    private func lighterColorForColor() -> UIColor {
        return self.changeColor(value: 0.2)
    }

    private func changeColor(value: CGFloat) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + value, 1.0),
                           green: min(green + value, 1.0),
                           blue: min(blue + value, 1.0),
                           alpha: alpha)
        }
        return self
    }
}


extension UIView {

    func takeScreenshot() -> UIImage {

        // Begin context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)

        // Draw view in that context
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)

        // And finally, get image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if (image != nil)
        {
            return image!
        }
        return UIImage()
    }

    func asImage() -> UIImage {
        // FIXME
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            return UIImage()
            // Fallback on earlier versions
        }
    }
}
