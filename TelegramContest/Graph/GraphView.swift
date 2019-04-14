//
//  GraphView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

enum Action {
    case none
    case warning
}

typealias SelectionBlock = (_ index: Int) -> Action?

class GraphView: UIView {
    var rangeUpdated: ((_ range: Range<CGFloat>) -> Void)?

    private(set) var dataSource: GraphDataSource?

    var zoomAction: SelectIndexAction?
    var zoomOutAction: VoidBlock?
    var updateSizeAction: VoidBlock?

    var noDataLabel = UILabel()

    var selectedAction: SelectionBlock? {
        didSet {
            self.graphControlView.selectedAction = selectedAction
        }
    }
    var selectedLongAction: SelectionBlock? {
        didSet {
            self.graphControlView.selectedLongAction = selectedLongAction
        }
    }

    var height: CGFloat = 404

    func updateDataSource(dataSource: GraphDataSource, enableRows: [Int], skip: Bool, zoomed: Bool) {
        self.style = dataSource.style
        self.zoomOutButton.isHidden = !zoomed
        self.dataSource = dataSource
        if !skip {
            self.graphControlView.updateDataSouce(dataSource, enableRows: enableRows, animated: false, zoom: nil)
            self.graphContentView.updateDataSouce(dataSource, enableRows: enableRows, animated: false, zoom: nil, zoomed: zoomed)
        }
    }

    private(set) var selectedRange: Range<CGFloat>

    func updateSelectedRange(range: Range<CGFloat>, skip: Bool) {
        self.selectedRange = range
        if !skip {
            self.graphControlView.control.update(range: self.selectedRange, animated: false)
            self.graphContentView.updateSelectedRange(self.selectedRange, shouldDraw: true)
        }
        self.updateLabel()
    }

    var theme: Theme = .default {
        didSet {
            let config = theme.configuration
            self.backgroundColor = config.backgroundColor
            self.titleLabel.backgroundColor = config.backgroundColor
            self.zoomOutButton.setTitleColor(config.zoomOutText, for: .normal)
            self.updateTheme()
        }
    }

    var style: GraphStyle = .basic {
        didSet {
            self.graphControlView.style = style
        }
    }

    private func updateTheme() {
        self.noDataLabel.textColor = theme.configuration.axisTextColor
        self.noDataLabel.backgroundColor = theme.configuration.backgroundColor
        self.graphControlView.theme = theme
        self.graphContentView.theme = theme
        self.titleLabel.textColor = theme.configuration.tooltipArrow
    }

    func updateEnabledRows(_ values: [Int], animated: Bool) {
        self.graphControlView.updateEnabledRows(values, animated: animated)
        self.graphContentView.updateEnabledRows(values, animated: animated)
        self.updateNoDataState(isEmpty: values.isEmpty)
    }

    private var noData: Bool = false

    func updateNoDataState(isEmpty: Bool) {
        guard noData != isEmpty else {
            return
        }
        self.noData = isEmpty
        UIView.animate(withDuration: 0.25) {
            let hasFilters = !self.graphControlView.filtersView.isHidden
            if isEmpty {
                self.graphContentView.alpha = 0
                if !hasFilters {
                    self.graphControlView.alpha = 0
                }
                self.zoomOutButton.alpha = 0
                self.titleLabel.alpha = 0
                self.noDataLabel.alpha = 1
            } else {
                self.zoomOutButton.alpha = 1
                self.graphContentView.alpha = 1
                self.graphControlView.alpha = 1
                self.titleLabel.alpha = 1
                self.noDataLabel.alpha = 0
            }
        }
    }

    func updateZoomStep(newValue: Int?) {
        self.graphContentView.updateZoomStep(newValue: newValue, override: false)
    }

    private var cachedIndexInterval: Range<Int> = -1..<1

    func updateLabel() {
        guard let dataSource = self.dataSource else {
            return
        }

        let count = dataSource.xRow.fullDateStrings.count
        var indexs = convertIndexes(count: count, range: self.selectedRange, rounded: self.style == .pie)
        if self.style == .pie, indexs.interval >= 1, self.selectedRange.upperBound <= 0.9 {
            indexs = indexs.lowerBound..<(indexs.upperBound - 1)
        }
        guard indexs != cachedIndexInterval else {
            return
        }

        self.cachedIndexInterval = indexs
        let firstDate = dataSource.xRow.fullDateStrings[indexs.lowerBound]
        let lastDate = dataSource.xRow.fullDateStrings[indexs.upperBound]

        if firstDate == lastDate {
            self.titleLabel.text = firstDate
            self.graphContentView.oneDayInterval = true
        } else {
            self.titleLabel.text = "\(firstDate) - \(lastDate)"
            self.graphContentView.oneDayInterval = false
        }
    }

    private var shouldUpdateRange: Bool = true
    func transform(to dataSource: GraphDataSource, enableRows: [Int], zoom: Zoom?, zoomStep: Int?, range: Range<CGFloat>, zoomed: Bool) {
        if dataSource.style == .pie {
            self.graphControlView.control.pagingDelta = 0.2
        } else {
            self.graphControlView.control.pagingDelta = nil
        }
        self.graphContentView.updateSelectedRange(range, shouldDraw: false)
        self.graphContentView.updateZoomStep(newValue: zoomStep, override: false)
        self.graphContentView.updateDataSouce(dataSource, enableRows: enableRows, animated: true, zoom: zoom, zoomed: zoomed)

        self.graphControlView.updateDataSouce(dataSource, enableRows: enableRows, animated: true, zoom: zoom)
        
        shouldUpdateRange = false
        self.graphControlView.control.update(range: range, animated: true)
        shouldUpdateRange = true

        self.updateDataSource(dataSource: dataSource, enableRows: enableRows, skip: true, zoomed: zoomed)
        self.updateSelectedRange(range: range, skip: true)
    }

    private let graphContentView = GraphContentView()
    private let graphControlView = GraphControlView(dataSource: nil, selectedRange: 0..<1)

    private let titleLabel = UILabel()
    private let zoomOutButton = UIButton(type: .system)

    var updatedZoomStep: ((Int?) -> Void)?

    init() {
        self.selectedRange = 0..<1
        super.init(frame: .zero)
        self.setup()
        self.updateTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            self.updateFrame()
        }
    }

    func updateFrame() {
        let labelHeight: CGFloat = 16
        let zoomButtonWidth = self.zoomOutButton.sizeThatFits(CGSize(width: 10000, height: 20)).width
        self.zoomOutButton.frame = CGRect(x: 23, y: 12, width: zoomButtonWidth, height: labelHeight)

        let labelOffset = 23 + zoomButtonWidth
        self.titleLabel.frame = CGRect(x: labelOffset, y: 12, width: self.frame.width - labelOffset * 2, height: labelHeight)

        self.graphContentView.frame = CGRect(x: 0, y: 12 + labelHeight, width: self.frame.width, height: 320)
        self.graphControlView.frame = CGRect(x: 0, y: self.graphContentView.frame.maxY, width: self.frame.width, height: self.graphControlView.height)

        var offset: CGFloat = 0
        if !self.graphControlView.filtersView.isHidden {
            offset += 20 + (self.graphControlView.height - 42)
        }
        self.noDataLabel.frame = CGRect(x: self.frame.width / 2 - 50, y: self.frame.height / 2 - 15 - offset, width: 100, height: 30)
    }

    private func setup() {
        self.addSubview(self.graphControlView)
        self.addSubview(self.graphContentView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.zoomOutButton)

        self.noDataLabel.alpha = 0
        self.addSubview(self.noDataLabel)
        self.noDataLabel.textAlignment = .center
        self.noDataLabel.font = UIFont.font(with: .regular, size: 16)
        self.noDataLabel.text = "No Data"

        self.titleLabel.font = UIFont.systemFont(ofSize: 13)
        self.titleLabel.textAlignment = .center
        self.titleLabel.adjustsFontSizeToFitWidth = true

        self.zoomOutButton.setImage(UIImage(named: "img_arrow_back"), for: .normal)
        self.zoomOutButton.setTitle("Zoom out", for: .normal)
        self.zoomOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.zoomOutButton.isExclusiveTouch = true
        self.zoomOutButton.addTarget(self, action: #selector(self.zoomOutTapAction), for: .touchUpInside)

        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdated(control:)), for: .valueChanged)
        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdateEnded(control:)), for: .editingDidEnd)
        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdateStated(control:)), for: .editingDidBegin)

        self.graphControlView.updateSizeAction = {
            self.height = 362 + self.graphControlView.height
            self.updateFrame()
            self.updateSizeAction?()
        }

        self.graphContentView.updatedZoomStep = { value in
            self.updatedZoomStep?(value)
        }

        self.graphContentView.zoomAction = { index in
            self.zoomAction?(index)
        }

        self.style = .basic
    }

    @objc
    func zoomOutTapAction() {
        self.zoomOutAction?()
    }

    @objc private func rangeUpdated(control: ThumbnailControl) {
        guard shouldUpdateRange else {
            return
        }

        self.updateSelectedRange(range: control.range, skip: false)
        self.rangeUpdated?(control.range)
    }

    @objc private func rangeUpdateEnded(control: ThumbnailControl) {
        self.graphContentView.isMovingZoomMode = false
    }

    @objc private func rangeUpdateStated(control: ThumbnailControl) {
        switch control.gesture {
        case .increaseLeft, .increaseRight:
            self.graphContentView.isMovingZoomMode = true
        case .move, .none:
            break
        }
    }

}
