//
//  GraphDataSource.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 07/04/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class Transformer {
    enum Style {
        case none
        case multiplyer
        case append
        case appendPercent
    }

//    private var rows: [GraphLineRow] = []
//    private let style: Style
    var values: [[Int]] = []

    init(rows: [[Int]], style: Style) {
        switch style {
        case .none:
            self.setupNone(rows: rows)
        case .multiplyer:
            self.setupMultiplyer(rows: rows)
        case .append:
            self.setupAppend(rows: rows)
        case .appendPercent:
            self.setupAppendPercent(rows: rows)
        }
    }

    func setupNone(rows: [[Int]]) {
        self.values = rows.map({ $0 })
    }

    func setupMultiplyer(rows: [[Int]]) {
        var max: Int = 0
        for row in rows {
            let newMax = row.max() ?? 0
            if newMax > max {
                max = newMax
            }
        }

        for row in rows {
            let newMax = row.max() ?? 0
            let percent = CGFloat(max) / CGFloat(newMax)
            self.values.append(row.map({ Int(CGFloat($0) * percent) }))
        }
    }

    func setupAppend(rows: [[Int]]) {
        guard rows.count > 0 else {
            return
        }

        self.values = (0..<rows.count).map({ _ in [] })
        for index in 0..<rows[0].count {
            var offset = 0
            for (rowIndex, row) in rows.enumerated() {
                offset += row[index]
                self.values[rowIndex].append(offset)
            }
        }
    }

    func setupAppendPercent(rows: [[Int]]) {
        guard rows.count > 0 else {
            return
        }

        self.values = (0..<rows.count).map({ _ in [] })
        for index in 0..<rows[0].count {
            var sum: Int = 0
            for row in rows {
                sum += row[index]
            }

            var preverousValue: CGFloat = 0
            for (rowIndex, row) in rows.enumerated() {
                let value = row[index]
                let percent = CGFloat(value) / CGFloat(sum) * 100
                let newValue = preverousValue + percent
                preverousValue += percent
                self.values[rowIndex].append(Int(min(round(newValue), 100)))
            }
        }
    }
}

class GraphLineRow {
    var color: UIColor
    var name: String
    var values: [Int]
    var transformedValues: [Int] = []

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

