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
        case areaBar
        case pie
    }

    let range: Range<CGFloat>
    let values: [Int]
    let maxValue: Int
    let minValue: Int
    let isSelected: Bool
    let style: Style

    init(range: Range<CGFloat>, values: [Int], maxValue: Int, minValue: Int, isSelected: Bool, style: Style = .area) {
        self.range = range
        self.values = values
        self.maxValue = maxValue
        self.minValue = minValue
        self.isSelected = isSelected
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
    var xOffset: CGFloat = 0

    func updateFrame() {
        self.availbleFrame = CGRect(x: self.xOffset, y: self.offset, width: self.frame.width - self.xOffset * 2, height: self.frame.height - self.offset)
        self.pathLayer.frame = self.availbleFrame
        self.selectedPath.frame = self.availbleFrame
        self.pathLayer.path = self.generatePath(graphContext: self.graphContext, fakeDots: (0, 0))
    }

    typealias FakeDots = (beggining: Int, end: Int)

    func update(graphContext: GraphContext?, animationDuration: TimeInterval, zoom: Zoom?) {
        if animationDuration > 0 {
            var fakeDotsBefore: FakeDots?
            var fakeDotsAfter: FakeDots?
            let oldContext = self.graphContext
            if let zoom = zoom, zoom.style == .basic, let firstGraph = self.graphContext, let secondGraph = graphContext {
                let zoomingIndex = zoom.index
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
        case .bar, .areaBar:
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
        case .pie:
            self.pathLayer.lineWidth = self.availbleFrame.height / 2 - 10
            self.selectedPath.strokeColor = color.cgColor
            self.pathLayer.strokeColor = color.cgColor
            self.pathLayer.fillColor = UIColor.clear.cgColor
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
        case .bar, .areaBar:
            return self.generatePathStack(graphContext: graphContext)
        case .area:
            return self.generatePathOverlay(graphContext: graphContext)
        case .pie:
            return self.generatePathPie(graphContext: graphContext)
        }
    }

    private var cahce: GraphicsDataCache?
    private var stackCache: StackGraphicsDataCache?
    private var overlayCache: OverlayGraphicsDataCache?

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

        if self.cahce == nil || self.cahce?.isThisCache(values: graphContext.values) == false {
            let cache = GraphicsDataCache(values: graphContext.values)
            cache.calculate()
            self.cahce = cache
        }

        guard let cacheValue = self.cahce else {
            return CGMutablePath()
        }

        if fakeDots.beggining < 2 && fakeDots.end < 2 {
            return cacheValue.transform(range: graphContext.range, size: self.availbleFrame.size, max: graphContext.maxValue, min: graphContext.minValue)
        }

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth

        let steps = graphContext.stepsBaseOn(width: fullWidth)
        let path = CGMutablePath()
        var isMoved: Bool = false

        let max = graphContext.maxValue
        let min = graphContext.minValue
        let maxMinDelta = max - min
        let devide = CGFloat(min) / CGFloat(maxMinDelta)

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index]
            let x = steps.pixels * CGFloat(index + 1) - offset
            if x > (-0.1 * self.availbleFrame.width) && x < (self.availbleFrame.width * 1.1) {
                let yPercent = (CGFloat(value) / CGFloat(maxMinDelta)) - devide
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

    private func deg2rad(_ number: CGFloat) -> CGFloat {
        return number * .pi / 180
    }

    func rad2deg(_ number: CGFloat) -> CGFloat {
        return number * 180 / .pi
    }

    func generatePathStack(graphContext: GraphContext?) -> CGPath {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return CGMutablePath()
        }

        if self.stackCache == nil || self.stackCache?.isThisCache(values: graphContext.values) == false {
            let cache = StackGraphicsDataCache(values: graphContext.values)
            cache.calculate()
            self.stackCache = cache
        }

        guard let stackCache = self.stackCache else {
            return CGMutablePath()
        }

        return stackCache.transformStack(range: graphContext.range, size: self.availbleFrame.size, max: graphContext.maxValue)
    }

    func generatePathOverlay(graphContext: GraphContext?) -> CGPath {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return CGMutablePath()
        }

        if self.overlayCache == nil || self.overlayCache?.isThisCache(values: graphContext.values) == false {
            let cache = OverlayGraphicsDataCache(values: graphContext.values)
            cache.calculate()
            self.overlayCache = cache
        }

        guard let overlayCache = self.overlayCache else {
            return CGMutablePath()
        }

        return overlayCache.transformOverlay(range: graphContext.range, size: self.availbleFrame.size, max: graphContext.maxValue)
    }

    func generatePathPie(graphContext: GraphContext?) -> CGPath {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return CGMutablePath()
        }

        var zoomOffset: CGFloat = 0
        if graphContext.isSelected {
            zoomOffset = 10
        }

        func point(degree: CGFloat, radius: CGFloat) -> CGPoint {
            return CGPoint(x: radius * sin(deg2rad(degree)),
                           y: radius * cos(deg2rad(degree)))
        }

        let moveCenterPoint = point(degree: graphContext.range.lowerBound * 360 + graphContext.range.interval / 2 * 360 + 90, radius: zoomOffset)

        let width = self.availbleFrame.width
        let height = self.availbleFrame.height
        let pathHeight = height / 2 - 10

        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: (width - pathHeight) / 2 + moveCenterPoint.x, y: (self.availbleFrame.height - pathHeight) / 2 - moveCenterPoint.y, width: pathHeight, height: pathHeight))
        self.pathLayer.strokeStart = graphContext.range.lowerBound
        self.pathLayer.strokeEnd = graphContext.range.upperBound
        self.pathLayer.lineWidth = pathHeight

        return path
    }

    func sins(degrees: Double) -> Double {
        return __sinpi(degrees / 180.0)
    }

    func sins(degrees: Float) -> Float {
        return __sinpif(degrees / 180.0)
    }

    func sins(degrees: CGFloat) -> CGFloat {
        return CGFloat(sins(degrees: degrees.native))
    }

    func isPieSelected(point: CGPoint, shouldRespectRadius: Bool) -> Bool {
        guard let graphContext = graphContext else {
            return false
        }

        let width = self.availbleFrame.width
        let height = self.availbleFrame.height
        let pathHeight = height / 2 - 10

        let circleCenter = CGPoint(
            x: width / 2,
            y: self.availbleFrame.height / 2 + 14
        )

        let xPositive = point.x - circleCenter.x >= 0
        let yPositive = point.y - circleCenter.y >= 0

        let radius = sqrt(pow(point.x - circleCenter.x, 2) + pow(point.y - circleCenter.y, 2))
        let sinus = (point.x - circleCenter.x) / radius
        var degree = rad2deg(asin(sinus))
        if xPositive && yPositive {
            degree = 180 - degree
        } else if !xPositive && yPositive {
            degree = 180 - degree
        } else if !xPositive && !yPositive {
            degree = 360 + degree
        }

        if shouldRespectRadius, radius > pathHeight {
            return false
        }

        func convertToNew(_ value: CGFloat) -> CGFloat {
            let newValue = (value - 90)
            if newValue < 0 {
                return 360 + newValue
            } else {
                return newValue
            }
        }

        let interval = (graphContext.range.lowerBound * 360)..<(graphContext.range.upperBound * 360)
        return interval.contains(convertToNew(degree))
    }

    func reportPieLabelFrame(graphContext: GraphContext?) -> CGRect {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return .zero
        }

        let width = self.availbleFrame.width
        let height = self.availbleFrame.height
        let pathHeight = height / 2 - 10

        var rect = self.square(radius: pathHeight, startAngle: 360 * graphContext.range.lowerBound + 90, endAngle: 360 * graphContext.range.upperBound + 90)
        rect.origin.x += (width - pathHeight) / 2 + pathHeight / 2
        rect.origin.y += (self.availbleFrame.height - pathHeight) / 2 + pathHeight / 2
        rect.origin.y = height - rect.origin.y - rect.size.height
        return rect
    }

    func rotate(point: CGPoint, aroundPoint: CGPoint, angel: CGFloat) -> CGPoint {
        var oldPoint = point
        let sinus = sin(deg2rad(angel))
        let cosis = cos(deg2rad(angel))

        oldPoint.x -= aroundPoint.x
        oldPoint.y -= aroundPoint.y

        var newPoint: CGPoint = .zero
        newPoint.x = oldPoint.x * cosis + oldPoint.y * sinus
        newPoint.y = oldPoint.y * cosis - oldPoint.x * sinus

        oldPoint.x = newPoint.x + aroundPoint.x
        oldPoint.y = newPoint.y + aroundPoint.y

        return oldPoint
    }

    func square(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) -> CGRect {
        var startAngle = startAngle
        var fullAngel = ((endAngle + 360) - (startAngle + 360))
        if fullAngel > 160 {
            let delta = fullAngel - 160
            fullAngel = 160
            startAngle += delta / 2
        }
        let middleAngle = fullAngel / 2
        func point(degree: CGFloat, radius: CGFloat) -> CGPoint {
            return CGPoint(x: radius * sin(deg2rad(degree)),
                           y: radius * cos(deg2rad(degree)))
        }
        let innerForCircleLineLength = radius * abs(sin(deg2rad(middleAngle)) / sin(deg2rad(middleAngle - 90))) * 2
        let a = sqrt(pow((innerForCircleLineLength / 2), 2) + pow(radius, 2))
        let b = innerForCircleLineLength
        let innerCircleRadius = b / 2 * sqrt((2 * a - b)/(2 * a + b))
        let innerSquareSide = 2 * innerCircleRadius / sqrt(2)
        let pointInsideCircle = point(degree: middleAngle, radius: radius - innerCircleRadius)
        let newPoint = rotate(point: pointInsideCircle, aroundPoint: .zero, angel: startAngle)
        let rect = CGRect(x: newPoint.x - innerSquareSide / 2,
                          y: newPoint.y - innerSquareSide / 2,
                          width: innerSquareSide,
                          height: innerSquareSide)

        return rect
    }

    func generatePathPieZoomed(graphContext: GraphContext?) -> CGPath {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return CGMutablePath()
        }

        let path = CGMutablePath()

        let xOffset = self.availbleFrame.width / 2
        let yOffset = self.availbleFrame.height / 2
        let offset = CGPoint(x: xOffset, y: yOffset)

        let startDegree: CGFloat = round(graphContext.range.lowerBound * 360)
        let endDegree: CGFloat = round(graphContext.range.upperBound * 360)

        let height: CGFloat = self.availbleFrame.height
        let halfHeight = height / 2
        let circleLine = sqrt((pow(halfHeight, 2) * 2)) * 6

        func point(degree: CGFloat, offset: CGPoint) -> CGPoint {
            return CGPoint(x: offset.x + circleLine * sin(deg2rad(degree)),
                           y: offset.y - circleLine * cos(deg2rad(degree)))
        }

        path.move(to: point(degree: startDegree, offset: offset))
        var currentStartDegree = startDegree
        while endDegree > currentStartDegree, endDegree - currentStartDegree > 45 {
            path.addLine(to: point(degree: currentStartDegree, offset: offset))
            currentStartDegree = CGFloat(findNear(value: Int(currentStartDegree), positive: true, devidedBy: 45)) + 1
        }
        path.addLine(to: point(degree: endDegree, offset: offset))
        path.addLine(to: CGPoint(x: xOffset, y: yOffset))


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

        return (newLower, newUpper, step, progress * progress, Int(maxValue))
    }

    private func square(_ x: CGFloat) -> CGFloat {
        return x * x
    }

    private func quadraticEaseOut(_ x: CGFloat) -> CGFloat {
        return -x * (x - 2)
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
        case .graph, .area, .pie:
            return self.selectLine(graphContext: graphContext, selectedPosition: position, animationDuration: animationDuration)
        case .bar, .areaBar:
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
//        let x = steps.pixels * CGFloat(cachedIndex) - offset - (steps.pixels / 2)
        let x = steps.pixels * CGFloat(cachedIndex) - offset
        let yPercent = CGFloat(value) / CGFloat(graphContext.maxValue)
        let y = (1 - yPercent) * self.availbleFrame.height

        let height = (self.availbleFrame.height - y)

        let rect = CGRect(x: x + xOffset, y: self.availbleFrame.height - height + self.offset, width: steps.pixels, height: height)

        return (cachedPosition + xOffset, cachedIndex, cachedHeight, rect)
    }

    func selectLine(graphContext: GraphContext?, selectedPosition: CGFloat, animationDuration: TimeInterval) -> Selection {
        guard let graphContext = graphContext, self.availbleFrame.width > 0 else {
            return (0, 0, 0, nil)
        }

        let position = selectedPosition

        let fullWidth = round(self.availbleFrame.width / graphContext.interval)
        let offset = graphContext.range.lowerBound * fullWidth
        let steps = graphContext.stepsBaseOn(width: fullWidth)

        var delta: CGFloat = 10000
        var cachedPosition: CGFloat = 0
        var cachedHeight: CGFloat = 0
        var cachedYPosition: CGFloat = 0
        var cachedIndex = 0

        let max = graphContext.maxValue
        let min = graphContext.minValue
        let maxMinDelta = max - min
        let devide = CGFloat(min) / CGFloat(maxMinDelta)

        for index in 0..<(graphContext.values.count / steps.points) {
            let value: Int = graphContext.values[index] * steps.points
            let x = round(steps.pixels * CGFloat(index + 1)) - offset
            let yPercent = (CGFloat(value) / CGFloat(maxMinDelta)) - devide

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

        return (cachedPosition + xOffset, cachedIndex, cachedHeight, nil)
    }
}

extension Range where Bound: FloatingPoint {
    var interval: Bound {
        return self.upperBound - self.lowerBound
    }
}

extension Range where Bound == Int {
    var interval: Bound {
        return self.upperBound - self.lowerBound
    }
}

func findNear(value: Int, positive: Bool, devidedBy: Int) -> Int {
    if devidedBy == 0 {
        return 0
    }

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
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}
