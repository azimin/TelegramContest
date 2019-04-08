//
//  GraphContentView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphContentView: UIView {
    private enum Constants {
        static var aniamtionDuration: TimeInterval = 0.2
        static var labelsHeight: CGFloat = 26
        static var offset: CGFloat = 16
    }

    private(set) var dataSource: GraphDataSource?
    private var transformedValues: [[Int]] = []

    var style: GraphStyle = .basic

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

    func updateDataSouce(_ dataSource: GraphDataSource?, animated: Bool, zoomingForThisStep: Bool) {
        self.dataSource = dataSource
        self.preveous = .zero
        self.currentMaxValue = 0
        if let dataSource = dataSource {
            self.enabledRows = Array(0..<dataSource.yRows.count)
        } else {
            self.enabledRows = []
        }
        self.transformedValues = Transformer(rows: dataSource?.yRows.map({ $0.values }) ?? [], visibleRows: self.enabledRows, style: style.transformerStyle).values
        self.hideSelection()
        self.update(animated: animated, zoomingForThisStep: animated)
    }

    private(set) var selectedRange: Range<CGFloat>

    func updateSelectedRange(_ selectedRange: Range<CGFloat>, shouldDraw: Bool) {
        self.selectedRange = selectedRange
        self.hideSelection()
        if shouldDraw {
            self.update(animated: false)
        }
    }

    var isZoomingMode: Bool = false {
        didSet {
            if oldValue != isZoomingMode {
                self.updateZoomingStatus()
            }
        }
    }
    private var cachedRange: Range<CGFloat>?

    private func updateZoomingStatus() {
        if self.isZoomingMode {
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

        self.transformedValues = Transformer(rows: dataSource?.yRows.map({ $0.values }) ?? [], visibleRows: values, style: style.transformerStyle).values
        self.update(animated: animated, force: true)

        if let selection = self.selectedLocation {
            self.showSelection(location: selection, animated: animated, shouldRespectCahce: false)
        }
    }

    private var graphDrawLayers: [GraphDrawLayerView] = []
    private var counter: AnimationCounter = AnimationCounter()
    private var dateLabels = ViewsOverlayView()
    private var yAxisLineOverlay = YAxisOverlayView(style: .line)
    private var yAxisLabelOverlay = YAxisOverlayView(style: .label)
    private lazy var yAxisOverlays = [yAxisLineOverlay, yAxisLabelOverlay]
    private var selectionPlateView = DateSelectionView(style: .plate)
    private var selectionLineView = DateSelectionView(style: .line)
    private lazy var selectionViews = [selectionPlateView, selectionLineView]
    private var lastVisible: GraphDrawLayerView?
    private var shadowImage = UIImageView(frame: .zero)
    private var shadowCachedSize: CGRect = .zero
    private var graphSelectionOverlayView: GraphSelectionOverlayView = GraphSelectionOverlayView()

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
        self.graphDrawLayers.forEach({ $0.frame = graphFrame })
        self.graphSelectionOverlayView.frame = graphFrame
        self.yAxisOverlays.forEach({ $0.frame = topFrame })
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
        self.addSubview(self.dateLabels)
        self.addSubview(self.yAxisLineOverlay)
        self.addSubview(self.selectionLineView)
        self.addSubview(self.yAxisLabelOverlay)
        self.addSubview(self.shadowImage)
        self.addSubview(self.graphSelectionOverlayView)
        self.addSubview(self.selectionPlateView)
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

    private func update(animated: Bool, force: Bool = false, zoomingForThisStep: Bool = false) {
        guard let dataSource = self.dataSource else {
            self.graphDrawLayers.forEach({ $0.isHidden = true })
            return
        }

        while graphDrawLayers.count < dataSource.yRows.count {
            let graphView = GraphDrawLayerView()
            graphView.layer.masksToBounds = true
            graphView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - Constants.labelsHeight)
            if let lates = self.graphDrawLayers.last {
                self.insertSubview(graphView, belowSubview: lates)
            } else {
                self.insertSubview(graphView, belowSubview: self.yAxisLabelOverlay)
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
                let values = self.converValues(values: self.transformedValues[index], range: self.selectedRange)
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

        if force {
            self.currentMaxValue = maxValue
            self.yAxisOverlays.forEach({ $0.update(value: maxValue, animated: animated) })
        }

        if self.currentMaxValue == 0 || animated {
            self.currentMaxValue = maxValue
            self.yAxisOverlays.forEach({ $0.update(value: maxValue, animated: animated) })
        } else {
            self.counter.animate(from: self.currentMaxValue, to: maxValue) { (value) in
                self.currentMaxValue = value
                self.update(animated: false)
            }
            self.yAxisOverlays.forEach({ $0.update(value: maxValue, animated: true) })
        }

        var anyPoints: [GraphDrawLayerView.LabelPosition] = []
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
            let context = GraphContext(
                range: self.selectedRange,
                values: self.transformedValues[index],
                maxValue: self.currentMaxValue,
                minValue: minValue,
                style: yRow.style
            )
            graphView.update(graphContext: context, animationDuration: animated ? Constants.aniamtionDuration : 0)
            graphView.color = yRow.color

            if anyPoints.isEmpty {
                let zooming = zoomingForThisStep || self.isZoomingMode
                let pair = graphView.reportLabelPoints(graphContext: context, startingRange: self.cachedRange, zooming: zooming, zoomStep: self.zoomStep)
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
    }

    private func converValues(values: [Int], range: Range<CGFloat>) -> [Int] {
        let count = values.count
        let firstCount = Int(floor(range.lowerBound * CGFloat(count)))
        let endCount = Int(ceil(range.upperBound * CGFloat(count)))
        return Array(values[firstCount..<endCount])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else {
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

            self.selectionViews.forEach({ $0.show(position: selection.position,
                                                  graph: dataSource,
                                                  enabledRows: self.enabledRows,
                                                  index: selection.index,
                                                  height: height) })
        }

        if overlays.count > 0 {
            self.graphSelectionOverlayView.show(overlays: overlays)
        }
    }
}
