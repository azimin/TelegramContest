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
    private var showAction: (() -> Void)?
    private var startTime = 0.0
    private var displayLink: CADisplayLink?

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

        self.show(items: newItems)

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
        self.showAction = {
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
            self.showAction = nil
            self.displayLink?.invalidate()
            self.displayLink = nil
        }

        if displayLink == nil {
            self.startTime = CACurrentMediaTime()
            self.displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidFire(_:)))
            self.displayLink?.add(to: .main, forMode: .common)
        }
    }

    @objc
    func displayLinkDidFire(_ displayLink: CADisplayLink) {
        let elapsed = CACurrentMediaTime() - self.startTime

        if elapsed > 0.02 {
            self.showAction?()
            self.displayLink?.invalidate()
            self.displayLink = nil
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
