//
//  GraphView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphView: UIView {
    var rangeUpdated: ((_ range: Range<CGFloat>) -> Void)?

    private(set) var dataSource: GraphDataSource?

    var zoomAction: SelectIndexAction?
    var zoomOutAction: VoidBlock?

    func updateDataSource(dataSource: GraphDataSource, enableRows: [Int], skip: Bool, zoomed: Bool) {
        self.zoomOutButton.isHidden = !zoomed
        self.dataSource = dataSource
        if !skip {
            self.graphControlView.updateDataSouce(dataSource, enableRows: enableRows, animated: false)
            self.graphContentView.updateDataSouce(dataSource, enableRows: enableRows, animated: false, zoomingForThisStep: false, zoomed: zoomed)
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
            self.graphContentView.style = style
        }
    }

    private func updateTheme() {
        self.graphControlView.theme = theme
        self.graphContentView.theme = theme
        self.titleLabel.textColor = theme.configuration.nameColor
    }

    func updateEnabledRows(_ values: [Int], animated: Bool) {
        self.graphControlView.updateEnabledRows(values, animated: animated)
        self.graphContentView.updateEnabledRows(values, animated: animated)
    }

    func updateZoomStep(newValue: Int?) {
        self.graphContentView.updateZoomStep(newValue: newValue, override: false)
    }

    func updateLabel() {
        guard let dataSource = self.dataSource else {
            return
        }

        let dates = self.converValues(values: dataSource.xRow.fullDateStrings, range: self.selectedRange)
        if let firstDate = dates.first, let lastDate = dates.last {
            if firstDate == lastDate {
                self.titleLabel.text = firstDate
                self.graphContentView.oneDayInterval = true
            } else {
                self.titleLabel.text = "\(firstDate) - \(lastDate)"
                self.graphContentView.oneDayInterval = false
            }
        }
    }

    private func converValues(values: [String], range: Range<CGFloat>) -> [String] {
        let count = values.count
        let firstCount = Int(floor(range.lowerBound * CGFloat(count)))
        let endCount = Int(ceil(range.upperBound * CGFloat(count)))
        return Array(values[max(firstCount, 0)..<min(endCount, count)])
    }

    private var shouldUpdateRange: Bool = true
    func transform(to dataSource: GraphDataSource, enableRows: [Int], zoomStep: Int?, range: Range<CGFloat>, zoomed: Bool) {
        self.graphContentView.updateSelectedRange(range, shouldDraw: false)
        self.graphContentView.updateZoomStep(newValue: zoomStep, override: false)
        self.graphContentView.updateDataSouce(dataSource, enableRows: enableRows, animated: true, zoomingForThisStep: true, zoomed: zoomed)

        self.graphControlView.updateDataSouce(dataSource, enableRows: enableRows, animated: true)
        
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
        self.graphControlView.frame = CGRect(x: 0, y: self.graphContentView.frame.maxY, width: self.frame.width, height: 42)
    }

    private func setup() {
        self.addSubview(self.graphControlView)
        self.addSubview(self.graphContentView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.zoomOutButton)

        self.titleLabel.font = UIFont.systemFont(ofSize: 13)
        self.titleLabel.textAlignment = .center
        self.titleLabel.adjustsFontSizeToFitWidth = true

        self.zoomOutButton.setTitle("⤶ Zoom out", for: .normal)
        self.zoomOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.zoomOutButton.isExclusiveTouch = true
        self.zoomOutButton.addTarget(self, action: #selector(self.zoomOutTapAction), for: .touchUpInside)

        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdated(control:)), for: .valueChanged)
        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdateEnded(control:)), for: .editingDidEnd)
        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdateStated(control:)), for: .editingDidBegin)

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
