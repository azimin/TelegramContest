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

class TouchableButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea = CGRect(
            x: self.bounds.origin.x - 16,
            y: self.bounds.origin.y - 16,
            width: self.bounds.size.width + 50,
            height: self.bounds.size.height + 30
        )
        return newArea.contains(point)
    }
}

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
        self.updateTitleAction()
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
        
        self.graphControlView.theme = theme
        self.graphContentView.theme = theme
        self.titleLabel.textColor = theme.configuration.nameColor
        self.titleLabel.backgroundColor = theme.configuration.backgroundColor
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
        let hasFilters = !self.graphControlView.filtersView.isHidden
        
        if isEmpty {
            if !hasFilters {
                self.graphControlView.alpha = 0
            }
            self.graphContentView.alpha = 0
        } else {
            self.graphControlView.alpha = 1
            self.graphContentView.alpha = 1
        }

        UIView.animate(withDuration: 0.25) {
            if isEmpty {
                self.zoomOutButton.alpha = 0
                self.titleLabel.alpha = 0
                self.noDataLabel.alpha = 1
            } else {
                self.zoomOutButton.alpha = 1
                self.titleLabel.alpha = 1
                self.noDataLabel.alpha = 0
            }
        }
    }

    func updateZoomStep(newValue: Int?) {
        self.graphContentView.updateZoomStep(newValue: newValue, override: false)
    }

    private var cachedIndexInterval: Range<Int> = -1..<1

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter
    }()

    func updateLabel() {
        guard let dataSource = self.dataSource else {
            return
        }

        let count = dataSource.xRow.count
        let indexs = convertIndexes(count: count, range: self.selectedRange, rounded: self.style == .pie)
        guard indexs != cachedIndexInterval else {
            return
        }

        self.cachedIndexInterval = indexs
        let firstDate = dataSource.xRow.fullDate(at: indexs.lowerBound)
        let lastDate = dataSource.xRow.fullDate(at: indexs.upperBound - 1)

        if firstDate == lastDate {
            let string = dateFormatter.string(from: dataSource.xRow.dates[indexs.lowerBound])
            self.titleLabel.text = string
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
    private let zoomOutButton = TouchableButton(type: .system)

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
        self.zoomOutButton.frame = CGRect(x: 23, y: 12, width: self.zoomOutButton.frame.width, height: self.zoomOutButton.frame.height)
        self.updateTitleAction()

        self.graphContentView.frame = CGRect(x: 0, y: 12 + labelHeight, width: self.frame.width, height: 320)
        self.graphControlView.frame = CGRect(x: 0, y: self.graphContentView.frame.maxY, width: self.frame.width, height: self.graphControlView.height)

        var offset: CGFloat = 0
        if !self.graphControlView.filtersView.isHidden {
            offset += 20 + (self.graphControlView.height - 42)
        }
        self.noDataLabel.frame = CGRect(x: self.frame.width / 2 - 50, y: self.frame.height / 2 - 15 - offset, width: 100, height: 30)
    }

    func updateTitleAction() {
        let labelOffset: CGFloat
        let labelHeight: CGFloat = 16
        if self.zoomOutButton.isHidden {
            labelOffset = 12
            self.titleLabel.frame = CGRect(x: labelOffset, y: 12, width: self.frame.width - labelOffset * 2, height: labelHeight)
            self.titleLabel.textAlignment = .center
        } else {
            labelOffset = 25 + self.zoomOutButton.frame.width
            self.titleLabel.frame = CGRect(x: labelOffset, y: 12, width: self.frame.width - labelOffset - 12, height: labelHeight)
            self.titleLabel.textAlignment = .right
        }
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

        self.titleLabel.font = UIFont.font(with: .bold, size: 13)
        self.titleLabel.textAlignment = .center
        self.titleLabel.adjustsFontSizeToFitWidth = true

        self.zoomOutButton.setImage(UIImage(named: "img_arrow_back"), for: .normal)
        self.zoomOutButton.setTitle("Zoom out", for: .normal)
        self.zoomOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.zoomOutButton.isExclusiveTouch = true
        self.zoomOutButton.addTarget(self, action: #selector(self.zoomOutTapAction), for: .touchUpInside)

        let labelHeight: CGFloat = 16
        let zoomButtonWidth = self.zoomOutButton.sizeThatFits(CGSize(width: 10000, height: 20)).width
        self.zoomOutButton.frame = CGRect(x: 23, y: 12, width: zoomButtonWidth, height: labelHeight)

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
