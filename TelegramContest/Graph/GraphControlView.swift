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
    var updateSizeAction: VoidBlock?
    var selectedAction: SelectionBlock?
    var selectedLongAction: SelectionBlock?
    
    private var transformedValues: [[Int]] = []

    private var enabledRows: [Int] = []

    var style: GraphStyle = .basic
    var height: CGFloat = 42

    func updateDataSouce(_ dataSource: GraphDataSource?, enableRows: [Int], animated: Bool, zoom: Zoom?) {
        if let zoom = zoom, zoom.shouldReplaceRangeController {
            self.triggerFilterView(zoom: zoom, dataSource: dataSource, enableRows: enableRows)
        }

        self.dataSource = dataSource
        self.enabledRows = enableRows
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
    var contentView: UIView = UIView()
    var filtersView: UIView = UIView()

    init(dataSource: GraphDataSource? = nil, selectedRange: Range<CGFloat> = 0..<1) {
        self.dataSource = dataSource
        super.init(frame: .zero)
        self.setup()
    }

    var theme: Theme = .default {
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
        self.control.frame = self.bounds
        self.contentView.frame = self.bounds
        self.filtersView.frame = self.bounds
        self.graphDrawLayers.forEach({ $0.frame = CGRect(x: Constants.offset, y: topSpace, width: self.frame.width - Constants.offset * 2, height: Constants.graphHeight) })
    }

    private func setup() {
        self.addSubview(self.contentView)
        self.filtersView.isHidden = true
        self.addSubview(self.filtersView)
        self.contentView.addSubview(self.control)
    }

    private func update(animated: Bool) {
        guard let dataSource = self.dataSource else {
            self.graphDrawLayers.forEach({ $0.isHidden = true })
            return
        }

        while graphDrawLayers.count < dataSource.yRows.count {
            let graphView = GraphDrawLayerView()
            graphView.layer.cornerRadius = 6
            graphView.layer.masksToBounds = true
            graphView.lineWidth = 1
            graphView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            if let lates = self.graphDrawLayers.last {
                self.contentView.insertSubview(graphView, belowSubview: lates)
            } else {
                self.contentView.insertSubview(graphView, belowSubview: self.control)
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
                    style: yRow.style
                )
                graphView.update(graphContext: context, animationDuration: animated ? Constants.aniamtionDuration : 0, zoom: nil)
                graphView.color = yRow.color
            }
        }

        self.updateFrame()
    }

    private let filterViewController = FiltersViewContentller()
    private var contentImage: UIImage?

    func triggerFilterView(zoom: Zoom, dataSource: GraphDataSource?, enableRows: [Int]) {
        if !zoom.index.isInside {
            self.hideFilterView()
            return
        } else {
            self.showFilterView(dataSource: dataSource, enableRows: enableRows)
        }
    }

    func showFilterView(dataSource: GraphDataSource?, enableRows: [Int]) {
        let contentImage = self.contentView.asImage()
        self.contentImage = contentImage

        let contentImageView = UIImageView(image: contentImage)
        contentImageView.frame = self.contentView.frame
        self.addSubview(contentImageView)

        var rows: [Row] = []
        for (index, yRow) in (dataSource?.yRows ?? []).enumerated() {
            let row = Row(name: yRow.name, color: yRow.color, isSelected: enableRows.contains(index), selectedAction: self.selectedAction, selectedLongAction: self.selectedLongAction)
            rows.append(row)
        }
        filterViewController.rows = rows
        filterViewController.update(width: self.frame.width, contentView: self.filtersView)
        self.height = filterViewController.height - 6
        self.contentView.isHidden = true

        self.filtersView.isHidden = false
        self.filtersView.alpha = 0
        self.filtersView.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.filtersView.alpha = 1
            self.filtersView.transform = CGAffineTransform.identity
            contentImageView.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            contentImageView.alpha = 0
        }) { (_) in
            contentImageView.removeFromSuperview()
        }

        self.updateSizeAction?()
    }

    func hideFilterView() {
        let contentImageView = UIImageView(image: contentImage)
        contentImageView.frame = self.contentView.frame
        contentImageView.frame.size.height -= (self.height - 42)
        self.addSubview(contentImageView)

        let filterImage = self.filtersView.asImage()
        let filterImageView = UIImageView(image: filterImage)
        filterImageView.frame = self.filtersView.frame
        self.addSubview(filterImageView)

        contentImageView.alpha = 0
        contentImageView.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            contentImageView.alpha = 1
            contentImageView.transform = CGAffineTransform.identity
            filterImageView.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            filterImageView.alpha = 0
        }) { (_) in
            contentImageView.removeFromSuperview()
            filterImageView.removeFromSuperview()
            self.contentView.isHidden = false
            self.filtersView.isHidden = true
        }

        self.filterViewController.clear()
        self.height = 42
        self.updateSizeAction?()
    }
}

