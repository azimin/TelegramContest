//
//  YAxisOverlayView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class YAxisView: UIView {
    enum Style {
        case line
        case label
        case labelRight
    }

    var label: UILabel?
    var line: UIView?
    let style: Style

    var labelOverrideColor: UIColor? {
        didSet {
            if (oldValue == nil && labelOverrideColor != nil) || (oldValue != nil && labelOverrideColor == nil) {
                self.label?.textColor = self.labelOverrideColor ?? self.theme.configuration.axisTextColor
            }
        }
    }

    var theme: Theme = .default {
        didSet {
            let config = theme.configuration
            self.label?.textColor = self.labelOverrideColor ?? config.axisTextColor
            self.line?.backgroundColor = config.gridLines
        }
    }

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            self.line?.frame = CGRect(x: 0, y: 25, width: self.frame.width, height: 0.5)
            if self.style == .labelRight {
                self.label?.frame = CGRect(x: self.frame.width - 60, y: 0, width: 60, height: 26)
            }
        }
    }

    func setup() {
        switch self.style {
        case .label:
            self.label = UILabel()
            self.label?.textAlignment = .left
            self.label?.frame = CGRect(x: 0, y: 0, width: 60, height: 26)
        case .labelRight:
            self.label = UILabel()
            self.label?.textAlignment = .right
            self.label?.frame = CGRect(x: self.frame.width - 60, y: 0, width: 60, height: 26)
        case .line:
            self.line = UIView()
        }

        self.label?.font = UIFont.systemFont(ofSize: 12)
        self.line?.frame = CGRect(x: 0, y: 25, width: self.frame.width, height: 0.5)

        if let label = self.label {
            self.addSubview(label)
        }
        if let line = self.line {
            self.addSubview(line)
        }
    }
}

class YAxisOverlayView: UIView {
    struct Item {
        var view: YAxisView
        var value: Int
        var valueString: String

        init(view: YAxisView, value: Int) {
            self.view = view
            self.value = value
            self.valueString = convertToText(value: value)
        }
    }

    var minValue: Int = 0
    var maxValue: Int = 0
    var items: [Int: Item] = [:]
    var onReuse: [YAxisView] = []
    var onRemoving: [YAxisView] = []

    var labelOverrideColor: UIColor? {
        didSet {
            if (oldValue == nil && labelOverrideColor != nil) || (oldValue != nil && labelOverrideColor == nil) {
                self.items.values.forEach({ $0.view.labelOverrideColor = self.labelOverrideColor })
            }
        }
    }

    var thresholdOptimization = ThresholdOptimization(elapsedTime: 0.08)

    var numberOfComponents = 6
    var supportCaching = true

    let style: YAxisView.Style

    init(style: YAxisView.Style) {
        self.style = style
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var theme: Theme = .default {
        didSet {
            self.items.values.forEach({ $0.view.theme = theme })
        }
    }

    func update(minValue: Int, maxValue: Int, shouldDelay: Bool, animated: Bool) {
        if shouldDelay {
            self.thresholdOptimization.update {
                self.updateFunction(minValue: minValue, maxValue: maxValue, shouldDelay: shouldDelay, animated: animated)
            }
        } else {
            self.updateFunction(minValue: minValue, maxValue: maxValue, shouldDelay: shouldDelay, animated: animated)
        }
    }

    func updateFunction(minValue: Int, maxValue: Int, shouldDelay: Bool, animated: Bool) {
        let value = maxValue - minValue
        let step = ((value) / self.numberOfComponents)
        let oldMaxValue = self.maxValue
        let oldMinValue = self.minValue

        guard (self.maxValue != maxValue || self.minValue != minValue), maxValue != 0 else {
            return
        }

        self.maxValue = maxValue
        self.minValue = minValue

        var newComponents: [String] = []
        var cachedComponentsIndexs: [Int] = []
        for i in 0..<self.numberOfComponents {
            let newValue = i * step + minValue
            newComponents.append(convertToText(value: newValue))
        }

        for index in self.items.keys {
            let item = self.items[index]!
            if item.valueString == newComponents[index] {
                cachedComponentsIndexs.append(index)
            }
        }

        self.disapear(animated: animated, cachedIndexes: cachedComponentsIndexs)

        self.animate(step: step, fromOldMax: oldMaxValue, toNewMax: self.maxValue, fromOldMin: oldMinValue, toNewMin: self.minValue, animated: animated)
    }

    private func disapear(animated: Bool, cachedIndexes: [Int]) {
        for view in self.onRemoving {
            view.layer.removeAllAnimations()
            view.isHidden = true
            self.onReuse.append(view)
        }
        self.onRemoving = []
        var itemsLeft: [Int: Item] = [:]

        for index in self.items.keys {
            let item = self.items[index]!
            if cachedIndexes.contains(index) {
                itemsLeft[index] = item
                continue
            }

            let percent = min(CGFloat(item.value - self.minValue) / CGFloat(self.maxValue - self.minValue), 2)
            self.onRemoving.append(item.view)
            if animated {
                UIView.animate(withDuration: 0.25, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
                    item.view.center = CGPoint(x: item.view.center.x, y: self.frame.height * (1 - percent) - item.view.frame.height / 2)
                    item.view.alpha = 0
                }, completion: { _ in
                    if let index = self.onRemoving.firstIndex(of: item.view) {
                        self.onRemoving.remove(at: index)
                        self.onReuse.append(item.view)
                    }
                })
            } else {
                item.view.isHidden = true
                self.onReuse.append(item.view)
            }
        }
        self.items = itemsLeft
    }

    private func animate(step: Int, fromOldMax: Int, toNewMax: Int, fromOldMin: Int, toNewMin: Int, animated: Bool) {
        let keys = self.items.keys
        for i in 0..<self.numberOfComponents {
            if keys.contains(i) {
                self.items[i]?.view.alpha = 1
                self.items[i]?.view.isHidden = false
                continue
            }
            self.addItem(i: i, step: step, fromOldMax: fromOldMax, toNewMax: toNewMax, fromOldMin: fromOldMin, toNewMin: toNewMin, animated: animated)
        }
        if self.numberOfComponents == 4 {
            self.addItem(i: 4, step: step, fromOldMax: fromOldMax, toNewMax: toNewMax, fromOldMin: fromOldMin, toNewMin: toNewMin, animated: animated)
        }
    }

    private func addItem(i: Int, step: Int, fromOldMax: Int, toNewMax: Int, fromOldMin: Int, toNewMin: Int, animated: Bool) {
        let newPercent = (CGFloat(i * step)) / CGFloat(toNewMax - toNewMin)
        let newValue = i * step + toNewMin
        let oldValue = i * (fromOldMax - fromOldMin) / self.numberOfComponents + fromOldMin
        let oldPercent: CGFloat
        if (fromOldMax - fromOldMin) == 0 {
            oldPercent = 0
        } else {
            oldPercent = (CGFloat(newValue) / CGFloat(oldValue)) - 1 + newPercent
        }
        let view: YAxisView
        if self.onReuse.isEmpty {
            view = YAxisView(style: self.style)
            view.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 26)
            view.theme = self.theme
            self.addSubview(view)
        } else {
            view = self.onReuse.removeLast()
            if let index = self.onRemoving.firstIndex(of: view) {
                self.onRemoving.remove(at: index)
            }
            view.isHidden = false
        }

        view.labelOverrideColor = self.labelOverrideColor
        view.alpha = 0

        let height = (self.frame.height - 20)
        view.center = CGPoint(x: view.center.x, y: height * (1 - oldPercent) - view.frame.height / 2 + 20)
        let item = Item(view: view, value: newValue)
        self.items[i] = item
        view.label?.text = item.valueString

        UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
            view.alpha = 1
            view.center = CGPoint(x: view.center.x, y: height * (1 - newPercent) - view.frame.height / 2 + 20)
        }, completion: nil)
    }
}

fileprivate func convertToText(value: Int) -> String {
    switch value {
    case 0..<1_000:
        return "\(value)"
    case 1_000..<1_000_000:
        let value = Float(value) / 1_000
        let twoDecimalPlaces = String(format: "%.1f", value)
        return "\(twoDecimalPlaces)k"
    default:
        let value = Float(value) / 1_000_000
        let twoDecimalPlaces = String(format: "%.1f", value)
        return "\(twoDecimalPlaces)m"
    }
}
