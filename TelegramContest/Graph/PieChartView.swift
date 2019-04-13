//
//  PieChartView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 12/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

struct PieChartValue {
    var isHidden: Bool
    var value: Int
    var rect: CGRect
}

class PieChartNumbersView: UIView {
    private var values: [PieChartValue] = []
    private var labels: [UILabel] = []
    private var valuesAnimationCounters: [AnimationCounter] = []
    private var fontAnimationCounters: [AnimationCounter] = []

    var theme: Theme = .default {
        didSet {
            self.updateTheme()
        }
    }

    func show(values: [PieChartValue]) {
        while values.count > labels.count {
            let label = UILabel()
            label.textAlignment = .center
//            label.adjustsFontSizeToFitWidth = true
            label.lineBreakMode = .byClipping
            label.font = UIFont.font(with: .bold, size: 26)
            label.textColor = .white
            self.addSubview(label)
            labels.append(label)
        }

        while values.count > valuesAnimationCounters.count {
            let counter = AnimationCounter()
            valuesAnimationCounters.append(counter)

            let fontCounter = AnimationCounter()
            fontAnimationCounters.append(fontCounter)
        }

        for (index, value) in values.enumerated() {
            let label = labels[index]
            var oldValue: Int
            if index < self.values.count {
                oldValue = self.values[index].value
            } else {
                oldValue = 0
            }
            let valuesCounter = valuesAnimationCounters[index]
            let fontCounter = fontAnimationCounters[index]
            UIView.animate(withDuration: 0.15, animations: {
                label.frame = value.rect
            })
            label.isHidden = value.isHidden

            if oldValue > 100 {
                oldValue = 0
            }

            valuesCounter.animate(from: oldValue, to: value.value) { (value) in
                label.text = "\(value)%"
            }
            let fontSize = self.fontSize(string: "\(value.value)%", width: value.rect.width)
            let currentSize = Int(label.font.pointSize * 2)
            fontCounter.animate(from: currentSize, to: Int(fontSize * 2)) { (value) in
                label.font = UIFont.font(with: .bold, size: CGFloat(value) / 2)
            }
        }

        self.values = values
    }

    func updateTheme() {
        let config = self.theme.configuration
        selectionPlateView.backgroundColor = config.mainBackgroundColor
        nameLabel.textColor = self.theme.configuration.isLight ? UIColor(hex: "6D6D72") : UIColor.white
    }

    private lazy var selectionPlateView: UIView = {
        let view = UIView()
        view.addSubview(self.nameLabel)
        view.addSubview(self.valueLabel)
        view.alpha = 0
        view.layer.cornerRadius = 6
        self.addSubview(view)
        return view
    }()
    
    private var nameLabel = UILabel()
    private var valueLabel = UILabel()

    func selectionFunction(range: Range<CGFloat>, name: String, value: Int, color: UIColor?, index: Int) {
        let frame = self.labels[index].frame
        var plateFrame = CGRect.zero

        let width: CGFloat = 154
        let height: CGFloat = 26

        let center = frame.origin.x + frame.width / 2 - width / 2
        if (frame.origin.y + frame.height / 2) > self.frame.height / 2 {
            plateFrame = CGRect(x: center, y: frame.origin.y - height - 12, width: width, height: height)
        } else {
            plateFrame = CGRect(x: center, y: frame.origin.y + frame.height + 12, width: width, height: height)
        }

        if plateFrame.maxX > self.frame.maxX - 16 {
            let delta = plateFrame.maxX - (self.frame.maxX - 16)
            plateFrame.origin.x -= delta
        }

        let shouldAnimate: Bool
        if self.selectionPlateView.alpha > 0 && self.nameLabel.text == name {
            shouldAnimate = true
        } else {
            shouldAnimate = false
        }

        UIView.animate(withDuration: 0.25) {
            if shouldAnimate {
                self.selectionPlateView.frame = plateFrame
            }
            self.selectionPlateView.alpha = 1
        }

        if !shouldAnimate {
            self.selectionPlateView.frame = plateFrame
        }

        nameLabel.frame = CGRect(x: 10, y: 0, width: 134, height: 26)
        nameLabel.text = name
        nameLabel.textAlignment = .left
        nameLabel.font = UIFont.font(with: .regular, size: 12)

        valueLabel.frame = CGRect(x: 10, y: 0, width: 134, height: 26)
        valueLabel.text = "\(value)"
        valueLabel.textAlignment = .right
        valueLabel.font = UIFont.font(with: .medium, size: 12)
        valueLabel.textColor = color

        self.updateTheme()
    }

    func selection(range: Range<CGFloat>, name: String, value: Int, color: UIColor?, index: Int) {
        OperationQueue.main.addOperation {
            self.selectionFunction(range: range, name: name, value: value, color: color, index: index)
        }
    }

    func hideSelection() {
        UIView.animate(withDuration: 0.25) {
            self.selectionPlateView.alpha = 0
        }
    }

    private func fontSize(string: String, width: CGFloat) -> CGFloat {
        var currentSize: CGFloat = 26
        while currentSize > 3 {
            let newWidth = string.sizeOfString(usingFont: UIFont.font(with: .bold, size: currentSize)).width * 1.4
            if newWidth < width {
                return currentSize
            }
            currentSize -= 1
        }
        return currentSize
    }
}
