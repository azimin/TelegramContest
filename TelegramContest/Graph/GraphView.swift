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

    var dataSource: GraphDataSource? {
        didSet {
            self.graphControlView.dataSource = dataSource
            self.graphContentView.dataSource = dataSource
        }
    }

    var selectedRange: Range<CGFloat> {
        didSet {
            self.graphControlView.control.range = self.selectedRange
            self.graphContentView.selectedRange = self.selectedRange
        }
    }

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.backgroundColor = config.backgroundColor
            self.updateTheme()
        }
    }

    func updateTheme() {
        self.graphControlView.theme = theme
        self.graphContentView.theme = theme
    }

    func updateEnabledRows(_ values: [Int], animated: Bool) {
        self.graphControlView.updateEnabledRows(values, animated: animated)
        self.graphContentView.updateEnabledRows(values, animated: animated)
    }

    func updateZoomStep(newValue: Int?) {
        self.graphContentView.updateZoomStep(newValue: newValue, override: false)
    }

    private let graphContentView = GraphContentView()
    private let graphControlView = GraphControlView(dataSource: nil, selectedRange: 0..<1)
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
            self.graphContentView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 320)
            self.graphControlView.frame = CGRect(x: 0, y: 320, width: self.frame.width, height: 42)
        }
    }

    private func setup() {
        self.addSubview(self.graphControlView)
        self.addSubview(self.graphContentView)
        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdated(control:)), for: .valueChanged)
        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdateEnded(control:)), for: .editingDidEnd)
        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdateStated(control:)), for: .editingDidBegin)

        self.graphContentView.updatedZoomStep = { value in
            self.updatedZoomStep?(value)
        }
    }

    @objc func rangeUpdated(control: ThumbnailControl) {
        self.selectedRange = control.range
        self.rangeUpdated?(control.range)
    }

    @objc func rangeUpdateEnded(control: ThumbnailControl) {
        self.graphContentView.isZoomingMode = false
    }

    @objc func rangeUpdateStated(control: ThumbnailControl) {
        switch control.gesture {
        case .increaseLeft, .increaseRight:
            self.graphContentView.isZoomingMode = true
        case .move, .none:
            break
        }
    }

}
