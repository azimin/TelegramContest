//
//  DateSelectionView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 19/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class DateSelectionView: UIView {
    let dateLabel = UILabel()
    var numberLabels: [UILabel] = []

    var plate = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        self.addSubview(self.plate)

        self.plate.layer.cornerRadius = 8
        self.plate.layer.masksToBounds = true

        self.dateLabel.frame = CGRect(x: 8, y: 0, width: 100, height: 44)
        self.dateLabel.text = "Feb 12\n2019"
        self.dateLabel.textColor = UIColor.white
        self.dateLabel.numberOfLines = 0
        self.plate.contentView.addSubview(self.dateLabel)
        self.dateLabel.font = UIFont.boldSystemFont(ofSize: 18)
    }

    func update(isLight: Bool) {
        self.dateLabel.textColor = isLight ? UIColor(hex: "6D6D72") : UIColor.white
        self.plate.effect = isLight ? UIBlurEffect(style: .light) : UIBlurEffect(style: .dark)
    }

    func show(position: CGFloat, graph: GraphDataSource, enabledRows: [Int], index: Int) {
        self.plate.isHidden = false
        self.numberLabels.forEach({ $0.removeFromSuperview() })
        self.numberLabels = []

        var maxWidth: CGFloat = 0
        for row in enabledRows.sorted() {
            let rowValue = graph.yRows[row]
            let label = UILabel()
            label.textAlignment = .left
            label.font = UIFont.boldSystemFont(ofSize: 18)
            label.textColor = rowValue.color
            label.text = "\(rowValue.values[index])"

            let size = label.sizeThatFits(CGSize(width: 10000, height: 50))
            if size.width > maxWidth {
                maxWidth = size.width
            }

            self.plate.contentView.addSubview(label)

            self.numberLabels.append(label)
        }

        var y: CGFloat = 8
        for label in self.numberLabels {
            label.frame = CGRect(x: 94, y: y, width: maxWidth, height: 28)
            y += (28 + 8)
        }

        let date = graph.xRow.dates[index]
        let components = self.getDateComponents(date)

        let myAttribute = [ NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18) ]
        let myString = NSMutableAttributedString(string: "\(components.0)\n", attributes: myAttribute )

        let myAttribute2 = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18) ]
        let myString2 = NSMutableAttributedString(string: components.1, attributes: myAttribute2 )

        myString.append(myString2)
        self.dateLabel.attributedText = myString

        self.plate.frame = CGRect(x: 0, y: 0, width: maxWidth + 94 + 8, height: y)
        self.plate.center = CGPoint(x: position, y: y / 2)

        self.dateLabel.center = CGPoint(x: self.dateLabel.center.x, y: self.plate.frame.height / 2)

        self.update(isLight: true)
    }

    func getDateComponents(_ date: Date) -> (String, String) {
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "MMM d"

        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy"

        return (dateFormatter1.string(from: date), dateFormatter2.string(from: date))
    }

    func hide() {
        self.plate.isHidden = true
    }
}
