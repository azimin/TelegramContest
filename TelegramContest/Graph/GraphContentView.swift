//
//  GraphContentView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphContentView: UIView {
    enum Constants {
        static var aniamtionDuration: TimeInterval = 0.2
        static var labelsHeight: CGFloat = 44
    }

    var dataSource: GraphDataSource? {
        didSet {
            self.currentMaxValue = 0
            if let dataSource = dataSource {
                self.enabledRows = Array(0..<dataSource.yRows.count)
            } else {
                self.enabledRows = []
            }
            self.update(animated: false)
        }
    }
    var selectedRange: Range<CGFloat> {
        didSet {
            self.hideSelection()
            self.update(animated: false)
        }
    }

    private var enabledRows: [Int] = []

    var shouldCacheMax = false
    var maxTarget: Int = 0
    var currentMaxValue: Int = 0

    func updateEnabledRows(_ values: [Int], animated: Bool) {
        self.enabledRows = values
        self.update(animated: animated)

        if let selection = self.selectedLocation {
            self.showSelection(location: selection, animated: animated)
        }
    }

    private var graphDrawLayers: [GraphDrawLayerView] = []
    private var counter: AnimationCounter = AnimationCounter()
    private var dateLabels = ViewsOverlayView()
    private var yAxisOverlay = YAxisOverlayView()
    private var selectionView = DateSelectionView()
    private var lastVisible: GraphDrawLayerView?

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
                let graphHeight = self.frame.height - Constants.labelsHeight
                self.graphDrawLayers.forEach({ $0.frame.size = CGSize(width: self.frame.size.width, height: graphHeight) })
                self.yAxisOverlay.frame.size = CGSize(width: self.frame.size.width, height: graphHeight)
                self.dateLabels.frame = CGRect(x: 0, y: graphHeight, width: self.frame.size.width, height: Constants.labelsHeight)
                self.selectionView.frame.size = CGSize(width: self.frame.size.width, height: graphHeight)
            }
        }
    }

    func setup() {
        self.addSubview(self.dateLabels)
        self.addSubview(self.yAxisOverlay)
        self.addSubview(self.selectionView)
    }

    func update(animated: Bool) {
        guard let dataSource = self.dataSource else {
            // We are not removing them for smother reusability if graph will be inside table view
            self.graphDrawLayers.forEach({ $0.isHidden = true })
            return
        }

        while graphDrawLayers.count < dataSource.yRows.count {
            let graphView = GraphDrawLayerView()
            graphView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - Constants.labelsHeight)
            self.insertSubview(graphView, belowSubview: self.yAxisOverlay)
            self.graphDrawLayers.append(graphView)
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

        if self.currentMaxValue == 0 || animated {
            self.currentMaxValue = maxValue
            self.yAxisOverlay.update(value: maxValue)
        } else {
            self.counter.animate(from: self.currentMaxValue, to: maxValue) { (value) in
                self.currentMaxValue = value
                self.update(animated: false)
            }
            self.yAxisOverlay.update(value: maxValue)
        }

        var anyPoints: [(Int, CGFloat)] = []
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
                anyPoints = graphView.reportPoints(graphContext: context)
            }

            if !graphView.isHidding {
                self.lastVisible = graphView
            }
        }

        var items: [ViewsOverlayView.Item] = []
        for point in anyPoints {
            let xRow = dataSource.xRow.dates[point.0]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let item = ViewsOverlayView.Item(text: dateFormatter.string(from: xRow), position: point.1)
            items.append(item)
        }
        self.dateLabels.showItems(items: items)
    }

    func converValues(values: [Int], range: Range<CGFloat>) -> [Int] {
        let count = values.count
        let firstCount = Int(floor(range.lowerBound * CGFloat(count)))
        let endCount = Int(ceil(range.upperBound * CGFloat(count)))
        return Array(values[firstCount..<endCount])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touch")
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: self)
        self.showSelection(location: location, animated: false)
    }

    func hideSelection() {
        self.selectedLocation = nil
        self.selectionView.hide()
        for layer in self.graphDrawLayers {
            layer.hidePosition()
        }
    }

    var selectedLocation: CGPoint?

    func showSelection(location: CGPoint, animated: Bool) {
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
                self.selectionView.show(position: position.0,
                                        graph: dataSource,
                                        enabledRows: self.enabledRows,
                                        index: position.1)
                isShowed = true
            }
        }
    }
}
