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
    var nameColor: UIColor
    var titleColor: UIColor
    var lineColor: UIColor
}

enum Theme {
    case light, dark

    var configuration: ThemeConfiguration {
        switch self {
        case .dark:
            return ThemeConfiguration(
                isLight: false,
                mainBackgroundColor: UIColor(hex: "1A222C"),
                backgroundColor: UIColor(hex: "242E3E"),
                nameColor: UIColor(hex: "FEFEFE"),
                titleColor: UIColor(hex: "5F6B7F"),
                lineColor: UIColor(hex: "171D24")
            )
        case .light:
            return ThemeConfiguration(
                isLight: true,
                mainBackgroundColor: UIColor(hex: "EFEFF4"),
                backgroundColor: UIColor(hex: "FEFEFE"),
                nameColor: UIColor(hex: "000000"),
                titleColor: UIColor(hex: "6C6C71"),
                lineColor: UIColor(hex: "D1D3D4")
            )
        }
    }
}
