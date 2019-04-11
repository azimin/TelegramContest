//
//  GraphContentView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

typealias SelectIndexAction = (_ index: Int) -> Void

class GraphContentView: UIView {
    private enum Constants {
        static var aniamtionDuration: TimeInterval = 0.2
        static var labelsHeight: CGFloat = 26
        static var offset: CGFloat = 16
    }

    private(set) var dataSource: GraphDataSource?
    private var transformedValues: [[Int]] = []
    private var coeficent: CGFloat?

    var style: GraphStyle = .basic
    var zoomed: Bool = false
    var oneDayInterval: Bool = false

    var zoomAction: SelectIndexAction? {
        didSet {
            self.selectionPlateView.tapAction = self.zoomAction
        }
    }

    func visibleRowValues(dataSource: GraphDataSource?, values: [Int]) -> [[Int]] {
        guard let dataSource = dataSource else {
            return []
        }
        var newValues: [[Int]] = []
        for (index, row) in dataSource.yRows.enumerated() {
            if values.contains(index) {
                newValues.append(row.values)
            }
        }
        return newValues
    }

    private var selectionAvailable: Bool = true

    func updateDataSouce(_ dataSource: GraphDataSource?, enableRows: [Int], animated: Bool, zoom: Zoom?, zoomed: Bool) {
        self.dataSource = dataSource
        self.style = dataSource?.style ?? self.style
        self.zoomed = zoomed
        self.preveous = .zero
        self.currentMaxValue = 0
        self.enabledRows = enableRows

        self.updatePieSelectedRange(force: true)

        if self.style == .doubleCompare {
            self.yAxisLabelOverlay.labelOverrideColor = self.dataSource?.yRows.first?.color
            self.secondYAxisLabelOverlay.labelOverrideColor = self.dataSource?.yRows.last?.color
            self.insertSubview(self.secondYAxisLabelOverlay, aboveSubview: self.yAxisLabelOverlay)
            self.yAxisOverlays.append(self.secondYAxisLabelOverlay)
        } else {
            self.yAxisLabelOverlay.labelOverrideColor = nil
            self.yAxisLabelOverlay.isHidden = false
            if let index = self.yAxisOverlays.firstIndex(of: self.secondYAxisLabelOverlay) {
                self.secondYAxisLabelOverlay.isHidden = true
                self.yAxisOverlays.remove(at: index)
            }
        }

        if self.style == .stackedBar || self.dataSource?.yRows.first?.style == .bar {
            self.selectionLineView.isHidden = true
        } else {
            self.selectionLineView.isHidden = false
        }

        if self.dataSource?.yRows.first?.style == .pie {
            self.selectionAvailable = false
        } else {
            self.selectionAvailable = true
        }

        self.updateTansformer()
        self.hideSelection()
        self.update(animated: animated, zoom: zoom)
    }

    func updateTansformer() {
        let transformer = Transformer(rows: dataSource?.yRows.map({ $0.values }) ?? [], visibleRows: self.enabledRows, style: style.transformerStyle)
        self.transformedValues = transformer.values
        self.coeficent = transformer.coeficent
    }

    private(set) var selectedRange: Range<CGFloat>
    private var pieChartSelectedRange: Range<Int> = 0..<1
    private var pieChartSumValue: Int = 1
    private var shouldUpdatePieChart: Bool = false

    func updateSelectedRange(_ selectedRange: Range<CGFloat>, shouldDraw: Bool) {
        self.selectedRange = selectedRange
        self.hideSelection()

        self.updatePieSelectedRange(force: false)

        if shouldDraw {
            self.update(animated: false, zoom: nil)
        }
    }

    func updatePieSelectedRange(force: Bool) {
        guard self.style == .pie, let dataSource = self.dataSource else {
            return
        }

        let count = dataSource.xRow.dateStrings.count
        let lowValue = Int(round(CGFloat(count) * self.selectedRange.lowerBound))
        let upperValue = Int(round(CGFloat(count) * self.selectedRange.upperBound))
        let range = lowValue..<upperValue
        print(range)
        if !force && pieChartSelectedRange == range {
            return
        }

        self.pieChartSelectedRange = range

        var sumValue: Int = 0
        for (index, yRow) in dataSource.yRows.enumerated() {
            if enabledRows.contains(index) {
                sumValue += converValues(values: yRow.values, range: self.selectedRange, rounded: true).reduce(0, { $0 + $1 })
            }
        }
        self.shouldUpdatePieChart = true
        self.pieChartSumValue = max(sumValue, 1)
    }

    var isMovingZoomMode: Bool = false {
        didSet {
            if oldValue != isMovingZoomMode {
                self.updateZoomingStatus()
            }
        }
    }
    private var cachedRange: Range<CGFloat>?

    private func updateZoomingStatus() {
        if self.isMovingZoomMode {
            self.cachedRange = self.selectedRange
        } else {
            self.cachedRange = nil
            self.dateLabels.finishTransision()
        }
    }

    private var enabledRows: [Int] = []
    private var currentMaxValue: Int = 0

    func updateEnabledRows(_ values: [Int], animated: Bool) {
        self.preveous = .zero
        self.enabledRows = values

        self.updateTansformer()
        self.updatePieSelectedRange(force: true)

        self.update(animated: animated, force: true, zoom: nil)

        if let selection = self.selectedLocation {
            self.showSelection(location: selection, animated: animated, shouldRespectCahce: false)
        }
    }

    private var graphDrawLayers: [GraphDrawLayerView] = []
    private var counter: AnimationCounter = AnimationCounter()
    private var dateLabels = ViewsOverlayView()
    private var yAxisLineOverlay = YAxisOverlayView(style: .line)
    private var yAxisLabelOverlay = YAxisOverlayView(style: .label)
    private var secondYAxisLabelOverlay = YAxisOverlayView(style: .labelRight)
    private lazy var yAxisOverlays = [yAxisLineOverlay, yAxisLabelOverlay]
    private var selectionPlateView = DateSelectionView(style: .plate)
    private var selectionLineView = DateSelectionView(style: .line)
    private lazy var selectionViews = [selectionPlateView, selectionLineView]
    private var lastVisible: GraphDrawLayerView?
    private var shadowImage = UIImageView(frame: .zero)
    private var shadowCachedSize: CGRect = .zero
    private var graphSelectionOverlayView: GraphSelectionOverlayView = GraphSelectionOverlayView()
    private var graphView = UIView()

    var updatedZoomStep: ((Int?) -> Void)?

    private var zoomStep: Int? = nil
    func updateZoomStep(newValue: Int?, override: Bool) {
        self.zoomStep = newValue
        if override {
            self.updatedZoomStep?(newValue)
        }
    }

    init(dataSource: GraphDataSource? = nil, selectedRange: Range<CGFloat> = 0..<1) {
        self.dataSource = dataSource
        self.selectedRange = selectedRange
        super.init(frame: .zero)
        self.setup()
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

    private var preveous: CGRect = .zero

    private func updateFrame() {
        guard self.frame != preveous else {
            return
        }
        self.preveous = self.frame

        let graphHeight = self.frame.height - Constants.labelsHeight - 20
        let topFrame = CGRect(x: Constants.offset, y: 20, width: self.frame.size.width - Constants.offset * 2, height: graphHeight)
        let graphFrame = CGRect(x: Constants.offset, y: 0, width: self.frame.size.width - Constants.offset * 2, height: graphHeight + 20)
        self.graphView.frame = graphFrame
//        self.graphDrawLayers.forEach({ $0.frame = graphFrame })
        self.graphSelectionOverlayView.frame = graphFrame
        self.yAxisOverlays.forEach({ $0.frame = topFrame })
        self.secondYAxisLabelOverlay.frame = topFrame
        self.dateLabels.frame = CGRect(x: Constants.offset, y: graphHeight + 20, width: self.frame.size.width - Constants.offset * 2, height: Constants.labelsHeight)
        self.selectionViews.forEach({ $0.frame = CGRect(x: Constants.offset, y: 6, width: self.frame.size.width - Constants.offset * 2, height: graphHeight + 8) })
        self.graphDrawLayers.forEach({ $0.offset = 20 })
        self.updateShadow()
        self.updateHierarhy()
    }

    var theme: Theme = .default {
        didSet {
            let config = theme.configuration
            self.backgroundColor = config.backgroundColor
            self.graphDrawLayers.forEach({ $0.theme = theme })
            self.selectionViews.forEach({ $0.theme = theme })
            self.yAxisOverlays.forEach({ $0.theme = theme })
            self.dateLabels.theme = theme
            self.shadowCachedSize = .zero
            self.updateShadow()
            self.graphSelectionOverlayView.overlayerLayer.backgroundColor = config.backgroundColor.withAlphaComponent(0.4).cgColor
        }
    }

    private func updateShadow() {
        let shadowFrame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: 20)
        guard self.shadowCachedSize != shadowFrame else {
            return
        }
        let config = self.theme.configuration
        self.shadowCachedSize = shadowFrame
        self.shadowImage.frame = shadowFrame
        self.shadowImage.image = UIImage(size: shadowFrame.size, gradientColor: [config.backgroundColor, config.backgroundColor.withAlphaComponent(0)])
    }

    private func setup() {
        self.yAxisOverlays.forEach({ $0.layer.masksToBounds = true })
        self.secondYAxisLabelOverlay.layer.masksToBounds = true
        self.addSubview(self.dateLabels)
        self.addSubview(self.yAxisLineOverlay)
        self.addSubview(self.selectionLineView)
        self.graphView.layer.masksToBounds = true
        self.addSubview(self.graphView)
        self.addSubview(self.yAxisLabelOverlay)
        self.addSubview(self.shadowImage)
        self.addSubview(self.graphSelectionOverlayView)
        self.graphSelectionOverlayView.layer.masksToBounds = true
        self.addSubview(self.selectionPlateView)

        self.selectionPlateView.closeAction = {
            self.hideSelection()
        }
    }

    var linePositionAbove = false

    func updateHierarhy() {
        let newLinePositionAbove = (self.style == .percentStackedBar || self.style == .stackedBar)
        guard newLinePositionAbove != self.linePositionAbove else {
            return
        }
        self.linePositionAbove = newLinePositionAbove
        if newLinePositionAbove {
            self.insertSubview(self.yAxisLineOverlay, aboveSubview: self.yAxisLabelOverlay)
            self.insertSubview(self.selectionLineView, aboveSubview: self.yAxisLabelOverlay)
        } else {
            self.insertSubview(self.yAxisLineOverlay, belowSubview: self.dateLabels)
            self.insertSubview(self.selectionLineView, aboveSubview: self.dateLabels)
        }
    }

    private func update(animated: Bool, force: Bool = false, zoom: Zoom?) {
        var animated = animated

        guard let dataSource = self.dataSource else {
            self.graphDrawLayers.forEach({ $0.isHidden = true })
            return
        }

        if !self.shouldUpdatePieChart, self.style == .pie {
            return
        }
        self.shouldUpdatePieChart = false
        if self.style == .pie {
            animated = true
        }

        while graphDrawLayers.count < dataSource.yRows.count {
            let graphView = GraphDrawLayerView()
//            graphView.layer.masksToBounds = true
            graphView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - Constants.labelsHeight)
            if let lates = self.graphDrawLayers.last {
                self.graphView.insertSubview(graphView, belowSubview: lates)
            } else {
                self.graphView.addSubview(graphView)
//                self.insertSubview(graphView, belowSubview: self.yAxisLabelOverlay)
            }
            self.graphDrawLayers.append(graphView)
        }

        while graphDrawLayers.count > dataSource.yRows.count {
            let layer = self.graphDrawLayers.removeLast()
            layer.removeFromSuperview()
        }

        var maxValue = 0
        var minValue = 0

        for index in 0..<self.graphDrawLayers.count {
            if enabledRows.contains(index) {
                let values = self.converValues(values: self.transformedValues[index], range: self.selectedRange, rounded: false)
                let max = values.max() ?? 0
                let min = values.min() ?? 0

                if max > maxValue {
                    maxValue = max
                }

                if min < minValue {
                    minValue = min
                }
            }
        }
        if maxValue == 0 {
            if let max = self.lastVisible?.graphContext?.maxValue {
                maxValue = max
            } else {
                maxValue = 1
            }
        }

        let updateYAxis: (_ maxValue: Int, _ animated: Bool) -> Void = { (maxValue, animated) in
            for yAxis in self.yAxisOverlays {
                switch yAxis.style {
                case .label, .line:
                    yAxis.update(value: maxValue, animated: animated)
                case .labelRight:
                    yAxis.update(value: Int(CGFloat(maxValue) / (self.coeficent ?? 1)), animated: animated)
                }
            }
        }

        if force {
            self.currentMaxValue = maxValue
            updateYAxis(maxValue, animated)
        }

        if self.currentMaxValue == 0 || animated {
            self.currentMaxValue = maxValue
            updateYAxis(maxValue, animated)
        } else {
            self.counter.animate(from: self.currentMaxValue, to: maxValue) { (value) in
                self.currentMaxValue = value
                self.update(animated: false, zoom: nil)
            }
            updateYAxis(maxValue, true)
        }

        var imageBefore: UIImage? = nil
        if let zoom = zoom, animated, zoom.style == .zooming {
            imageBefore = self.graphView.asImage()
        }

        var anyPoints: [GraphDrawLayerView.LabelPosition] = []
        var startingRange: CGFloat = 0
        for index in 0..<self.graphDrawLayers.count {
            let graphView = self.graphDrawLayers[index]
            let isHidden = !enabledRows.contains(index)
            let shouldUpdateOpacity = graphView.isHidden != isHidden
            graphView.isHidding = isHidden

            if !isHidden {
                graphView.isHidden = isHidden
            }

            if animated && shouldUpdateOpacity {
                graphView.alpha = isHidden ? 1 : 0
                UIView.animate(withDuration: Constants.aniamtionDuration, animations: {
                    graphView.alpha = isHidden ? 0 : 1
                }) { (success) in
                    if success, isHidden {
                        graphView.isHidden = isHidden
                    }
                }
            } else {
                graphView.isHidden = isHidden
                graphView.alpha = isHidden ? 0 : 1
            }

            let yRow = dataSource.yRows[index]
            let range: Range<CGFloat>
            if yRow.style == .pie {
                let sumValue = CGFloat(self.converValues(values: yRow.values, range: self.selectedRange, rounded: true).reduce(0, { $0 + $1 }))
                let delta = sumValue / CGFloat(self.pieChartSumValue)
                if !isHidden {
                    range = startingRange..<(startingRange + delta)
                    startingRange += delta
                } else {
                    range = startingRange..<startingRange + 0.001
                }
            } else {
                range = self.selectedRange
            }

            let context = GraphContext(
                range: range,
                values: self.transformedValues[index],
                maxValue: self.currentMaxValue,
                minValue: minValue,
                style: yRow.style
            )
            graphView.update(graphContext: context, animationDuration: animated ? Constants.aniamtionDuration : 0, zoom: zoom)
            graphView.color = yRow.color

            if anyPoints.isEmpty && yRow.style != .pie {
                let zoomingForThisStep = zoom != nil
                let zooming = zoomingForThisStep || self.isMovingZoomMode
                let startingRange  = zoomingForThisStep ? self.selectedRange : self.cachedRange
                let pair = graphView.reportLabelPoints(graphContext: context, startingRange: startingRange, zooming: zooming, zoomStep: self.zoomStep)
                anyPoints = pair.points
                
                if zooming {
                    self.updateZoomStep(newValue: pair.step, override: true)
                }
            }

            if !graphView.isHidding {
                self.lastVisible = graphView
            }
        }

        var items: [ViewsOverlayView.Item] = []
        for point in anyPoints {
            let xRow = dataSource.xRow.dateStrings[point.index]
            let corner: ViewsOverlayView.Item.Corner
            switch point.index {
            case 0:
                corner = .left
            case dataSource.xRow.dateStrings.count - 1:
                corner = .right
            default:
                corner = .none
            }
            let item = ViewsOverlayView.Item(text: xRow, position: point.position, alpha: point.alpha, corner: corner)
            items.append(item)
        }
        self.dateLabels.showItems(items: items)
        self.updateFrame()

        if self.style == .doubleCompare {
            if dataSource.yRows.count == 2 {
                if self.enabledRows.contains(0) {
                    self.yAxisLabelOverlay.isHidden = false
                } else {
                    self.yAxisLabelOverlay.isHidden = true
                }

                if self.enabledRows.contains(1) {
                    self.secondYAxisLabelOverlay.isHidden = false
                } else {
                    self.secondYAxisLabelOverlay.isHidden = true
                }
            }
        }

        if let zoom = zoom, animated, zoom.style == .zooming {
            let imageAfter = graphView.asImage()
            switch zoom.index {
            case .inside(_):
                self.animateZoom(imageBefore: imageBefore ?? UIImage(), imageAfter: imageAfter, reversed: false)
            case .outside(_):
                self.animateZoom(imageBefore: imageAfter, imageAfter: imageBefore ?? UIImage(), reversed: true)
            }
        }

    }

    func animateZoom(imageBefore: UIImage, imageAfter: UIImage, reversed: Bool) {
        let whiteView = UIView()
        whiteView.frame = self.graphView.frame
        whiteView.backgroundColor = UIColor.white
        self.insertSubview(whiteView, aboveSubview: self.graphView)

        let snapshotImageAfterView = UIImageView(image: imageAfter)
        let snapshotImageBeforeView = UIImageView(image: imageBefore)

        if reversed {
//            self.insertSubview(snapshotImageBeforeView, aboveSubview: whiteView)
//            self.insertSubview(snapshotImageAfterView, aboveSubview: snapshotImageBeforeView)
            self.insertSubview(snapshotImageAfterView, aboveSubview: whiteView)
            self.insertSubview(snapshotImageBeforeView, aboveSubview: snapshotImageAfterView)
        } else {
            self.insertSubview(snapshotImageAfterView, aboveSubview: whiteView)
            self.insertSubview(snapshotImageBeforeView, aboveSubview: snapshotImageAfterView)
        }

        snapshotImageBeforeView.frame = self.graphView.frame
        snapshotImageAfterView.frame = self.graphView.frame
        snapshotImageBeforeView.backgroundColor = UIColor.white
        snapshotImageAfterView.backgroundColor = UIColor.white

        if reversed {
            snapshotImageBeforeView.alpha = 0
            snapshotImageBeforeView.transform = CGAffineTransform.init(scaleX: 3, y: 1)
        } else {
            snapshotImageAfterView.alpha = 0
            snapshotImageAfterView.transform = CGAffineTransform.init(scaleX: 0.3, y: 1)
        }

        let duration: TimeInterval = 0.3
        UIView.animate(withDuration: reversed ? duration : duration * 0.7, delay: 0, options: [reversed ? .curveEaseOut : .curveEaseIn], animations: {
            if reversed {
                snapshotImageBeforeView.alpha = 1
                snapshotImageBeforeView.transform = CGAffineTransform.identity
            } else {
                snapshotImageBeforeView.alpha = 0
                snapshotImageBeforeView.transform = CGAffineTransform.init(scaleX: 3, y: 1)
            }

        }) { _ in
            snapshotImageBeforeView.removeFromSuperview()
            if reversed {
                whiteView.removeFromSuperview()
            }
        }

        UIView.animate(withDuration: reversed ? duration * 0.7 : duration, delay: 0, options: [reversed ? .curveEaseIn : .curveEaseOut], animations: {
            if reversed {
                snapshotImageAfterView.alpha = 0
                snapshotImageAfterView.transform = CGAffineTransform.init(scaleX: 0.3, y: 1)
            } else {
                snapshotImageAfterView.alpha = 1
                snapshotImageAfterView.transform = CGAffineTransform.identity
            }
        }) { (_) in
            snapshotImageAfterView.removeFromSuperview()
            if !reversed {
                whiteView.removeFromSuperview()
            }
        }
    }

    private func converValues(values: [Int], range: Range<CGFloat>, rounded: Bool) -> [Int] {
        let count = values.count
        let firstCount: Int
        let endCount: Int

        if rounded {
            firstCount = Int(round(range.lowerBound * CGFloat(count)))
            endCount = Int(round(range.upperBound * CGFloat(count)))
        } else {
            firstCount = Int(floor(range.lowerBound * CGFloat(count)))
            endCount = Int(ceil(range.upperBound * CGFloat(count)))
        }

        return Array(values[firstCount..<endCount])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else {
            return
        }
        guard self.selectionAvailable else {
            return
        }

        let location = touch.location(in: self)
        let locationInSelection = touch.location(in: self.selectionPlateView)
        if self.selectionPlateView.frame.contains(location) {
            self.showSelection(location: locationInSelection, animated: false, shouldRespectCahce: false)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard let touch = touches.first else {
            return
        }
        guard self.selectionAvailable else {
            return
        }

        let location = touch.location(in: self)
        let locationInSelection = touch.location(in: self.selectionPlateView)
        if self.selectionPlateView.frame.contains(location) {
            self.showSelection(location: locationInSelection, animated: false, shouldRespectCahce: true)
        }
    }

    private func hideSelection() {
        self.selectedLocation = nil
        self.selectionViews.forEach({ $0.hide() })
        for layer in self.graphDrawLayers {
            layer.hidePosition()
        }
        self.graphSelectionOverlayView.hide(animated: true)
    }

    private var selectedLocation: CGPoint?

    private func showSelection(location: CGPoint, animated: Bool, shouldRespectCahce: Bool) {
        guard let dataSource = self.dataSource else {
            return
        }


        let layers = self.graphDrawLayers.filter({ $0.isHidding == false })
        guard layers.count > 0 else {
            self.hideSelection()
            return
        }

        self.selectedLocation = location
        var selection: GraphDrawLayerView.Selection?
        var overlays: [SelectOverlay] = []

        for layer in layers {
            guard let context = layer.graphContext else {
                continue
            }

            let newSelection = layer.selectPosition(
                graphContext: context,
                position: location.x,
                animationDuration: animated ? Constants.aniamtionDuration : 0
            )

            if let frame = newSelection.rect {
                overlays.append(SelectOverlay(color: layer.color, rect: frame))
            }

            if (selection?.height ?? 0) < newSelection.height {
                selection = newSelection
            }
        }

        if let selection = selection {
            if shouldRespectCahce && self.selectionPlateView.selectedIndex == selection.index {
                return
            }

            let bottomOffset = ((self.graphDrawLayers.first?.frame.maxY ?? 0) - selectionPlateView.frame.maxY)
            let topOffset = ((self.graphDrawLayers.first?.frame.minY ?? 0) - selectionPlateView.frame.minY)
            let height = selection.height - bottomOffset + topOffset

            let dateStyle: DateSelectionView.DateStyle
            if self.zoomed {
                dateStyle = self.oneDayInterval ? .time : .fullTime
            } else {
                dateStyle = .date
            }

            self.selectionViews.forEach({ $0.show(position: selection.position,
                                                  graph: dataSource,
                                                  enabledRows: self.enabledRows,
                                                  index: selection.index,
                                                  height: height,
                                                  canZoom: !self.zoomed,
                                                  dateStyle: dateStyle) })
        }

        if overlays.count > 0 {
            self.graphSelectionOverlayView.show(overlays: overlays)
        }
    }
}
