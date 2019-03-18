//
//  ThumbnailControl.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ThumbnailControl: UIControl {
    enum Gesture {
        case increaseLeft
        case increaseRight
        case move
        case none
    }

    private var beforeOverlay = UIView()
    private var endOverlay = UIView()
    private var controlImageView: UIImageView = {
        let image = UIImage(named: "img_control_full")!
        let insets = UIEdgeInsets(top: 16, left: 17, bottom: 16, right: 17)
        let strechingImage = image.resizableImage(withCapInsets: insets, resizingMode: .stretch)
        return UIImageView(image: strechingImage)
    }()

    private var gesture: Gesture = .none
    var range: Range<CGFloat> = 0..<1 {
        didSet {
            self.update()
            if oldValue != range {
                self.sendActions(for: .valueChanged)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.beforeOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.endOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.2)

        self.addSubview(self.beforeOverlay)
        self.addSubview(self.endOverlay)
        self.addSubview(self.controlImageView)

        self.update()
    }

    override var frame: CGRect {
        didSet {
            self.update()
        }
    }

    func update() {
        let width = self.frame.width
        let height = self.frame.height
        self.beforeOverlay.frame = CGRect(x: 0, y: 0, width: self.range.lowerBound * width, height: height)

        let lastWidth = width - self.range.upperBound * width
        self.endOverlay.frame = CGRect(x: self.range.upperBound * width, y: 0, width: lastWidth, height: height)

        self.controlImageView.frame = CGRect(x: self.beforeOverlay.frame.width, y: 0, width: self.endOverlay.frame.minX - self.beforeOverlay.frame.width, height: height)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        let locationX = touch.location(in: self).x
        let increaseLeftRange = (self.controlImageView.frame.minX - 16)..<(self.controlImageView.frame.minX + 20)
        let increaseMoveRange = (self.controlImageView.frame.minX + 20)..<(self.controlImageView.frame.maxX - 20)
        let increaseRightRange = (self.controlImageView.frame.maxX - 20)..<(self.controlImageView.frame.maxX + 16)

        if increaseLeftRange.contains(locationX) {
            self.gesture = .increaseLeft
        } else if increaseMoveRange.contains(locationX) {
            self.gesture = .move
        } else if increaseRightRange.contains(locationX) {
            self.gesture = .increaseRight
        } else {
            self.gesture = .none
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: self)
        let preveousLocation = touch.previousLocation(in: self)
        switch self.gesture {
        case .increaseLeft:
            let delta = (location.x - preveousLocation.x) / self.frame.width
            self.range = self.normalize(range: (self.range.lowerBound + delta)..<(self.range.upperBound), collapse: false)
        case .increaseRight:
            let delta = (location.x - preveousLocation.x) / self.frame.width
            self.range = self.normalize(range: (self.range.lowerBound)..<(self.range.upperBound + delta), collapse: false)
        case .move:
            let delta = (location.x - preveousLocation.x) / self.frame.width
            self.range = self.normalize(range: (self.range.lowerBound + delta)..<(self.range.upperBound + delta), collapse: true)
        case .none:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.gesture = .none
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.gesture = .none
    }

    func normalize(range: Range<CGFloat>, collapse: Bool) -> Range<CGFloat> {
        var collapseDelta: CGFloat = 0.2
        if collapse {
            collapseDelta = min((range.upperBound - range.lowerBound), 1)
        }
        var lower = min(max(range.lowerBound, 0), 1)
        var upper = min(max(range.upperBound, 0), 1)
        if upper - lower <= collapseDelta {
            let needToAdd = collapseDelta - (upper - lower)
            if upper <= collapseDelta {
                upper += needToAdd
            } else {
                lower -= needToAdd
            }
        }
        lower = min(max(lower, 0), 1)
        upper = min(max(upper, 0), 1)
        return lower..<upper
    }
}
