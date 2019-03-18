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

    var allItems: [VisualItem] = []

    func showItems(items: [Item]) {
        var newItems: [Item] = items
        for item in self.allItems.map({ $0.item }) {
            if let index = items.firstIndex(of: item) {
                newItems.removeAll(where: { $0 == item })
                self.move(item: items[index])
            } else {
                self.disaper(item: item)
            }
        }

        for item in newItems {
            self.show(item: item)
        }
    }

    func move(item: Item) {
        guard let index = self.allItems.firstIndex(where: { $0.item == item }) else {
            return
        }
        let visualItem = self.allItems[index]
        visualItem.label.center = CGPoint(x: item.position, y: visualItem.label.center.y)
    }

    func show(item: Item) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        label.center = CGPoint(x: item.position, y: label.center.y)
        label.text = item.text
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        self.addSubview(label)
        let visualItem = VisualItem(label: label, item: item)
        self.allItems.append(visualItem)
    }

    func disaper(item: Item) {
        guard let index = self.allItems.firstIndex(where: { $0.item == item }) else {
            return
        }
        let visualItem = self.allItems[index]
        self.allItems.remove(at: index)

        UIView.animate(withDuration: 0.1, animations: {
            visualItem.label.alpha = 0
        }) { (success) in
            visualItem.label.removeFromSuperview()
        }
    }
}
