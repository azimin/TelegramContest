//
//  GraphTableViewCell.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphTableViewCell: UITableViewCell {

    let graphView = GraphView()

    override var frame: CGRect {
        didSet {
            self.graphView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    func setup() {
        self.selectionStyle = .none
        self.separatorInset = UIEdgeInsets(top: 0, left: 1000, bottom: 0, right: 0)
        self.contentView.addSubview(self.graphView)
    }

}
