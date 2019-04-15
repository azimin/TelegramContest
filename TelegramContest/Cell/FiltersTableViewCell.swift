//
//  FiltersTableViewCell.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 07/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

typealias VoidBlock = () -> Void

class Row {
    var name: String
    var color: UIColor
    var isSelected: Bool
    var selectedAction: SelectionBlock?
    var selectedLongAction: SelectionBlock?

    init(name: String, color: UIColor, isSelected: Bool, selectedAction: SelectionBlock?, selectedLongAction: SelectionBlock?) {
        self.name = name
        self.color = color
        self.isSelected = isSelected
        self.selectedAction = selectedAction
        self.selectedLongAction = selectedLongAction
    }
}

class FiltersViewContentller {
    let defaultOffset: CGFloat
    var height: CGFloat = 0
    var isCached = false

    init(defaultOffset: CGFloat) {
        self.defaultOffset = defaultOffset
    }

    var rows: [Row] = [] {
        didSet {
            self.isCached = false
        }
    }

    var filterViews: [FilterView] = []

    var theme: Theme = .default

    func clear() {
        self.filterViews.forEach({ $0.removeFromSuperview() })
        self.filterViews = []
    }

    func update(width: CGFloat, contentView: UIView) {
        guard !isCached else {
            return
        }

        var yCoord: CGFloat = defaultOffset
        var xCoord: CGFloat = 16
        let offset: CGFloat = 8

        self.clear()

        for (index, item) in rows.enumerated() {
            let filterView = FilterView(title: item.name, isSelected: item.isSelected, color: item.color, index: index, theme: theme)

            filterView.longAction = { index in
                let result = item.selectedLongAction?(index)
                filterView.updateSelection(isSelected: true, animated: true)
                for (newIndex, filter) in self.filterViews.enumerated() {
                    if index != newIndex {
                        filter.updateSelection(isSelected: false, animated: true)
                    }
                }
                return result
            }

            filterView.action = { index in
                let result = item.selectedAction?(index)
                filterView.updateSelection(isSelected: !filterView.isSelected, animated: true)
                return result
            }

            contentView.addSubview(filterView)
            self.filterViews.append(filterView)
            let size = FilterView.size(text: item.name)

            if xCoord + size.width >= width - 16 {
                xCoord = 16
                yCoord += size.height + offset
            }

            filterView.frame = CGRect(x: xCoord, y: yCoord, width: size.width, height: size.height)
            xCoord += size.width + offset
            self.height = yCoord + offset + size.height
        }
        self.height += 10
    }
}

class FiltersTableViewCell: UITableViewCell {

    let filtersViewController: FiltersViewContentller = FiltersViewContentller(defaultOffset: 0)

    var rows: [Row] = [] {
        didSet {
            filtersViewController.rows = rows
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(width: CGFloat) {
        self.filtersViewController.update(width: width, contentView: self.contentView)
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        self.update(width: size.width)
        return CGSize(width: size.width, height: self.filtersViewController.height)
    }

}

class FilterView: UIView {
    static let font = UIFont.font(with: .medium, size: 13)

    let label = UILabel()
    let selectionArrow = UIImageView(image: UIImage(named: "img_select_arrow")!)
    let button = UIButton()

    let color: UIColor

    private(set) var isSelected: Bool
    private let index: Int
    var action: SelectionBlock?
    var longAction: SelectionBlock?

    let theme: Theme

    func updateSelection(isSelected: Bool, animated: Bool) {
        self.isSelected = isSelected
        self.updateFrame(animated: animated)
    }

    init(title: String, isSelected: Bool, color: UIColor, index: Int, theme: Theme, action: SelectionBlock? = nil, longAction: SelectionBlock? = nil) {
        self.isSelected = isSelected
        self.theme = theme
        self.action = action
        self.color = color
        self.index = index
        super.init(frame: .zero)
        self.label.text = title
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        self.layer.cornerRadius = 6
        self.addSubview(self.label)
        self.backgroundColor = self.theme.configuration.backgroundColor
        self.label.textColor = UIColor.white
        self.label.font = FilterView.font
        self.label.textAlignment = .center
        self.addSubview(self.selectionArrow)
        self.addSubview(self.button)
        self.updateFrame(animated: false)

        self.button.addTarget(self, action: #selector(self.tapAction), for: .touchUpInside)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(gesture:)))
        longPress.minimumPressDuration = 0.2
        self.button.addGestureRecognizer(longPress)

        self.layer.borderWidth = 1
        self.layer.borderColor = self.color.cgColor
    }

    @objc
    func longPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let action = self.longAction?(self.index)
            self.execute(action: action)
        }
    }

    @objc
    func tapAction() {
        let action = self.action?(self.index)
        self.execute(action: action)
    }

    private func execute(action: Action?) {
        guard let action = action else {
            return
        }
        switch action {
        case .none:
            break
        case .warning:
            self.shake()
        }
    }

    func changeRestarise(state: Bool) {
        self.layer.shouldRasterize = state
        self.layer.rasterizationScale = UIScreen.main.scale
    }

    func updateFrame(animated: Bool) {
        self.label.backgroundColor = UIColor.clear
        OperationQueue.main.addOperation {
            self.updateFrameLogic(animated: animated)
        }
    }

    func updateFrameLogic(animated: Bool) {
        let animationDuration: TimeInterval = 0.2

        let updateBlock: (_ animated: Bool) -> Void = { animated in
            let size = FilterView.size(text: self.label.text ?? "")
            let labelWidth = size.width - 40

            if self.isSelected {
                let offset: CGFloat = 12 + 10 + 8
                self.label.frame = CGRect(x: offset, y: 0, width: labelWidth, height: size.height)
                self.backgroundColor = self.color
                self.selectionArrow.frame = CGRect(x: 12, y: 10, width: 12, height: 10)
            } else {
                self.label.frame = CGRect(x: 20, y: 0, width: labelWidth, height: size.height)
                self.backgroundColor = UIColor.clear
                self.selectionArrow.frame = CGRect(x: -12, y: 10, width: 12, height: 10)
            }
            self.selectionArrow.alpha = self.isSelected ? 1 : 0
            self.button.frame.size = size
        }

        let animationCompletion = {
//            self.label.backgroundColor = self.isSelected ? self.color : self.theme.configuration.backgroundColor
        }

        if animated {
            UIView.animate(withDuration: animationDuration, animations: {
                updateBlock(true)
            }) { (success) in
                if success {
                    animationCompletion()
                }
            }

            let changeColor = CATransition()
            changeColor.duration = animationDuration
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.label.layer.add(changeColor, forKey: nil)
                self.label.textColor = self.isSelected ? .white : self.color
            }
            CATransaction.commit()
            self.label.textColor = self.isSelected ? .white : self.color
        } else {
            updateBlock(false)
            self.label.textColor = self.isSelected ? .white : self.color
            animationCompletion()
        }
    }

    static func size(text: String) -> CGSize {
        let labelWidth = text.widthOfString(usingFont: FilterView.font)
        return CGSize(width: labelWidth + 12 + 10 + 12 + 8, height: 30)
    }
}

extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }

    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }

    func sizeOfString(usingFont font: UIFont) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes)
    }
}

public extension UIView {
    private static let shakeAnimationKey = "shake"

    func shake() {
        self.stopShaking()
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.duration = 1
        animation.repeatCount = 1
        let angle1 = 10
        let angle2 = angle1 / 2
        let angle3 = angle2 / 2
        animation.values = [ 0.0, -angle1, angle1, -angle1, angle1, -angle2, angle2, -angle3, angle3, 0.0 ]
        self.layer.add(animation, forKey: UIView.shakeAnimationKey)
    }

    func stopShaking() {
        self.layer.removeAnimation(forKey: UIView.shakeAnimationKey)
    }
}
