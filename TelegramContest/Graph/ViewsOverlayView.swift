//
//  NumbersOverlayView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ViewsOverlayView: UIView {
    struct VisualItem {
        let label: UILabel
        let item: Item
    }

    struct Item: Equatable {
        enum Corner {
            case left
            case right
            case none
        }

        let text: String
        let position: CGFloat
        let alpha: CGFloat
        let corner: Corner

        static func == (lhs: Item, rhs: Item) -> Bool {
            return lhs.text == rhs.text
        }
    }

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.backgroundColor = config.backgroundColor
            self.allItems.forEach({ $0.label.textColor = config.titleColor })
        }
    }

    private var allItems: [VisualItem] = []
    private var onRemoving: [UILabel] = []
    var thresholdOptimization = ThresholdOptimization(elapsedTime: 0.1)

    func showItems(items: [Item]) {
        var newItems: [Item] = items
        var itemsToDisapear: [Item] = []

        for item in self.allItems.map({ $0.item }) {
            if let index = items.firstIndex(of: item) {
                newItems.removeAll(where: { $0 == item })
                self.move(item: items[index])
            } else {
                itemsToDisapear.append(item)
            }
        }

        thresholdOptimization.update {
            self.show(items: newItems)
        }

        if newItems.count > 0 {
            self.onRemoving.forEach({ $0.removeFromSuperview() })
            self.onRemoving = []
        }
        itemsToDisapear.forEach({ self.disaper(item: $0) })
    }

    func finishTransision() {
        for item in self.allItems {
            if item.label.alpha > 0 {
                UIView.animate(withDuration: 0.25) {
                    item.label.alpha = 1
                }
            } else {
                self.disaper(item: item.item)
            }
        }
    }

    func move(item: Item) {
        guard let index = self.allItems.firstIndex(where: { $0.item == item }) else {
            return
        }
        let visualItem = self.allItems[index]
        let label = visualItem.label
        label.center = CGPoint(x: item.position, y: visualItem.label.center.y)

        let newAlpha = self.calculateAlpha(baseOn: item.alpha)
        if abs(newAlpha - label.alpha) > 0.15 {
            UIView.animate(withDuration: 0.25) {
                label.alpha = newAlpha
            }
        } else {
            label.alpha = newAlpha
        }

        switch item.corner {
        case .right:
            label.center = CGPoint(x: item.position - visualItem.label.frame.width / 2, y: visualItem.label.center.y)
        case .left:
            label.center = CGPoint(x: item.position + visualItem.label.frame.width / 2, y: visualItem.label.center.y)
        case .none:
            label.center = CGPoint(x: item.position, y: visualItem.label.center.y)
        }
    }

    func show(items: [Item]) {
        let config = self.theme.configuration
        for item in items {
            let label = UILabel(frame: .zero)
            label.center = CGPoint(x: item.position, y: label.center.y)
            label.text = item.text
            label.font = UIFont.systemFont(ofSize: 12)
            label.textAlignment = .center
            label.textColor = config.titleColor
            label.alpha = self.calculateAlpha(baseOn: item.alpha)
            let size = label.sizeThatFits(CGSize(width: 10000, height: 50))
            label.frame.size = size
            self.addSubview(label)
            let visualItem = VisualItem(label: label, item: item)
            self.allItems.append(visualItem)
        }
    }

    func calculateAlpha(baseOn alpha: CGFloat) -> CGFloat {
        return alpha < 0.5 ? 0 : (alpha - 0.5) * 2
    }

    func disaper(item: Item) {
        guard let index = self.allItems.firstIndex(where: { $0.item == item }) else {
            return
        }
        let visualItem = self.allItems[index]
        self.allItems.remove(at: index)
        self.onRemoving.append(visualItem.label)

        UIView.animate(withDuration: 0.25, animations: {
            visualItem.label.alpha = 0
        }) { (success) in
            visualItem.label.removeFromSuperview()
        }
    }
}
