//
//  ButtonTableViewCell.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 19/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ButtonTableViewCell: UITableViewCell {
    var buttonLabel = UILabel()

    var theme: Theme = .default {
        didSet {
            self.updateTheme()
        }
    }

    func updateTheme() {
        let config = self.theme.configuration
        self.buttonLabel.text = theme.configuration.isLight ? "Switch to Night Mode" : "Switch to Day Mode"
        self.backgroundColor = config.backgroundColor

        let view = UIView()
        view.backgroundColor = config.selectionColor
        self.selectedBackgroundView = view
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
        self.contentView.addSubview(self.buttonLabel)
        self.buttonLabel.text = "Switch"
        self.buttonLabel.font = UIFont.systemFont(ofSize: 17)
        self.buttonLabel.textColor = UIColor(hex: "4591FB")
        self.buttonLabel.translatesAutoresizingMaskIntoConstraints = false
        self.buttonLabel.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.buttonLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
    }
}
