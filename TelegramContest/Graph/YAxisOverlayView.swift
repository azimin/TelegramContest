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

    var labelOverrideColor: UIColor?
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
    }

    var maxValue: Int = 0
    var items: [Item] = []
    var onReuse: [YAxisView] = []
    var onRemoving: [YAxisView] = []
    var labelOverrideColor: UIColor?
    var thresholdOptimization = ThresholdOptimization(elapsedTime: 0.02)

    var numberOfComponents = 6

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
            self.items.forEach({ $0.view.theme = theme })
        }
    }

    func update(value: Int, animated: Bool) {
        let step = (value / self.numberOfComponents)
        let maxValue = step * self.numberOfComponents
        let oldValue = self.maxValue

        guard oldValue != maxValue, maxValue != 0 else {
            return
        }

        self.maxValue = maxValue
        self.disapear(animated: animated)
        self.thresholdOptimization.update {
            self.animate(step: step, from: oldValue, animated: animated)
        }
    }

    private func disapear(animated: Bool) {
        for view in self.onRemoving {
            view.layer.removeAllAnimations()
            view.isHidden = true
            self.onReuse.append(view)
        }
        self.onRemoving = []

        for item in self.items {
            let percent = min(CGFloat(item.value) / CGFloat(self.maxValue), 2)
            self.onRemoving.append(item.view)
            UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
                item.view.center = CGPoint(x: item.view.center.x, y: self.frame.height * (1 - percent) - item.view.frame.height / 2)
                item.view.alpha = 0
            }, completion: { _ in
                self.onReuse.append(item.view)
            })
        }
        self.items = []
    }

    private func animate(step: Int, from: Int, animated: Bool) {
        for i in 0..<self.numberOfComponents {
            self.addItem(i: i, step: step, from: from, animated: animated)
        }
        if self.numberOfComponents == 4 {
            self.addItem(i: 4, step: step, from: from, animated: animated)
        }
    }

    private func addItem(i: Int, step: Int, from: Int, animated: Bool) {
        let percent = CGFloat(i * step) / CGFloat(self.maxValue)
        let oldPercent: CGFloat
        if from == 0 {
            oldPercent = 0
        } else {
            oldPercent = CGFloat(i * step) / CGFloat(from)
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
            view.alpha = 1
        }
        view.labelOverrideColor = self.labelOverrideColor
        view.label?.text = self.convertToText(value: step * i)
        view.alpha = 0

        let height = (self.frame.height - 20)
        view.center = CGPoint(x: view.center.x, y: height * (1 - oldPercent) - view.frame.height / 2 + 20)
        self.items.append(Item(view: view, value: step * i))

        UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
            view.alpha = 1
            view.center = CGPoint(x: view.center.x, y: height * (1 - percent) - view.frame.height / 2 + 20)
        }, completion: nil)
    }

    private func convertToText(value: Int) -> String {
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
}
