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
    var selectedAction: VoidBlock?
    var selectedLongAction: VoidBlock?

    init(name: String, color: UIColor, isSelected: Bool, selectedAction: VoidBlock?, selectedLongAction: VoidBlock?) {
        self.name = name
        self.color = color
        self.isSelected = isSelected
        self.selectedAction = selectedAction
        self.selectedLongAction = selectedLongAction
    }
}

class FiltersTableViewCell: UITableViewCell {

    var height: CGFloat = 0
    var isCached = false

    var rows: [Row] = [] {
        didSet {
            self.isCached = false
        }
    }

    var filterViews: [FilterView] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(width: CGFloat) {
        guard !isCached else {
            return
        }

        var yCoord: CGFloat = 8
        var xCoord: CGFloat = 16
        let offset: CGFloat = 8

        self.filterViews.forEach({ $0.removeFromSuperview() })
        self.filterViews = []

        for (index, item) in rows.enumerated() {
            let filterView = FilterView(title: item.name, isSelected: item.isSelected)

            filterView.longAction = {
                item.selectedLongAction?()
                filterView.updateSelection(isSelected: true, animated: true)
                for (newIndex, filter) in self.filterViews.enumerated() {
                    if index != newIndex {
                        filter.updateSelection(isSelected: false, animated: true)
                    }
                }
            }

            filterView.action = {
                item.selectedAction?()
                filterView.updateSelection(isSelected: !filterView.isSelected, animated: true)
            }

            self.contentView.addSubview(filterView)
            self.filterViews.append(filterView)
            filterView.backgroundColor = item.color
            let size = FilterView.size(text: item.name)

            if xCoord + size.width >= width - 16 {
                xCoord = 16
                yCoord += size.height + offset
            }

            filterView.frame = CGRect(x: xCoord, y: yCoord, width: size.width, height: size.height)
            xCoord += size.width + offset
            self.height = yCoord + offset + size.height
        }
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        self.update(width: size.width)
        return CGSize(width: size.width, height: self.height)
    }

}

class FilterView: UIView {
    static let font = UIFont.font(with: .medium, size: 13)

    let label = UILabel()
    let selectionArrow = UIImageView(image: UIImage(named: "img_select_arrow")!)
    let button = UIButton()

    private(set) var isSelected: Bool
    var action: VoidBlock?
    var longAction: VoidBlock?

    func updateSelection(isSelected: Bool, animated: Bool) {
        self.isSelected = isSelected
        self.updateFrame(animated: animated)
    }

    init(title: String, isSelected: Bool, action: VoidBlock? = nil, longAction: VoidBlock? = nil) {
        self.isSelected = isSelected
        self.action = action
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
        self.label.textColor = UIColor.white
        self.label.font = FilterView.font
        self.label.textAlignment = .center
        self.addSubview(self.selectionArrow)
        self.addSubview(self.button)
        self.updateFrame(animated: false)

        self.button.addTarget(self, action: #selector(self.tapAction), for: .touchUpInside)
        self.button.isExclusiveTouch = true

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(gesture:)))
        self.button.addGestureRecognizer(longPress)
    }

    @objc
    func longPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            self.longAction?()
        }
    }

    @objc
    func tapAction() {
        self.action?()
    }

    func updateFrame(animated: Bool) {
        let updateBlock = {
            let size = FilterView.size(text: self.label.text ?? "")
            let labelWidth = size.width - 40

            if self.isSelected {
                let offset: CGFloat = 12 + 8 + 8
                self.label.frame = CGRect(x: offset, y: 0, width: labelWidth, height: size.height)
                self.selectionArrow.frame = CGRect(x: 12, y: 11, width: 8, height: 8)
            } else {
                self.label.frame = CGRect(x: 20, y: 0, width: labelWidth, height: size.height)
                self.selectionArrow.frame = CGRect(x: -12, y: 11, width: 8, height: 8)
            }
            self.selectionArrow.alpha = self.isSelected ? 1 : 0
            self.button.frame.size = size
        }

        if animated {
            UIView.animate(withDuration: 0.25) {
                updateBlock()
            }
        } else {
            updateBlock()
        }
    }

    static func size(text: String) -> CGSize {
        let labelWidth = text.widthOfString(usingFont: FilterView.font)
        return CGSize(width: labelWidth + 12 + 8 + 12 + 8, height: 30)
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
