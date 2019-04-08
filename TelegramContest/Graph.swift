//
//  Graph.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 07/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import Foundation

enum GraphStyle: String {
    case basic
    case doubleCompare
    case stackedBar
    case percentStackedBar

    var transformerStyle: Transformer.Style {
        switch self {
        case .basic:
            return .none
        case .doubleCompare:
            return .multiplyer
        case .stackedBar:
            return .append
        case .percentStackedBar:
            return .appendPercent
        }
    }

    var drawStyle: GraphContext.Style {
        switch self {
        case .basic:
            return .graph
        case .doubleCompare:
            return .graph
        case .stackedBar:
            return .bar
        case .percentStackedBar:
            return .area
        }
    }
}
