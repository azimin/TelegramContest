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
        static var minimalSpacing: CGFloat = 16
        static var arrowSize: CGSize = CGSize(width: 5, height: 10)
    }

    enum Style {
        case plate
        case line
    }

    enum DateStyle {
        case date
        case time
        case fullTime
    }

    private var line: UIView?
    private var plate: UIView?

    private var dateLabel: UILabel!
    private var arrowImageView: UIImageView!
    private var button: UIButton!
    private var percentageLabels: [UILabel] = []
    private var numberLabels: [UILabel] = []
    private var namesLabels: [UILabel] = []

    private var currentIndex = 0
    private var canZoom: Bool = false

    var selectedIndex: Int?
    private let style: Style

    var tapAction: SelectIndexAction?
    var closeAction: VoidBlock?

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
        let plate = UIView()
        self.addSubview(plate)

        plate.layer.cornerRadius = 6

        self.dateLabel = UILabel()
        self.dateLabel.frame = CGRect(x: 8, y: 0, width: 100, height: 15)
        self.dateLabel.textColor = UIColor.white
        plate.addSubview(self.dateLabel)
        self.dateLabel.font = UIFont.boldSystemFont(ofSize: 12)

        self.arrowImageView = UIImageView(image: UIImage(named: "img_action_arrow")!.withRenderingMode(.alwaysTemplate))
        plate.addSubview(self.arrowImageView)

        self.button = UIButton()
        self.button.isExclusiveTouch = true
        self.button.addTarget(self, action: #selector(self.didTap), for: .touchUpInside)
        plate.addSubview(self.button)

        self.plate = plate
    }

    @objc
    func didTap() {
        if canZoom {
            self.tapAction?(self.currentIndex)
        } else {
            self.closeAction?()
        }
    }

    var theme: Theme = .default {
        didSet {
            let config = theme.configuration
            self.dateLabel?.textColor = config.isLight ? UIColor(hex: "6D6D72") : UIColor.white
            self.arrowImageView?.tintColor = config.tooltipArrow
            self.plate?.backgroundColor = config.mainBackgroundColor
            self.line?.backgroundColor = config.gridLines
        }
    }

    func show(position: CGFloat, graph: GraphDataSource, enabledRows: [Int], index: Int, height: CGFloat, canZoom: Bool, dateStyle: DateStyle) {
        self.canZoom = canZoom
        self.currentIndex = index
        switch self.style {
        case .line:
            self.showLine(position: position)
        case .plate:
            self.showPlate(position: position, graph: graph, enabledRows: enabledRows, index: index, availableHeight: height, canZoom: canZoom, dateStyle: dateStyle)
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

    private func showPlate(position: CGFloat, graph: GraphDataSource, enabledRows: [Int], index: Int, availableHeight: CGFloat, canZoom: Bool, dateStyle: DateStyle) {
        guard let plate = self.plate else {
            return
        }

        plate.isHidden = false
        self.numberLabels.forEach({ $0.removeFromSuperview() })
        self.namesLabels.forEach({ $0.removeFromSuperview() })
        self.numberLabels = []
        self.namesLabels = []

        self.selectedIndex = index

        var maxNameWidth: CGFloat = 0
        var maxValueWidth: CGFloat = 0

        var height: CGFloat = 0

        for row in enabledRows.sorted() {
            let rowValue = graph.yRows[row]

            let valueLabel = UILabel()
            valueLabel.textAlignment = .right
            valueLabel.font = UIFont.font(with: .medium, size: 12)
            valueLabel.textColor = rowValue.color
            valueLabel.text = "\(rowValue.values[index])"
            let valueSize = valueLabel.sizeThatFits(CGSize(width: 10000, height: 50))
            if valueSize.width > maxValueWidth {
                maxValueWidth = valueSize.width
            }
            if height < valueSize.height {
                height = valueSize.height
            }
            plate.addSubview(valueLabel)
            self.numberLabels.append(valueLabel)

            let nameLabel = UILabel()
            nameLabel.textAlignment = .left
            nameLabel.font = UIFont.font(with: .regular, size: 12)
            nameLabel.textColor = self.theme.configuration.isLight ? UIColor(hex: "6D6D72") : UIColor.white
            nameLabel.text = rowValue.name
            let nameSize = nameLabel.sizeThatFits(CGSize(width: 10000, height: 50))
            if nameSize.width > maxNameWidth {
                maxNameWidth = nameSize.width
            }
            if height < nameSize.height {
                height = nameSize.height
            }
            plate.addSubview(nameLabel)
            self.namesLabels.append(nameLabel)
        }

        let offset: CGFloat = 12
        let smallOffset: CGFloat = 8

        let date = graph.xRow.dates[index]
        let dateString = self.getDateComponents(date, dateStyle: dateStyle)
        self.dateLabel.text = dateString
        let dateSize = self.dateLabel.sizeThatFits(CGSize(width: 10000, height: 50))
        self.dateLabel.frame = CGRect(x: offset, y: 6, width: dateSize.width, height: 15)
        let dateArrowWidth = dateSize.width + Constants.arrowSize.width + smallOffset
        let leftWidth = max(dateArrowWidth, maxNameWidth + maxValueWidth + smallOffset)

        self.arrowImageView.frame = CGRect(
            x: offset + dateSize.width + smallOffset,
            y: 0,
            width: Constants.arrowSize.width,
            height: Constants.arrowSize.height
        )
        self.arrowImageView.center.y = self.dateLabel.center.y
        self.arrowImageView.isHidden = !self.canZoom

        var y = dateSize.height + 9
        for (index, valueLabel) in self.numberLabels.enumerated() {
            let nameLabel = self.namesLabels[index]

            nameLabel.frame = CGRect(x: offset, y: y, width: maxNameWidth, height: height)
            valueLabel.frame = CGRect(x: offset + maxNameWidth + smallOffset, y: y, width: leftWidth - maxNameWidth - smallOffset, height: height)
            y += height + 3
        }
        y += 3

        let plateWidth = offset * 2 + leftWidth
        var platePosition = position
        plate.frame = CGRect(x: 0, y: 0, width: plateWidth, height: y)
        if platePosition - plateWidth / 2 < -1 {
            platePosition -= (platePosition + 1 - plateWidth / 2)
        } else if platePosition + plateWidth / 2 > (self.frame.width + 1) {
            platePosition += (self.frame.width + 1 - platePosition - plateWidth / 2)
        }

        if availableHeight + offset * 2 > (self.frame.height - y) {
            let range = (platePosition - plateWidth / 2)..<(platePosition + plateWidth / 2)
            if range.contains(position) {
                if position > self.frame.width / 2 {
                    platePosition = position - plateWidth / 2 - offset
                } else {
                    platePosition = position + plateWidth / 2 + offset
                }
            }
        }

        plate.center = CGPoint(x: platePosition, y: y / 2)
        self.button.frame = plate.bounds
    }

    private func getDateComponents(_ date: Date, dateStyle: DateStyle) -> String {
        let dateFormatter1 = DateFormatter()
        switch dateStyle {
        case .date:
            dateFormatter1.dateFormat = "EEE, d MMM yyyy"
        case .time:
            dateFormatter1.dateFormat = "HH:mm"
        case .fullTime:
            dateFormatter1.dateFormat = "d MMM, HH:mm"
        }
        return dateFormatter1.string(from: date)
    }

    func hide() {
        self.plate?.isHidden = true
        self.line?.isHidden = true
        self.selectedIndex = nil
    }
}
