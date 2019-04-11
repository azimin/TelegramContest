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
    var coeficent: CGFloat?

    init(rows: [[Int]], visibleRows: [Int], style: Style) {
        switch style {
        case .none:
            self.setupNone(rows: rows, visibleRows: visibleRows)
        case .multiplyer:
            self.setupMultiplyer(rows: rows, visibleRows: visibleRows)
        case .append:
            self.setupAppend(rows: rows, visibleRows: visibleRows)
        case .appendPercent:
            self.setupAppendPercent(rows: rows, visibleRows: visibleRows)
        }
    }

    func setupNone(rows: [[Int]], visibleRows: [Int]) {
        self.values = rows.map({ $0 })
    }

    func setupMultiplyer(rows: [[Int]], visibleRows: [Int]) {
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
            if max != newMax {
                self.coeficent = percent
            }
            self.values.append(row.map({ Int(CGFloat($0) * percent) }))
        }
    }

    func setupAppend(rows: [[Int]], visibleRows: [Int]) {
        guard rows.count > 0 else {
            return
        }

        self.values = (0..<rows.count).map({ _ in [] })
        for index in 0..<rows[0].count {
            var offset = 0
            for (rowIndex, row) in rows.enumerated() {
                if visibleRows.contains(rowIndex) {
                    offset += row[index]
                    self.values[rowIndex].append(offset)
                } else {
                    self.values[rowIndex].append(offset)
                }
            }
        }
    }

    func setupAppendPercent(rows: [[Int]], visibleRows: [Int]) {
        guard rows.count > 0 else {
            return
        }

        self.values = (0..<rows.count).map({ _ in [] })
        for index in 0..<rows[0].count {
            var sum: Int = 0
            for (rowIndex, row) in rows.enumerated() {
                if visibleRows.contains(rowIndex) {
                    sum += row[index]
                }
            }

            var preverousValue: CGFloat = 0
            for (rowIndex, row) in rows.enumerated() {
                let value = row[index]
                let percent = CGFloat(value) / CGFloat(sum) * 100
                let newValue = preverousValue + percent
                let result = Int(min(round(newValue), 100))
                if visibleRows.contains(rowIndex) {
                    preverousValue += percent
                    self.values[rowIndex].append(result)
                } else {
                    self.values[rowIndex].append(Int(preverousValue))
                }
            }
        }
    }
}

class GraphLineRow {
    var style: GraphContext.Style
    var color: UIColor
    var name: String
    var values: [Int]
    var transformedValues: [Int] = []

    init(color: UIColor, name: String, values: [Int], style: GraphContext.Style) {
        self.color = color
        self.name = name
        self.values = values
        self.style = style
    }
}

class GraphXRow {
    var dates: [Date]
    var dateStrings: [String]
    var fullDateStrings: [String]

    init(dates: [Date], byDay: Bool) {
        self.dates = dates

        let dateFormatter = DateFormatter()
        if byDay {
            dateFormatter.dateFormat = "MMM d"
        } else {
            dateFormatter.dateFormat = "HH:mm"
        }
        self.dateStrings = dates.map({ dateFormatter.string(from: $0) })

        dateFormatter.dateFormat = "d MMM yyyy"
        self.fullDateStrings = dates.map({ dateFormatter.string(from: $0) })
    }
}

class Section {
    private var dataSource: GraphDataSource
    private var selectedRange: Range<CGFloat>
    private var zoomStep: Int?
    var enabledRows: [Int]
    var graph: PathManager.Graph

    var zoomedIndex: Int?
    var zoomedSection: Section?

    var currentDataSource: GraphDataSource {
        set {
            if let zoomedSection = self.zoomedSection {
                zoomedSection.currentDataSource = newValue
            } else {
                self.dataSource = newValue
            }
        }
        get {
            if let zoomedSection = self.zoomedSection {
                return zoomedSection.currentDataSource
            } else {
                return dataSource
            }
        }
    }

    var currentSelectedRange: Range<CGFloat> {
        set {
            if let zoomedSection = self.zoomedSection {
                zoomedSection.currentSelectedRange = newValue
            } else {
                self.selectedRange = newValue
            }
        }
        get {
            if let zoomedSection = self.zoomedSection {
                return zoomedSection.currentSelectedRange
            } else {
                return selectedRange
            }
        }
    }

    var currentZoomStep: Int? {
        set {
            if let zoomedSection = self.zoomedSection {
                zoomedSection.currentZoomStep = newValue
            } else {
                self.zoomStep = newValue
            }
        }
        get {
            if let zoomedSection = self.zoomedSection {
                return zoomedSection.currentZoomStep
            } else {
                return zoomStep
            }
        }
    }

    init(dataSource: GraphDataSource, selectedRange: Range<CGFloat>, enabledRows: [Int], graph: PathManager.Graph) {
        self.dataSource = dataSource
        self.selectedRange = selectedRange
        self.enabledRows = enabledRows
        self.zoomStep = nil
        self.graph = graph
    }
}

class GraphDataSource {
    let xRow: GraphXRow
    let yRows: [GraphLineRow]
    private let yScaled: Bool
    private let stacked: Bool
    let style: GraphStyle

    init(xRow: GraphXRow, yRows: [GraphLineRow], style: GraphStyle) {
        self.xRow = xRow
        self.yRows = yRows
        self.yScaled = false
        self.stacked = false
        self.style = style
    }

    init?(json: [String: Any], byDay: Bool) {
        var lineRows: [GraphLineRow] = []
        var types: [String: String] =  (json["types"] as? [String: String]) ?? [:]
        var names: [String: String] = (json["names"] as? [String: String]) ?? [:]
        var colors: [String: UIColor] =  ((json["colors"] as? [String: String]) ?? [:]).mapValues({ return UIColor(hex: $0 )})

        self.yScaled = (json["y_scaled"] as? Bool) ?? false
        self.stacked = (json["stacked"] as? Bool) ?? false
        let percentage = (json["percentage"] as? Bool) ?? false

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
                                let lineRow = GraphLineRow(color: color, name: realName, values: values.map({ Int($0) }), style: .graph)
                                lineRows.append(lineRow)
                            }
                        case "bar":
                            if let color = colors[name], let realName = names[name] {
                                let lineRow = GraphLineRow(color: color, name: realName, values: values.map({ Int($0) }), style: .bar)
                                lineRows.append(lineRow)
                            }
                        case "area":
                            if let color = colors[name], let realName = names[name] {
                                let lineRow = GraphLineRow(color: color, name: realName, values: values.map({ Int($0) }), style: .area)
                                lineRows.append(lineRow)
                            }
                        case "x":
                            let dates = values.map({ Date(timeIntervalSince1970: TimeInterval($0 / 1000)) })
                            xRow = GraphXRow(dates: dates, byDay: byDay)
                        default:
                            break
                        }
                    }
                }
            }
        }

        if self.stacked {
            if percentage {
                self.style = .percentStackedBar
            } else {
                self.style = .stackedBar
            }
        } else if self.yScaled {
            self.style = .doubleCompare
        } else {
            self.style = .basic
        }

        if let xRow = xRow, xRow.dates.count > 0, lineRows.count > 0 {
            self.xRow = xRow
            self.yRows = lineRows
        } else {
            return nil
        }
    }
}

