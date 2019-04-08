//
//  Theme.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 19/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

struct ThemeConfiguration {
    var isLight: Bool
    var mainBackgroundColor: UIColor
    var backgroundColor: UIColor
    var selectionColor: UIColor
    var nameColor: UIColor
    var titleColor: UIColor
    var lineColor: UIColor
    var controlOverlayColor: UIColor
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
        return Theme(style: .light)
    }

    static func setupConfiguration(style: Style) -> ThemeConfiguration {
        switch style {
        case .dark:
            return ThemeConfiguration(
                isLight: false,
                mainBackgroundColor: UIColor(hex: "1A222C"),
                backgroundColor: UIColor(hex: "242E3E"),
                selectionColor: UIColor(hex: "161C26"),
                nameColor: UIColor(hex: "FEFEFE"),
                titleColor: UIColor(hex: "5F6B7F"),
                lineColor: UIColor(hex: "171D24"),
                controlOverlayColor: UIColor(hex: "171E29").withAlphaComponent(0.6)
            )
        case .light:
            return ThemeConfiguration(
                isLight: true,
                mainBackgroundColor: UIColor(hex: "EFEFF4"),
                backgroundColor: UIColor(hex: "FEFEFE"),
                selectionColor: UIColor(hex: "D9D9D9"),
                nameColor: UIColor(hex: "000000"),
                titleColor: UIColor(hex: "6C6C71"),
                lineColor: UIColor(hex: "D1D3D4"),
                controlOverlayColor: UIColor(hex: "E1E9F3").withAlphaComponent(0.6)
            )
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
