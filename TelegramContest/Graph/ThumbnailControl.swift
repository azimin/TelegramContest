//
//  ThumbnailControl.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ThumbnailControl: UIControl {
    enum Constants {
        static var graphHeight: CGFloat = 38
        static var offset: CGFloat = 16
    }

    enum Gesture {
        case increaseLeft
        case increaseRight
        case move
        case none
    }

    private var beforeOverlay = UIView()
    private var endOverlay = UIView()
    private var controlImageView: UIImageView = UIImageView()

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.beforeOverlay.backgroundColor = config.backgroundColor.withAlphaComponent(0.7)
            self.endOverlay.backgroundColor = config.backgroundColor.withAlphaComponent(0.7)

            let image = ThumbnailImage.imageDraw(isLight: config.isLight)
            let insets = UIEdgeInsets(top: 16, left: 17, bottom: 16, right: 17)
            let strechingImage = image?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
            controlImageView.image = strechingImage
        }
    }
    private(set) var gesture: Gesture = .none {
        didSet {
            switch gesture {
            case .increaseLeft, .increaseRight, .move:
                self.sendActions(for: .editingDidBegin)
            case .none:
                self.sendActions(for: .editingDidEnd)
            }
        }
    }

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
        self.beforeOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.endOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)

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
        let offset = Constants.offset
        let width = self.frame.width - offset * 2
        let height = self.frame.height
        let topSpace = (self.frame.height - Constants.graphHeight) / 2

        self.beforeOverlay.frame = CGRect(x: offset, y: topSpace, width: self.range.lowerBound * width, height: Constants.graphHeight)

        let lastWidth = width - self.range.upperBound * width
        self.endOverlay.frame = CGRect(x: offset + self.range.upperBound * width, y: topSpace, width: lastWidth, height: Constants.graphHeight)

        self.controlImageView.frame = CGRect(x: offset + self.beforeOverlay.frame.width, y: 0, width: self.endOverlay.frame.minX - self.beforeOverlay.frame.width - offset, height: height)
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
        let delta = (location.x - preveousLocation.x) / self.frame.width
        switch self.gesture {
        case .increaseLeft:
            if range.lowerBound + delta < self.range.upperBound {
                self.range = self.normalize(range: (self.range.lowerBound + delta)..<(self.range.upperBound), collapse: false, movingRight: false)
            }
        case .increaseRight:
            if self.range.lowerBound < self.range.upperBound + delta {
                self.range = self.normalize(range: (self.range.lowerBound)..<(self.range.upperBound + delta), collapse: false, movingRight: true)
            }
        case .move:
            if self.range.lowerBound + delta < self.range.upperBound + delta {
                self.range = self.normalize(range: (self.range.lowerBound + delta)..<(self.range.upperBound + delta), collapse: true, movingRight: false)
            }
        case .none:
            break
        }
    }

    func shouldMove(range: Range<CGFloat>, delta: CGFloat) -> Bool {
        return range.lowerBound + delta < self.range.upperBound
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.gesture = .none
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.gesture = .none
    }

    func normalize(range: Range<CGFloat>, collapse: Bool, movingRight: Bool) -> Range<CGFloat> {
        var collapseDelta: CGFloat = 0.2
        if collapse {
            collapseDelta = min((range.upperBound - range.lowerBound), 1)
        }
        var lower = min(max(range.lowerBound, 0), 1)
        var upper = min(max(range.upperBound, 0), 1)
        if upper - lower < collapseDelta {
            let needToAdd = collapseDelta - (upper - lower)
            if upper <= collapseDelta || movingRight {
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
