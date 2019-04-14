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

    var theme: Theme = .default {
        didSet {
            let config = theme.configuration
            self.backgroundColor = config.backgroundColor
            self.allItems.forEach({ $0.label.textColor = config.axisTextColor; $0.label.backgroundColor = config.backgroundColor })
        }
    }

    private var allItems: [VisualItem] = []
    private var onRemoving: [UILabel] = []
    private var labelsToReuse: [UILabel] = []
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

        label.center = CGPoint(x: item.position, y: visualItem.label.center.y)
        //        switch item.corner {
        //        case .right:
        //            label.center = CGPoint(x: item.position - visualItem.label.frame.width / 2, y: visualItem.label.center.y)
        //        case .left:
        //            label.center = CGPoint(x: item.position + visualItem.label.frame.width / 2, y: visualItem.label.center.y)
        //        case .none:
        //            label.center = CGPoint(x: item.position, y: visualItem.label.center.y)
        //        }
    }

    func show(items: [Item]) {
        let config = self.theme.configuration
        for item in items {
            let label: UILabel
            if self.labelsToReuse.isEmpty {
                label = UILabel()
            } else {
                label = self.labelsToReuse.removeLast()
                if let index = self.onRemoving.firstIndex(of: label) {
                    self.onRemoving.remove(at: index)
                }
                label.frame = .zero
                label.isHidden = false
                label.alpha = 1
            }
            label.text = item.text
            label.font = UIFont.systemFont(ofSize: 12)
            label.textAlignment = .center
            label.textColor = config.axisTextColor
            label.backgroundColor = config.backgroundColor
            label.alpha = self.calculateAlpha(baseOn: item.alpha)
            let size = label.sizeThatFits(CGSize(width: 10000, height: 50))
            label.frame.size = size
            label.center = CGPoint(x: item.position, y: label.center.y)
            self.addSubview(label)
            let visualItem = VisualItem(label: label, item: item)
            self.allItems.append(visualItem)
        }
    }

    func calculateAlpha(baseOn alpha: CGFloat) -> CGFloat {
        return alpha < 0.8 ? 0 : (alpha - 0.8) * 5
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
            self.labelsToReuse.append(visualItem.label)
            visualItem.label.removeFromSuperview()
        }
    }

    func animateForceZoomOut(position: CGFloat, reversed: Bool) {
        var selectedIndex: Int = 0
        var distance: CGFloat = 1000
        let allItems = self.allItems

        for (index, item) in self.allItems.enumerated() {
            let itemDistance = abs(item.label.center.x - position)
            if itemDistance < distance {
                distance = itemDistance
                selectedIndex = index
            }
        }

        var labelsToShow: [UILabel] = []
        var labelsToRemove: [UILabel] = []
        var xPositions: [CGFloat] = []

        for (index, item) in self.allItems.enumerated() {
            if item.label.alpha > 0 {
                labelsToShow.append(item.label)
                xPositions.append(item.label.center.x)
                if reversed {
                    let distance = (abs(CGFloat(selectedIndex - index) / 3) + 1)
                    if index < selectedIndex {
                        item.label.center.x -= distance * self.frame.width
                    } else if index > selectedIndex {
                        item.label.center.x += distance * self.frame.width
                    }
                    item.label.alpha = 0
                }
            } else {
                labelsToRemove.append(item.label)
                xPositions.append(item.label.center.x)
            }
        }

        UIView.animate(withDuration: 0.3, animations: {
            for (index, item) in self.allItems.enumerated() {
                if !labelsToShow.contains(item.label) {
                    continue
                }

                if reversed {
                    let oldPosition = xPositions[index]
                    item.label.center.x = oldPosition
                    item.label.alpha = 1
                } else {
                    let distance = (abs(CGFloat(selectedIndex - index) / 3) + 1)
                    if index < selectedIndex {
                        item.label.center.x -= distance * self.frame.width
                    } else if index > selectedIndex {
                        item.label.center.x += distance * self.frame.width
                    }
                    item.label.alpha = 0
                }
            }
            if !reversed {
                self.allItems = []
            }
        }) { (_) in
            if !reversed {
                allItems.forEach({ self.labelsToReuse.append($0.label) })
                allItems.forEach({ $0.label.removeFromSuperview() })
            }
        }
    }

    func animateForceZoomIn(position: CGFloat, reversed: Bool) {
        var xPositions: [CGFloat] = []
        var labelsToShow: [UILabel] = []

        for item in self.allItems {
            if item.label.alpha > 0 {
                xPositions.append(item.label.center.x)
                labelsToShow.append(item.label)
                if !reversed {
                    item.label.center.x = position
                    item.label.alpha = 0
                }
            }
        }

        let allItems = self.allItems
        UIView.animate(withDuration: 0.3, animations: {
            for (index, label) in labelsToShow.enumerated() {
                if reversed {
                    label.center.x = position
                    label.alpha = 0
                    self.allItems = []
                } else {
                    let oldPosition = xPositions[index]
                    label.center.x = oldPosition
                    label.alpha = 1
                }
            }
        }, completion: { _ in
            if reversed {
                allItems.forEach({ self.labelsToReuse.append($0.label) })
                allItems.forEach({ $0.label.removeFromSuperview() })
            }
        })
    }
}
