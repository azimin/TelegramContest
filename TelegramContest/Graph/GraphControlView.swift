//
//  GraphControlView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphControlView: UIView {
    private enum Constants {
        static var aniamtionDuration: TimeInterval = 0.25
        static var offset: CGFloat = 16
        static var graphHeight: CGFloat = 38
    }

    private(set) var dataSource: GraphDataSource?
    private var transformedValues: [[Int]] = []

    private var enabledRows: [Int] = []

    var style: GraphStyle = .basic

    func updateDataSouce(_ dataSource: GraphDataSource?, animated: Bool) {
        self.dataSource = dataSource
        if let dataSource = dataSource {
            self.enabledRows = Array(0..<dataSource.yRows.count)
        } else {
            self.enabledRows = []
        }
        self.transformedValues = Transformer(rows: dataSource?.yRows.map({ $0.values }) ?? [], visibleRows: self.enabledRows, style: style.transformerStyle).values
        self.update(animated: animated)
    }

    func updateEnabledRows(_ values: [Int], animated: Bool) {
        self.enabledRows = values
        self.transformedValues = Transformer(rows: dataSource?.yRows.map({ $0.values }) ?? [], visibleRows: self.enabledRows, style: style.transformerStyle).values
        self.update(animated: animated)
    }

    private var graphDrawLayers: [GraphDrawLayerView] = []
    var control = ThumbnailControl(frame: .zero)

    init(dataSource: GraphDataSource? = nil, selectedRange: Range<CGFloat> = 0..<1) {
        self.dataSource = dataSource
        super.init(frame: .zero)
        self.setup()
    }

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.backgroundColor = config.backgroundColor
            control.theme = theme
            self.graphDrawLayers.forEach({ $0.theme = theme })
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            if frame != oldValue {
                self.updateFrame()
            }
        }
    }

    private func updateFrame() {
        let topSpace = (self.frame.height - Constants.graphHeight) / 2
        self.graphDrawLayers.forEach({ $0.frame = CGRect(x: Constants.offset, y: topSpace, width: self.frame.width - Constants.offset * 2, height: Constants.graphHeight) })
        self.control.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }

    private func setup() {
        self.addSubview(self.control)
    }

    private func update(animated: Bool) {
        guard let dataSource = self.dataSource else {
            self.graphDrawLayers.forEach({ $0.isHidden = true })
            return
        }

        while graphDrawLayers.count < dataSource.yRows.count {
            let graphView = GraphDrawLayerView()
            graphView.layer.masksToBounds = true
            graphView.lineWidth = 1
            graphView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            if let lates = self.graphDrawLayers.last {
                self.insertSubview(graphView, belowSubview: lates)
            } else {
                self.insertSubview(graphView, belowSubview: self.control)
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
                let max = self.transformedValues[index].max() ?? 0
                let min = self.transformedValues[index].min() ?? 0

                if max > maxValue {
                    maxValue = max
                }

                if min < minValue {
                    minValue = min
                }
            }
        }

        for index in 0..<self.graphDrawLayers.count {
            let graphView = self.graphDrawLayers[index]
            let isHidden = !enabledRows.contains(index)
            let shouldUpdateOpacity = graphView.isHidden != isHidden
            graphView.isHidden = isHidden

            if animated && shouldUpdateOpacity {
                graphView.alpha = isHidden ? 1 : 0
                UIView.animate(withDuration: Constants.aniamtionDuration) {
                    graphView.alpha = isHidden ? 0 : 1
                }
            } else {
                graphView.alpha = isHidden ? 0 : 1
            }

            if !isHidden {
                let yRow = dataSource.yRows[index]
                let context = GraphContext(
                    range: 0..<1,
                    values: self.transformedValues[index],
                    maxValue: maxValue,
                    minValue: minValue,
                    style: self.style.drawStyle
                )
                graphView.update(graphContext: context, animationDuration: animated ? Constants.aniamtionDuration : 0)
                graphView.color = yRow.color
            }
        }

        self.updateFrame()
    }
}

