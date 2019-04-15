//
//  Theme.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 19/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class ThemeConfiguration {
    let isLight: Bool
    let mainBackgroundColor: UIColor
    let backgroundColor: UIColor
    let selectionColor: UIColor
    let nameColor: UIColor
    let scrollBackground: UIColor
    let scrollSelector: UIColor
    let zoomOutText: UIColor
    let gridLines: UIColor
    let tooltipArrow: UIColor
    let axisTextColor: UIColor
    let axisTextColor2: UIColor
    let sectionColor: UIColor

    init(isLight: Bool, mainBackgroundColor: UIColor, backgroundColor: UIColor, selectionColor: UIColor, nameColor: UIColor, scrollBackground: UIColor, scrollSelector: UIColor, zoomOutText: UIColor, gridLines: UIColor, tooltipArrow: UIColor, axisTextColor: UIColor, axisTextColor2: UIColor, sectionColor: UIColor) {
        self.isLight = isLight
        self.mainBackgroundColor = mainBackgroundColor
        self.backgroundColor = backgroundColor
        self.selectionColor = selectionColor
        self.nameColor = nameColor
        self.scrollBackground = scrollBackground
        self.scrollSelector = scrollSelector
        self.zoomOutText = zoomOutText
        self.gridLines = gridLines
        self.tooltipArrow = tooltipArrow
        self.axisTextColor = axisTextColor
        self.axisTextColor2 = axisTextColor2
        self.sectionColor = sectionColor
    }
}

class Theme: Equatable {
    enum Style {
        case light, dark
    }

    let configuration: ThemeConfiguration
    let style: Style

    init(style: Style) {
        self.style = style
        self.configuration = Theme.setupConfiguration(style: style)
    }

    static var `default`: Theme {
        return Theme(style: .dark)
    }

    static var nightConfiguration: ThemeConfiguration = {
        return ThemeConfiguration(
            isLight: false,
            mainBackgroundColor: UIColor(hex: "1A222C"),
            backgroundColor: UIColor(hex: "242E3E"),
            selectionColor: UIColor(hex: "161C26"),
            nameColor: UIColor(hex: "FEFEFE"),
            scrollBackground: UIColor(hex: "18222D").withAlphaComponent(0.6),
            scrollSelector: UIColor(hex: "56626D"),
            zoomOutText: UIColor(hex: "2EA6FE"),
            gridLines: UIColor(hex: "8596AB").withAlphaComponent(0.2),
            tooltipArrow: UIColor(hex: "D2D5D7"),
            axisTextColor: UIColor(hex: "8596AB"),
            axisTextColor2: UIColor(hex: "BACCE1").withAlphaComponent(0.6),
            sectionColor: UIColor(hex: "8895A9")
        )
    }()

    static var dayConfiguration: ThemeConfiguration = {
        return ThemeConfiguration(
            isLight: true,
            mainBackgroundColor: UIColor(hex: "EFEFF4"),
            backgroundColor: UIColor(hex: "FEFEFE"),
            selectionColor: UIColor(hex: "D9D9D9"),
            nameColor: UIColor(hex: "000000"),
            scrollBackground: UIColor(hex: "E2EEF9").withAlphaComponent(0.6),
            scrollSelector: UIColor(hex: "C0D1E1"),
            zoomOutText: UIColor(hex: "108BE3"),
            gridLines: UIColor(hex: "182D3B").withAlphaComponent(0.1),
            tooltipArrow: UIColor(hex: "59606D").withAlphaComponent(0.3),
            axisTextColor: UIColor(hex: "8E8E93"),
            axisTextColor2: UIColor(hex: "252529").withAlphaComponent(0.5),
            sectionColor: UIColor(hex: "6D6D72")
        )
    }()

    static func setupConfiguration(style: Style) -> ThemeConfiguration {
        switch style {
        case .light:
            return self.dayConfiguration
        case .dark:
            return self.nightConfiguration
        }
    }

    static func == (lhs: Theme, rhs: Theme) -> Bool {
        return lhs.style == rhs.style
    }
}

extension UIFont {
    enum Wight {
        case light
        case regular
        case medium
        case bold
        case heavy
    }

    static func font(with wight: Wight, size: CGFloat) -> UIFont {
        switch wight {
        case .bold:
            return UIFont.systemFont(ofSize: size, weight: .bold)
        case .regular:
            return UIFont.systemFont(ofSize: size, weight: .regular)
        case .medium:
            return UIFont.systemFont(ofSize: size, weight: .medium)
        case .light:
            return UIFont.systemFont(ofSize: size, weight: .thin)
        case .heavy:
            return UIFont.systemFont(ofSize: size, weight: .heavy)
        }
    }
}
