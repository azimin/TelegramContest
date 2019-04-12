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
            let oldValue: Int
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
