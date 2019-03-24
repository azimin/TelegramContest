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

    var dataSource: GraphDataSource? {
        didSet {
            self.preveous = .zero
            self.currentMaxValue = 0
            if let dataSource = dataSource {
                self.enabledRows = Array(0..<dataSource.yRows.count)
            } else {
                self.enabledRows = []
            }
            self.hideSelection()
            self.update(animated: false)
        }
    }

    var selectedRange: Range<CGFloat> {
        didSet {
            self.hideSelection()
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
        self.yAxisOverlays.forEach({ $0.frame = topFrame })
        self.dateLabels.frame = CGRect(x: Constants.offset, y: graphHeight + 20, width: self.frame.size.width - Constants.offset * 2, height: Constants.labelsHeight)
        self.selectionViews.forEach({ $0.frame = CGRect(x: Constants.offset, y: 6, width: self.frame.size.width - Constants.offset * 2, height: graphHeight + 8) })
        self.graphDrawLayers.forEach({ $0.offset = 20 })
        self.updateShadow()
    }

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.backgroundColor = config.backgroundColor
            self.graphDrawLayers.forEach({ $0.theme = theme })
            self.selectionViews.forEach({ $0.theme = theme })
            self.yAxisOverlays.forEach({ $0.theme = theme })
            self.dateLabels.theme = theme
            self.shadowCachedSize = .zero
            self.updateShadow()
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
        self.addSubview(self.selectionPlateView)
    }

    private func update(animated: Bool, force: Bool = false) {
        guard let dataSource = self.dataSource else {
            self.graphDrawLayers.forEach({ $0.isHidden = true })
            return
        }

        while graphDrawLayers.count < dataSource.yRows.count {
            let graphView = GraphDrawLayerView()
            graphView.layer.masksToBounds = true
            graphView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - Constants.labelsHeight)
            self.insertSubview(graphView, belowSubview: self.yAxisLabelOverlay)
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
                let yRow = dataSource.yRows[index]
                let values = self.converValues(values: yRow.values, range: self.selectedRange)
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
                values: yRow.values,
                maxValue: self.currentMaxValue,
                minValue: minValue
            )
            graphView.update(graphContext: context, animationDuration: animated ? Constants.aniamtionDuration : 0)
            graphView.pathLayer.strokeColor = yRow.color.cgColor
            graphView.selectedPath.strokeColor = yRow.color.cgColor

            if anyPoints.isEmpty {
                let pair = graphView.reportLabelPoints(graphContext: context, startingRange: self.cachedRange, zooming: self.isZoomingMode, zoomStep: self.zoomStep)
                anyPoints = pair.points
                
                if self.isZoomingMode {
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

        var isShowed: Bool = false

        for layer in layers {
            guard let context = layer.graphContext else {
                continue
            }

            let position = layer.selectPosition(
                graphContext: context,
                position: location.x,
                animationDuration: animated ? Constants.aniamtionDuration : 0
            )

            if !isShowed {
                if shouldRespectCahce && self.selectionPlateView.selectedIndex == position.1 {
                    continue
                }

                self.selectionViews.forEach({ $0.show(position: position.0,
                                                      graph: dataSource,
                                                      enabledRows: self.enabledRows,
                                                      index: position.1) })
                isShowed = true
            }
        }
    }
}
