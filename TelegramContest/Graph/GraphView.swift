//
//  GraphView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphView: UIView {
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

    func updateEnabledRows(_ values: [Int], animated: Bool) {
        self.graphControlView.updateEnabledRows(values, animated: animated)
        self.graphContentView.updateEnabledRows(values, animated: animated)
    }

    private let graphContentView = GraphContentView()
    private let graphControlView = GraphControlView(dataSource: nil, selectedRange: 0..<1)

    init() {
        self.selectedRange = 0..<1
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            self.graphContentView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 300)
            self.graphControlView.frame = CGRect(x: 0, y: 300, width: self.frame.width, height: 72)
        }
    }

    private func setup() {
        self.addSubview(self.graphControlView)
        self.addSubview(self.graphContentView)
        self.graphControlView.control.addTarget(self, action: #selector(self.rangeUpdated(control:)), for: .valueChanged)
    }

    @objc func rangeUpdated(control: ThumbnailControl) {
        self.selectedRange = control.range
    }

}
