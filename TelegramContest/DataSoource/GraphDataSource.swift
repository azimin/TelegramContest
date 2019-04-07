//
//  GraphDataSource.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 07/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class GraphLineRow {
    var color: UIColor
    var name: String
    var values: [Int]

    init(color: UIColor, name: String, values: [Int]) {
        self.color = color
        self.name = name
        self.values = values
    }
}

class GraphXRow {
    var dates: [Date]
    var dateStrings: [String]

    init(dates: [Date]) {
        self.dates = dates

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        self.dateStrings = dates.map({ dateFormatter.string(from: $0) })
    }
}

class Section {
    var dataSource: GraphDataSource
    var selectedRange: Range<CGFloat>
    var zoomStep: Int?
    var enabledRows: [Int]

    init(dataSource: GraphDataSource, selectedRange: Range<CGFloat>, enabledRows: [Int]) {
        self.dataSource = dataSource
        self.selectedRange = selectedRange
        self.enabledRows = enabledRows
        self.zoomStep = nil
    }
}

class GraphDataSource {
    let xRow: GraphXRow
    let yRows: [GraphLineRow]

    init(xRow: GraphXRow, yRows: [GraphLineRow]) {
        self.xRow = xRow
        self.yRows = yRows
    }

    init?(json: [String: Any]) {
        var lineRows: [GraphLineRow] = []
        var types: [String: String] =  (json["types"] as? [String: String]) ?? [:]
        var names: [String: String] = (json["names"] as? [String: String]) ?? [:]
        var colors: [String: UIColor] =  ((json["colors"] as? [String: String]) ?? [:]).mapValues({ return UIColor(hex: $0 )})

        var xRow: GraphXRow?

        if let columns = json["columns"] as? [[AnyObject]] {
            for column in columns {
                var name: String?
                var values: [Int64] = []
                for row in column {
                    if let nameValue = row as? String {
                        name = nameValue
                    } else if let value = row as? Int64 {
                        values.append(value)
                    }
                }
                if let name = name {
                    if let type = types[name] {
                        switch type {
                        case "line":
                            if let color = colors[name], let realName = names[name] {
                                let lineRow = GraphLineRow(color: color, name: realName, values: values.map({ Int($0) }))
                                lineRows.append(lineRow)
                            }
                        case "x":
                            let dates = values.map({ Date(timeIntervalSince1970: TimeInterval($0 / 1000)) })
                            xRow = GraphXRow(dates: dates)
                        default:
                            break
                        }
                    }
                }
            }
        }

        if let xRow = xRow, xRow.dates.count > 0, lineRows.count > 0 {
            self.xRow = xRow
            self.yRows = lineRows
        } else {
            return nil
        }
    }
}

