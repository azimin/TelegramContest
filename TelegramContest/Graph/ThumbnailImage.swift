//
//  ThumbnailImage.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 24/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ThumbnailImage {
    // Comment: Used paint code to generate image
    static func imageDraw() -> UIImage? {
        let rect = CGRect(origin: .zero, size: CGSize(width: 44, height: 43))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        let fillColor = UIColor(red: 0.501, green: 0.632, blue: 0.740, alpha: 0.300)
        let fillColor2 = UIColor(red: 0.996, green: 0.996, blue: 0.996, alpha: 1.000)

        context.saveGState()
        context.beginTransparencyLayer(auxiliaryInfo: nil)

        let clipPath = UIBezierPath()
        clipPath.move(to: CGPoint(x: 1.34, y: 0))
        clipPath.addLine(to: CGPoint(x: 10.67, y: 0))
        clipPath.addLine(to: CGPoint(x: 10.67, y: 43))
        clipPath.addLine(to: CGPoint(x: 1.34, y: 43))
        clipPath.addCurve(to: CGPoint(x: 0, y: 41.66), controlPoint1: CGPoint(x: 0.6, y: 43), controlPoint2: CGPoint(x: 0, y: 42.4))
        clipPath.addLine(to: CGPoint(x: 0, y: 1.34))
        clipPath.addCurve(to: CGPoint(x: 1.34, y: 0), controlPoint1: CGPoint(x: 0, y: 0.6), controlPoint2: CGPoint(x: 0.6, y: 0))
        clipPath.close()
        clipPath.usesEvenOddFillRule = true
        clipPath.addClip()

        let rectanglePath = UIBezierPath(rect: CGRect(x: -4.98, y: -5, width: 20.65, height: 53))
        fillColor.setFill()
        rectanglePath.fill()

        context.endTransparencyLayer()
        context.restoreGState()

        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 7.45, y: 17.8))
        bezier2Path.addCurve(to: CGPoint(x: 6.45, y: 16.42), controlPoint1: CGPoint(x: 8.11, y: 16.91), controlPoint2: CGPoint(x: 7.12, y: 15.52))
        bezier2Path.addLine(to: CGPoint(x: 3.2, y: 20.82))
        bezier2Path.addCurve(to: CGPoint(x: 3.2, y: 22.17), controlPoint1: CGPoint(x: 2.93, y: 21.19), controlPoint2: CGPoint(x: 2.93, y: 21.8))
        bezier2Path.addLine(to: CGPoint(x: 6.45, y: 26.58))
        bezier2Path.addCurve(to: CGPoint(x: 7.45, y: 25.19), controlPoint1: CGPoint(x: 7.12, y: 27.48), controlPoint2: CGPoint(x: 8.11, y: 26.13))
        bezier2Path.addLine(to: CGPoint(x: 4.71, y: 21.52))
        bezier2Path.addLine(to: CGPoint(x: 7.45, y: 17.8))
        bezier2Path.close()
        bezier2Path.usesEvenOddFillRule = true
        fillColor2.setFill()
        bezier2Path.fill()

        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 42.66, y: 0))
        bezier3Path.addLine(to: CGPoint(x: 33.33, y: 0))
        bezier3Path.addLine(to: CGPoint(x: 33.33, y: 43))
        bezier3Path.addLine(to: CGPoint(x: 42.66, y: 43))
        bezier3Path.addCurve(to: CGPoint(x: 44, y: 41.66), controlPoint1: CGPoint(x: 43.4, y: 43), controlPoint2: CGPoint(x: 44, y: 42.4))
        bezier3Path.addLine(to: CGPoint(x: 44, y: 1.34))
        bezier3Path.addCurve(to: CGPoint(x: 42.66, y: 0), controlPoint1: CGPoint(x: 44, y: 0.6), controlPoint2: CGPoint(x: 43.4, y: 0))
        bezier3Path.close()
        bezier3Path.usesEvenOddFillRule = true
        fillColor.setFill()
        bezier3Path.fill()

        let bezier4Path = UIBezierPath()
        bezier4Path.move(to: CGPoint(x: 36.55, y: 17.8))
        bezier4Path.addCurve(to: CGPoint(x: 37.55, y: 16.42), controlPoint1: CGPoint(x: 35.89, y: 16.91), controlPoint2: CGPoint(x: 36.88, y: 15.52))
        bezier4Path.addLine(to: CGPoint(x: 40.8, y: 20.82))
        bezier4Path.addCurve(to: CGPoint(x: 40.8, y: 22.17), controlPoint1: CGPoint(x: 41.07, y: 21.19), controlPoint2: CGPoint(x: 41.07, y: 21.8))
        bezier4Path.addLine(to: CGPoint(x: 37.55, y: 26.58))
        bezier4Path.addCurve(to: CGPoint(x: 36.55, y: 25.19), controlPoint1: CGPoint(x: 36.88, y: 27.48), controlPoint2: CGPoint(x: 35.89, y: 26.13))
        bezier4Path.addLine(to: CGPoint(x: 39.29, y: 21.52))
        bezier4Path.addLine(to: CGPoint(x: 36.55, y: 17.8))
        bezier4Path.close()
        bezier4Path.usesEvenOddFillRule = true
        fillColor2.setFill()
        bezier4Path.fill()

        let bezier5Path = UIBezierPath()
        bezier5Path.move(to: CGPoint(x: 10.67, y: -0))
        bezier5Path.addLine(to: CGPoint(x: 33.33, y: -0))
        bezier5Path.addLine(to: CGPoint(x: 33.33, y: 1.01))
        bezier5Path.addLine(to: CGPoint(x: 10.67, y: 1.01))
        bezier5Path.addLine(to: CGPoint(x: 10.67, y: -0))
        bezier5Path.close()
        bezier5Path.usesEvenOddFillRule = true
        fillColor.setFill()
        bezier5Path.fill()

        let bezier6Path = UIBezierPath()
        bezier6Path.move(to: CGPoint(x: 10.67, y: 41.99))
        bezier6Path.addLine(to: CGPoint(x: 33.33, y: 41.99))
        bezier6Path.addLine(to: CGPoint(x: 33.33, y: 43))
        bezier6Path.addLine(to: CGPoint(x: 10.67, y: 43))
        bezier6Path.addLine(to: CGPoint(x: 10.67, y: 41.99))
        bezier6Path.close()
        bezier6Path.usesEvenOddFillRule = true
        fillColor.setFill()
        bezier6Path.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}
