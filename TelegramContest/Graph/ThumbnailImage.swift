//
//  ThumbnailImage.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 24/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ThumbnailImage {
    // Comment: Used paint code to generate bezier path code
    static func imageDraw(theme: Theme) -> UIImage? {
        let rect = CGRect(origin: .zero, size: CGSize(width: 44, height: 43))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        let fillColor = theme.configuration.scrollSelector
        let fillColor2 = UIColor(red: 0.996, green: 0.996, blue: 0.996, alpha: 1.000)

        context.saveGState()
        context.beginTransparencyLayer(auxiliaryInfo: nil)

        //// Clip Clip
        let clipPath = UIBezierPath()
        clipPath.move(to: CGPoint(x: 6.67, y: 0))
        clipPath.addLine(to: CGPoint(x: 10.67, y: 0))
        clipPath.addLine(to: CGPoint(x: 10.67, y: 42))
        clipPath.addLine(to: CGPoint(x: 6.67, y: 42))
        clipPath.addCurve(to: CGPoint(x: 0, y: 35.33), controlPoint1: CGPoint(x: 2.98, y: 42), controlPoint2: CGPoint(x: 0, y: 39.02))
        clipPath.addLine(to: CGPoint(x: 0, y: 6.67))
        clipPath.addCurve(to: CGPoint(x: 6.67, y: 0), controlPoint1: CGPoint(x: 0, y: 2.98), controlPoint2: CGPoint(x: 2.98, y: 0))
        clipPath.close()
        clipPath.usesEvenOddFillRule = true
        clipPath.addClip()


        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: -4.98, y: -5, width: 20.65, height: 52))
        fillColor.setFill()
        rectanglePath.fill()


        context.endTransparencyLayer()
        context.restoreGState()


        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 7.45, y: 18.49))
        bezier2Path.addCurve(to: CGPoint(x: 6.45, y: 17.36), controlPoint1: CGPoint(x: 8.11, y: 17.76), controlPoint2: CGPoint(x: 7.12, y: 16.63))
        bezier2Path.addLine(to: CGPoint(x: 3.2, y: 20.95))
        bezier2Path.addCurve(to: CGPoint(x: 3.2, y: 22.05), controlPoint1: CGPoint(x: 2.93, y: 21.25), controlPoint2: CGPoint(x: 2.93, y: 21.75))
        bezier2Path.addLine(to: CGPoint(x: 6.45, y: 25.63))
        bezier2Path.addCurve(to: CGPoint(x: 7.45, y: 24.5), controlPoint1: CGPoint(x: 7.12, y: 26.37), controlPoint2: CGPoint(x: 8.11, y: 25.27))
        bezier2Path.addLine(to: CGPoint(x: 4.71, y: 21.51))
        bezier2Path.addLine(to: CGPoint(x: 7.45, y: 18.49))
        bezier2Path.close()
        bezier2Path.usesEvenOddFillRule = true
        fillColor2.setFill()
        bezier2Path.fill()


        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 38.33, y: 0))
        bezier3Path.addLine(to: CGPoint(x: 34.33, y: 0))
        bezier3Path.addLine(to: CGPoint(x: 34.33, y: 42))
        bezier3Path.addLine(to: CGPoint(x: 38.33, y: 42))
        bezier3Path.addCurve(to: CGPoint(x: 45, y: 35.33), controlPoint1: CGPoint(x: 42.02, y: 42), controlPoint2: CGPoint(x: 45, y: 39.02))
        bezier3Path.addLine(to: CGPoint(x: 45, y: 6.67))
        bezier3Path.addCurve(to: CGPoint(x: 38.33, y: 0), controlPoint1: CGPoint(x: 45, y: 2.98), controlPoint2: CGPoint(x: 42.02, y: 0))
        bezier3Path.close()
        bezier3Path.usesEvenOddFillRule = true
        fillColor.setFill()
        bezier3Path.fill()


        //// Bezier 4 Drawing
        let bezier4Path = UIBezierPath()
        bezier4Path.move(to: CGPoint(x: 38.22, y: 18.49))
        bezier4Path.addCurve(to: CGPoint(x: 39.21, y: 17.36), controlPoint1: CGPoint(x: 37.56, y: 17.76), controlPoint2: CGPoint(x: 38.55, y: 16.63))
        bezier4Path.addLine(to: CGPoint(x: 42.46, y: 20.95))
        bezier4Path.addCurve(to: CGPoint(x: 42.46, y: 22.05), controlPoint1: CGPoint(x: 42.73, y: 21.25), controlPoint2: CGPoint(x: 42.73, y: 21.75))
        bezier4Path.addLine(to: CGPoint(x: 39.21, y: 25.63))
        bezier4Path.addCurve(to: CGPoint(x: 38.22, y: 24.5), controlPoint1: CGPoint(x: 38.55, y: 26.37), controlPoint2: CGPoint(x: 37.56, y: 25.27))
        bezier4Path.addLine(to: CGPoint(x: 40.96, y: 21.51))
        bezier4Path.addLine(to: CGPoint(x: 38.22, y: 18.49))
        bezier4Path.close()
        bezier4Path.usesEvenOddFillRule = true
        fillColor2.setFill()
        bezier4Path.fill()


        //// Bezier 5 Drawing
        let bezier5Path = UIBezierPath()
        bezier5Path.move(to: CGPoint(x: 10.67, y: 0))
        bezier5Path.addLine(to: CGPoint(x: 34.33, y: 0))
        bezier5Path.addLine(to: CGPoint(x: 34.33, y: 1.01))
        bezier5Path.addLine(to: CGPoint(x: 10.67, y: 1.01))
        bezier5Path.addLine(to: CGPoint(x: 10.67, y: 0))
        bezier5Path.close()
        bezier5Path.usesEvenOddFillRule = true
        fillColor.setFill()
        bezier5Path.fill()


        //// Bezier 6 Drawing
        let bezier6Path = UIBezierPath()
        bezier6Path.move(to: CGPoint(x: 10.67, y: 40.99))
        bezier6Path.addLine(to: CGPoint(x: 34.33, y: 40.99))
        bezier6Path.addLine(to: CGPoint(x: 34.33, y: 42))
        bezier6Path.addLine(to: CGPoint(x: 10.67, y: 42))
        bezier6Path.addLine(to: CGPoint(x: 10.67, y: 40.99))
        bezier6Path.close()
        bezier6Path.usesEvenOddFillRule = true
        fillColor.setFill()
        bezier6Path.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}
