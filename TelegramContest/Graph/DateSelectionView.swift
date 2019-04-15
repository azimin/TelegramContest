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

    var offset: CGFloat = 0

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

    func show(position: CGFloat, graph: GraphDataSource, enabledRows: [Int], index: Int, height: CGFloat, canZoom: Bool, dateStyle: DateStyle, shouldShowPercentage: Bool, shouldRespectCahce: Bool) {
        self.canZoom = canZoom
        self.currentIndex = index
        switch self.style {
        case .line:
            self.showLine(position: position)
        case .plate:
            if let plate = plate {
                if plate.isHidden || !shouldRespectCahce {
                    self.preparePlate(graph: graph, enabledRows: enabledRows, canZoom: canZoom, dateStyle: dateStyle, shouldShowPercentage: shouldShowPercentage)
                    self.updatePlate(position: position, graph: graph, enabledRows: enabledRows, index: index, availableHeight: height, dateStyle: dateStyle, shouldShowPercentage: shouldShowPercentage)
                } else {
                    self.updatePlate(position: position, graph: graph, enabledRows: enabledRows, index: index, availableHeight: height, dateStyle: dateStyle, shouldShowPercentage: shouldShowPercentage)
                }
            }
        }
    }

    private func showLine(position: CGFloat) {
        guard let line = self.line else {
            return
        }

        line.isHidden = false
        line.frame = CGRect(x: position, y: self.offset, width: 1, height: self.frame.height - self.offset)
    }

    func updatePlate(position: CGFloat, graph: GraphDataSource, enabledRows: [Int], index: Int, availableHeight: CGFloat, dateStyle: DateStyle, shouldShowPercentage: Bool) {
        guard let plate = self.plate else {
            return
        }

        let offset: CGFloat = 12
        let plateWidth = plate.frame.width
        let plateHeigh = plate.frame.height

        if shouldShowPercentage {
            var sum = 0
            for row in enabledRows.sorted() {
                let rowValue = graph.yRows[row]
                let value = rowValue.values[index]
                sum += value
            }

            var maxPercent = 100
            for (labelIndex, row) in enabledRows.sorted().enumerated() {
                let rowValue = graph.yRows[row]
                let value = rowValue.values[index]
                let label = self.percentageLabels[labelIndex]
                let percentageValue = Int(round(CGFloat(value) / CGFloat(sum) * 100))
                
                if maxPercent < percentageValue {
                    label.text = "\(maxPercent)%"
                } else {
                    label.text = "\(percentageValue)%"
                }

                maxPercent -= percentageValue
            }
        }

        for (labelIndex, row) in enabledRows.sorted().enumerated() {
            let rowValue = graph.yRows[row]
            let valueLabel = self.numberLabels[labelIndex]
            valueLabel.text = "\(rowValue.values[index])"
        }

        var platePosition = position
        if platePosition - plateWidth / 2 < 16 {
            platePosition -= (platePosition - 16 - plateWidth / 2)
        } else if platePosition + plateWidth / 2 > (self.frame.width - 16) {
            platePosition += (self.frame.width - 16 - platePosition - plateWidth / 2)
        }

        if availableHeight + offset * 2 > (self.frame.height - plateHeigh) {
            let range = (platePosition - plateWidth / 2)..<(platePosition + plateWidth / 2)
            if range.contains(position) {
                if position > self.frame.width / 2 {
                    platePosition = position - plateWidth / 2 - offset
                } else {
                    platePosition = position + plateWidth / 2 + offset
                }
            }
        }

        let date = graph.xRow.dates[index]
        let dateString = self.getDateComponents(date, dateStyle: dateStyle)
        self.dateLabel.text = dateString

        plate.center = CGPoint(x: platePosition, y: plateHeigh / 2 + offset * 1.4)
        self.button.frame = plate.bounds
    }

    func preparePlate(graph: GraphDataSource, enabledRows: [Int], canZoom: Bool, dateStyle: DateStyle, shouldShowPercentage: Bool) {
        guard let plate = self.plate else {
            return
        }

        self.plate?.isHidden = false

        self.percentageLabels.forEach({ $0.removeFromSuperview() })
        self.numberLabels.forEach({ $0.removeFromSuperview() })
        self.namesLabels.forEach({ $0.removeFromSuperview() })
        self.numberLabels = []
        self.namesLabels = []
        self.percentageLabels = []

        var maxNameWidth: CGFloat = 0
        var maxPercentageWidth: CGFloat = 0
        var maxValueWidth: CGFloat = 0

        var height: CGFloat = 0

        for row in enabledRows.sorted() {
            let rowValue = graph.yRows[row]

            if shouldShowPercentage {
                let percentageLabel = UILabel()
                percentageLabel.textAlignment = .right
                percentageLabel.font = UIFont.font(with: .bold, size: 12)
                percentageLabel.textColor = self.theme.configuration.isLight ? UIColor(hex: "6D6D72") : UIColor.white
                percentageLabel.backgroundColor = self.theme.configuration.mainBackgroundColor
                if enabledRows.count == 1 {
                    percentageLabel.text = "100%"
                } else {
                    percentageLabel.text = "99%"
                }
                let valueSize = percentageLabel.sizeThatFits(CGSize(width: 10000, height: 50))
                let valueWidth = valueSize.width + 4
                if valueWidth > maxPercentageWidth {
                    maxPercentageWidth = valueWidth
                }
                plate.addSubview(percentageLabel)
                self.percentageLabels.append(percentageLabel)
            }

            let valueLabel = UILabel()
            valueLabel.textAlignment = .right
            valueLabel.font = UIFont.font(with: .medium, size: 12)
            valueLabel.textColor = rowValue.color
            valueLabel.text = "\(rowValue.values.max() ?? 0)"
            valueLabel.backgroundColor = self.theme.configuration.mainBackgroundColor
            let valueSize = valueLabel.sizeThatFits(CGSize(width: 10000, height: 50))
            let valueWidth = valueSize.width + 8
            if valueWidth > maxValueWidth {
                maxValueWidth = valueWidth
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
            nameLabel.backgroundColor = self.theme.configuration.mainBackgroundColor
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
        let anotherOffset = shouldShowPercentage ? smallOffset * 2 : smallOffset

        let dateSize: CGSize
        switch dateStyle {
        case .date:
            dateSize = CGSize(width: 115, height: 15)
        case .fullTime:
            dateSize = CGSize(width: 92, height: 15)
        case .time:
            dateSize = CGSize(width: 40, height: 15)
        }

        self.dateLabel.frame = CGRect(x: offset, y: 6, width: dateSize.width, height: 15)
        self.dateLabel.backgroundColor = self.theme.configuration.mainBackgroundColor

        let dateArrowWidth = dateSize.width + Constants.arrowSize.width + smallOffset
        let leftWidth = max(dateArrowWidth, maxPercentageWidth + maxNameWidth + maxValueWidth + anotherOffset)

        self.arrowImageView.frame = CGRect(
            x: offset + leftWidth - Constants.arrowSize.width,
            y: 0,
            width: Constants.arrowSize.width,
            height: Constants.arrowSize.height
        )
        self.arrowImageView.center.y = self.dateLabel.center.y
        self.arrowImageView.isHidden = !self.canZoom

        var y = dateSize.height + 9
        for (index, valueLabel) in self.numberLabels.enumerated() {
            let nameLabel = self.namesLabels[index]

            if shouldShowPercentage {
                let perentageLabel = self.percentageLabels[index]
                perentageLabel.frame = CGRect(x: offset, y: y, width: maxPercentageWidth, height: height)
            }

            nameLabel.frame = CGRect(x: offset + maxPercentageWidth + (anotherOffset - smallOffset), y: y, width: maxNameWidth, height: height)
            valueLabel.frame = CGRect(x: offset + maxPercentageWidth + maxNameWidth + anotherOffset, y: y, width: leftWidth - maxPercentageWidth - maxNameWidth - anotherOffset, height: height)
            y += height + 3
        }
        y += 3

        let plateWidth = offset * 2 + leftWidth
        let plateHeight = y
        plate.frame = CGRect(x: 0, y: 0, width: plateWidth, height: plateHeight)
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
