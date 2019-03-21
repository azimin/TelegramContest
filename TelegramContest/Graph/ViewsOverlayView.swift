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
        let text: String
        let position: CGFloat

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
    var thresholdOptimization = ThresholdOptimization(elapsedTime: 0.02)

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

    func move(item: Item) {
        guard let index = self.allItems.firstIndex(where: { $0.item == item }) else {
            return
        }
        let visualItem = self.allItems[index]
        visualItem.label.center = CGPoint(x: item.position, y: visualItem.label.center.y)
    }

    func show(items: [Item]) {
        let config = self.theme.configuration
        for item in items {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 26))
            label.center = CGPoint(x: item.position, y: label.center.y)
            label.text = item.text
            label.font = UIFont.systemFont(ofSize: 12)
            label.textAlignment = .center
            label.textColor = config.titleColor
            self.addSubview(label)
            let visualItem = VisualItem(label: label, item: item)
            self.allItems.append(visualItem)
        }
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
