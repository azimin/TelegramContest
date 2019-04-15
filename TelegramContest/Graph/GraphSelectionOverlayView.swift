//
//  GraphSelectionOverlayView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 07/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

struct SelectOverlay {
    var color: UIColor
    var rect: CGRect
}

class GraphSelectionOverlayView: UIView {
    var overlayerLayer = CALayer()
    var shapeLayers: [CAShapeLayer] = []

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.layer.addSublayer(self.overlayerLayer)
    }

    override var frame: CGRect {
        didSet {
            self.overlayerLayer.frame = self.bounds
        }
    }

    var offset: CGFloat = 16

    func show(overlays: [SelectOverlay]) {
        self.shapeLayers.forEach({ $0.isHidden = false })
        while self.shapeLayers.count < overlays.count {
            let layer = CAShapeLayer()
            self.shapeLayers.append(layer)
            self.layer.insertSublayer(layer, above: self.overlayerLayer)
        }

        if self.shapeLayers.count > overlays.count {
            for i in (overlays.count)..<self.shapeLayers.count {
                self.shapeLayers[i].isHidden = true
            }
        }

        for (index, overlay) in overlays.enumerated() {
            let layer = self.shapeLayers[index]
            let newPath = UIBezierPath(rect: overlay.rect)
            layer.fillColor = overlay.color.cgColor
            layer.path = newPath.cgPath
        }

        self.alpha = 1
    }

    func hide(animated: Bool) {
        self.shapeLayers.forEach({ $0.isHidden = true })
        self.alpha = 0
    }
}
