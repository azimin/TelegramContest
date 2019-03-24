//
//  DateSelectionView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 19/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class DateSelectionView: UIView {
    enum Constants {
        static var spacing: CGFloat = 8
    }

    enum Style {
        case plate
        case line
    }

    private var line: UIView?
    private var plate: UIVisualEffectView?

    private let dateLabel = UILabel()
    private var numberLabels: [UILabel] = []

    var selectedIndex: Int?
    private let style: Style

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        switch self.style {
        case .line:
            self.setupLine()
        case .plate:
            self.setupPlate()
        }
    }

    private func setupLine() {
        let line = UIView()
        line.frame = CGRect(x: 0, y: 0, width: 1, height: 100)
        line.isHidden = true
        self.addSubview(line)
        self.line = line
    }

    private func setupPlate() {
        let plate = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.addSubview(plate)

        plate.layer.cornerRadius = 8
        plate.layer.masksToBounds = true

        self.dateLabel.frame = CGRect(x: 8, y: 0, width: 100, height: 30)
        self.dateLabel.text = "Feb 12\n2019"
        self.dateLabel.textColor = UIColor.white
        self.dateLabel.numberOfLines = 0
        plate.contentView.addSubview(self.dateLabel)
        self.dateLabel.font = UIFont.boldSystemFont(ofSize: 12)

        self.plate = plate
    }

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.dateLabel.textColor = config.isLight ? UIColor(hex: "6D6D72") : UIColor.white
            self.plate?.effect = config.isLight ? UIBlurEffect(style: .light) : UIBlurEffect(style: .dark)
            self.line?.backgroundColor = config.lineColor
        }
    }

    func show(position: CGFloat, graph: GraphDataSource, enabledRows: [Int], index: Int) {
        switch self.style {
        case .line:
            self.showLine(position: position)
        case .plate:
            self.showPlate(position: position, graph: graph, enabledRows: enabledRows, index: index)
        }
    }

    private func showLine(position: CGFloat) {
        guard let line = self.line else {
            return
        }

        line.isHidden = false
        line.frame.size = CGSize(width: 1, height: self.frame.height)
        line.center = CGPoint(x: position, y: self.center.y)
    }

    private func showPlate(position: CGFloat, graph: GraphDataSource, enabledRows: [Int], index: Int) {
        guard let plate = self.plate else {
            return
        }

        plate.isHidden = false
        self.numberLabels.forEach({ $0.removeFromSuperview() })
        self.numberLabels = []
        self.selectedIndex = index

        var maxWidth: CGFloat = 0
        var height: CGFloat = 0
        for row in enabledRows.sorted() {
            let rowValue = graph.yRows[row]
            let label = UILabel()
            label.textAlignment = .left
            label.font = UIFont.boldSystemFont(ofSize: 12)
            label.textColor = rowValue.color
            label.text = "\(rowValue.values[index])"

            let size = label.sizeThatFits(CGSize(width: 10000, height: 50))
            if size.width > maxWidth {
                maxWidth = size.width
                height = size.height
            }

            plate.contentView.addSubview(label)

            self.numberLabels.append(label)
        }

        var y = Constants.spacing
        for label in self.numberLabels {
            label.frame = CGRect(x: 63, y: y, width: maxWidth, height: height)
            y += height
        }
        y += Constants.spacing

        let date = graph.xRow.dates[index]
        let components = self.getDateComponents(date)

        let myAttribute = [ NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12) ]
        let myString = NSMutableAttributedString(string: "\(components.0)\n", attributes: myAttribute )

        let myAttribute2 = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12) ]
        let myString2 = NSMutableAttributedString(string: components.1, attributes: myAttribute2 )

        myString.append(myString2)
        self.dateLabel.attributedText = myString

        let plateWidth = maxWidth + 63 + Constants.spacing
        var platePosition = position
        plate.frame = CGRect(x: 0, y: 0, width: plateWidth, height: y)
        if platePosition - plateWidth / 2 < -1 {
            platePosition -= (platePosition + 1 - plateWidth / 2)
        } else if platePosition + plateWidth / 2 > (self.frame.width + 1) {
            platePosition += (self.frame.width + 1 - platePosition - plateWidth / 2)
        }
        plate.center = CGPoint(x: platePosition, y: y / 2)

        self.dateLabel.center = CGPoint(x: self.dateLabel.center.x, y: plate.frame.height / 2)
    }

    private func getDateComponents(_ date: Date) -> (String, String) {
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "MMM d"

        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy"

        return (dateFormatter1.string(from: date), dateFormatter2.string(from: date))
    }

    func hide() {
        self.plate?.isHidden = true
        self.line?.isHidden = true
        self.selectedIndex = nil
    }
}
