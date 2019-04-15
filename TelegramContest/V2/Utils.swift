//
//  Utils.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 12/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

func converValues<T>(values: [T], range: Range<CGFloat>, rounded: Bool, appendOffset: Int = 0) -> [T] {
    let index = convertIndexes(count: values.count, range: range, rounded: rounded, appendOffset: appendOffset)
    return Array(values[index])
}

func convertIndexes(count: Int, range: Range<CGFloat>, rounded: Bool, appendOffset: Int = 0) -> Range<Int> {
    let firstCount: Int
    let endCount: Int
    if rounded {
        firstCount = Int(round(range.lowerBound * CGFloat(count)))
        endCount = Int(round(range.upperBound * CGFloat(count)))
    } else {
        firstCount = Int(floor(range.lowerBound * CGFloat(count)))
        endCount = Int(ceil(range.upperBound * CGFloat(count)))
    }
    return min(max(firstCount - appendOffset, 0), count - 1)..<min(endCount + appendOffset, count)
}
