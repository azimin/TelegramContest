//
//  ThumbnailControl.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ThumbnailControl: UIControl {
    private enum Constants {
        static var graphHeight: CGFloat = 38
        static var offset: CGFloat = 16
    }

    enum Gesture {
        case increaseLeft
        case increaseRight
        case move
        case none
    }

    private var beforeOverlay = CAShapeLayer()
    private var endOverlay = CAShapeLayer()
    private var controlImageView: UIImageView = UIImageView()

    var theme: Theme = .default {
        didSet {
            let config = theme.configuration
            self.beforeOverlay.fillColor = config.scrollBackground.cgColor
            self.endOverlay.fillColor = config.scrollBackground.cgColor

            let image = ThumbnailImage.imageDraw(theme: self.theme)
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

    private(set) var range: Range<CGFloat> = 0..<1
    var pagingDelta: CGFloat?

    func update(range: Range<CGFloat>, animated: Bool) {
        guard self.range != range else {
            return
        }
        self.range = range
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.update()
            }
        } else {
            self.update()
        }
        self.sendActions(for: .valueChanged)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
//        self.beforeOverlay.backgroundColor = UIColor.clear
//        self.endOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)

//        self.beforeOverlay.layer.cornerRadius = 6
//        self.endOverlay.layer.cornerRadius = 6

        self.layer.addSublayer(self.beforeOverlay)
        self.layer.addSublayer(self.endOverlay)
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

        let rect1 = CGRect(x: offset, y: topSpace, width: self.range.lowerBound * width + 10, height: Constants.graphHeight)
        if rect1.origin.y < 0 {
            return
        }

        let path1 = CGPath(roundedRect: rect1, cornerWidth: 5, cornerHeight: 6, transform: nil)
        self.beforeOverlay.path = path1

        let lastWidth = width - self.range.upperBound * width

        let rect2 = CGRect(x: offset + self.range.upperBound * width - 10, y: topSpace, width: lastWidth + 10, height: Constants.graphHeight)
        let path2 = CGPath(roundedRect: rect2, cornerWidth: 5, cornerHeight: 6, transform: nil)
        self.endOverlay.path = path2

        self.controlImageView.frame = CGRect(x: offset + rect1.width - 10, y: 0, width: rect2.minX - rect1.width - offset + 20, height: height)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        let lentgh = self.range.interval * self.frame.width
        let range = min((lentgh / 4), 40)
        let innerRange = max(range, 30)

        let locationX = touch.location(in: self).x
        let increaseLeftRange = self.normalizeRange(
            start: self.controlImageView.frame.minX - innerRange,
            finish: self.controlImageView.frame.minX + range
        )
        let increaseMoveRange = self.normalizeRange(
            start: self.controlImageView.frame.minX + range,
            finish: self.controlImageView.frame.maxX - range
        )
        let increaseRightRange = self.normalizeRange(
            start: self.controlImageView.frame.maxX - range,
            finish: self.controlImageView.frame.maxX + innerRange
        )

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

    private func normalizeRange(start: CGFloat, finish: CGFloat) -> Range<CGFloat> {
        let newFinish = max(start + 1, finish)
        return start..<newFinish
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
                let range = self.normalize(range: (self.range.lowerBound + delta)..<(self.range.upperBound), collapse: false, movingRight: false)
                self.update(range: range, animated: false)
            }
        case .increaseRight:
            if self.range.lowerBound < self.range.upperBound + delta {
                let range = self.normalize(range: (self.range.lowerBound)..<(self.range.upperBound + delta), collapse: false, movingRight: true)
                self.update(range: range, animated: false)
            }
        case .move:
            if self.range.lowerBound + delta < self.range.upperBound + delta {
                let range = self.normalize(range: (self.range.lowerBound + delta)..<(self.range.upperBound + delta), collapse: true, movingRight: false)
                self.update(range: range, animated: false)
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
        self.finishTransition()
        self.gesture = .none
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.finishTransition()
        self.gesture = .none
    }

    func finishTransition() {
        guard let paging = self.pagingDelta else {
            return
        }

        let lower = self.range.lowerBound
        let interval = self.range.interval

        let lowerInt = Int(lower * 1000)
        let intervalInt = Int(interval * 1000)
        let pagingInt = Int(paging * 1000)

        let lowerFit = CGFloat(findNearAdvanced(value: lowerInt, devidedBy: pagingInt, negativeRestricted: false)) / 1000
        let intervalFit = CGFloat(findNearAdvanced(value: intervalInt, devidedBy: pagingInt, negativeRestricted: true)) / 1000

        let range = self.normalize(range: lowerFit..<(lowerFit + intervalFit), collapse: false, movingRight: false)
        self.update(range: range, animated: true)
    }

    private func findNearAdvanced(value: Int, devidedBy: Int, negativeRestricted: Bool) -> Int {
        let fitPos = findNear(value: value, positive: true, devidedBy: devidedBy)
        let fitNeg = findNear(value: value, positive: false, devidedBy: devidedBy)

        let fit: Int
        if abs(fitPos - value) > abs(value - fitNeg) && (!negativeRestricted || fitNeg > 0) {
            fit = fitNeg
        } else {
            fit = fitPos
        }

        return fit
    }

    func normalize(range: Range<CGFloat>, collapse: Bool, movingRight: Bool) -> Range<CGFloat> {
        var collapseDelta: CGFloat = self.pagingDelta ?? 0.1
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

//class CornerView: UIView {
//    var drawRect: CGRect = .zero
//
//    override func draw(_ rect: CGRect) {
//        let path = UIBezierPath(ovalIn: drawRect)
//        UIColor.green.withAlphaComponent(0.5).setFill()
//        path.fill()
//    }
//}
