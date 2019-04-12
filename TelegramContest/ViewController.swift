//
//  ViewController.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

struct Zoom {
    enum ZoomIndex {
        case inside(value: Int)
        case outside(value: Int)

        var isInside: Bool {
            switch self {
            case .inside:
                return true
            case .outside:
                return false
            }
        }

        var index: Int {
            switch self {
            case .inside(let value):
                return value
            case .outside(let value):
                return value
            }
        }
    }

    enum AnimationStyle {
        case basic
        case zooming
        case pie
    }

    let index: ZoomIndex
    let positionPercentage: CGFloat
    let style: AnimationStyle
    let shouldReplaceRangeController: Bool
}

class PathManager {
    enum Graph: String {
        case first = "1"
        case second = "2"
        case third = "3"
        case forth = "4"
        case fivth = "5"

        static var allCases: [Graph] = [.first, .second, .third, .forth, .fivth]
    }

    private static func path(to graph: Graph) -> String {
        return "data/\(graph.rawValue)/overview"
    }

    private static func path(to date: Date, in graph: Graph) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let folder = dateFormatter.string(from: date)

        dateFormatter.dateFormat = "dd"
        let subfolder = dateFormatter.string(from: date)

        return "data/\(graph.rawValue)/\(folder)/\(subfolder)"
    }

    static func section(to graph: Graph) -> Section? {
        return self.dataSource(fromPath: self.path(to: graph), byDay: true, graph: graph)
    }

    static func section(to date: Date, index: Int, section: Section) -> Section? {
        if section.graph == .fivth {
            return self.fivth(index: index, section: section)
        }
        return self.dataSource(fromPath: self.path(to: date, in: section.graph), byDay: false, graph: section.graph)
    }

    static func fivth(index: Int, section: Section) -> Section? {
        let range = (index - 2)..<(index + 3)
        let dates = section.currentDataSource.xRow.dates[range]
        var yRows: [GraphLineRow] = []
        for yRow in section.currentDataSource.yRows {
            yRows.append(GraphLineRow(color: yRow.color, name: yRow.name, values: Array(yRow.values[range]), style: .pie))
        }
        let dataSource = GraphDataSource(xRow: GraphXRow(dates: Array(dates), byDay: true), yRows: yRows, style: .pie)
        let section = Section(dataSource: dataSource, selectedRange: 0.4..<0.6, enabledRows: section.enabledRows, graph: section.graph)
        return section
    }

    private static func dataSource(fromPath: String, byDay: Bool, graph: Graph) -> Section? {
        let path = Bundle.main.path(forResource: fromPath, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)

        let jsonResult = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        if let jsonResult = jsonResult as? [String: Any], let dataSource = GraphDataSource(json: jsonResult, byDay: byDay) {
            return Section(dataSource: dataSource, selectedRange: 0.0..<1.0, enabledRows: Array(0..<dataSource.yRows.count), graph: graph)
        }
        return nil
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView(frame: .zero, style: .grouped)
    var section: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()

//        let path = Bundle.main.path(forResource: "chart_data", ofType: "json")!
//        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
//
//        let jsonResult = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
//        if let jsonResult = jsonResult as? [Any] {
//            for result in jsonResult {
//                if let value = result as? [String: Any],
//                    let dataSource = GraphDataSource(json: value) {
//                    self.section.append(Section(dataSource: dataSource, selectedRange: 0..<1, enabledRows: Array(0..<dataSource.yRows.count)))
//                }
//            }
//        }

        for graph in PathManager.Graph.allCases {
            if let section = PathManager.section(to: graph) {
                self.section.append(section)
            }
        }

        self.view.addSubview(self.tableView)
        self.tableView.canCancelContentTouches = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.allowsMultipleSelection = true
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        for graph in PathManager.Graph.allCases {
            self.tableView.register(GraphTableViewCell.self, forCellReuseIdentifier: "GraphTableViewCell\(graph.rawValue)")
        }
        self.tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: "ButtonTableViewCell")
        self.tableView.register(FiltersTableViewCell.self, forCellReuseIdentifier: "FiltersTableViewCell")
    }

    var theme: Theme = .default {
        didSet {
            let config = theme.configuration
            self.tableView.backgroundColor = config.mainBackgroundColor
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    // MARK: - TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.section.count + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            let sectionType = self.section[section - 1]
            return sectionType.graph != .forth ? 2 : 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonTableViewCell", for: indexPath) as! ButtonTableViewCell
            cell.theme = theme
            return cell
        }

        let section = self.section[indexPath.section - 1]

        let selectAction: SelectionBlock = { index in
            if section.enabledRows.contains(index) {
                section.enabledRows.removeAll(where: { $0 == index })
            } else {
                section.enabledRows.append(index)
            }
            let graphCell = tableView.cellForRow(at: IndexPath(row: 0, section: indexPath.section)) as! GraphTableViewCell
            let graphView = graphCell.graphView
            graphView.updateEnabledRows(section.enabledRows, animated: true)
        }
        let longSelectAction: SelectionBlock = { index in
            section.enabledRows = [index]
            let graphCell = tableView.cellForRow(at: IndexPath(row: 0, section: indexPath.section)) as! GraphTableViewCell
            let graphView = graphCell.graphView
            graphView.updateEnabledRows(section.enabledRows, animated: true)
        }

        switch indexPath.row {
        case 0:
            let dataSource = section.currentDataSource
            let cell = tableView.dequeueReusableCell(withIdentifier: "GraphTableViewCell\(section.graph.rawValue)", for: indexPath) as! GraphTableViewCell
            cell.graphView.style = dataSource.style
            cell.graphView.theme = theme
            cell.graphView.updateDataSource(dataSource: dataSource, enableRows: section.enabledRows, skip: false, zoomed: section.zoomedSection != nil)
            cell.graphView.selectedAction = selectAction
            cell.graphView.selectedLongAction = longSelectAction
            cell.graphView.rangeUpdated = { value in
                section.currentSelectedRange = value
            }
            cell.graphView.updatedZoomStep = { value in
                section.currentZoomStep = value
            }
            cell.graphView.updateSizeAction = {
                self.graphCachedHeigh[indexPath] = cell.graphView.height
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
            cell.graphView.zoomAction = { index in
                let date = section.currentDataSource.xRow.dates[index]

                let indexes = convertIndexes(count: section.currentDataSource.xRow.dates.count, range: section.currentSelectedRange, rounded: false)
                let positionPercentage = (CGFloat(index - indexes.lowerBound) / CGFloat(indexes.upperBound - indexes.lowerBound))
                section.positionPercentage = positionPercentage

                guard let newSection = PathManager.section(to: date, index: index, section: section) else {
                    return
                }
                let range: Range<CGFloat>
                let enableRows: [Int]
                let shouldReplaceRangeController: Bool
                if section.graph == .forth {
                    range = 0..<1.0
                    enableRows = newSection.enabledRows
                    shouldReplaceRangeController = true
                } else {
                    range = 0.4..<0.6
                    enableRows = section.enabledRows
                    shouldReplaceRangeController = false
                }
                let zoomAnimationStyle: Zoom.AnimationStyle
                if section.graph == .forth || section.graph == .third {
                    zoomAnimationStyle = .zooming
                } else if section.graph == .fivth {
                    zoomAnimationStyle = .pie
                } else {
                    zoomAnimationStyle = .basic
                }

                section.zoomedSection = newSection
                section.currentSelectedRange = range
                section.enabledRows = enableRows
                section.zoomedIndex = index
                let zoom = Zoom(index: .inside(value: index), positionPercentage: positionPercentage, style: zoomAnimationStyle, shouldReplaceRangeController: shouldReplaceRangeController)
                cell.graphView.transform(to: section.currentDataSource, enableRows: enableRows, zoom: zoom, zoomStep: nil, range: range, zoomed: true)
            }
            cell.graphView.zoomOutAction = {
                section.zoomedSection = nil
                var zoom: Zoom? = nil
                let shouldReplaceRangeController: Bool
                if section.graph == .forth {
                    section.enabledRows = [0]
                    shouldReplaceRangeController = true
                } else {
                    shouldReplaceRangeController = false
                }
                if let index = section.zoomedIndex {
                    let zoomAnimationStyle: Zoom.AnimationStyle
                    if section.graph == .forth || section.graph == .third {
                        zoomAnimationStyle = .zooming
                    } else {
                        zoomAnimationStyle = .basic
                    }
                    zoom = Zoom(index: .outside(value: index), positionPercentage: section.positionPercentage ?? 0, style: zoomAnimationStyle, shouldReplaceRangeController: shouldReplaceRangeController)
                }
                cell.graphView.transform(to: section.currentDataSource, enableRows: section.enabledRows, zoom: zoom, zoomStep: section.currentZoomStep, range: section.currentSelectedRange, zoomed: false)
                section.zoomedIndex = nil
            }
            cell.graphView.updateZoomStep(newValue: section.currentZoomStep)
            cell.graphView.updateSelectedRange(range: section.currentSelectedRange, skip: false)
            cell.graphView.updateEnabledRows(section.enabledRows, animated: false)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FiltersTableViewCell", for: indexPath) as! FiltersTableViewCell
            let yRows = section.currentDataSource.yRows
            let section = self.section[indexPath.section - 1]
            var rows: [Row] = []

            for (index, yRow) in yRows.enumerated() {
                let row = Row(name: yRow.name,
                              color: yRow.color,
                              isSelected: section.enabledRows.contains(index),
                              selectedAction: selectAction,
                              selectedLongAction: longSelectAction)
                rows.append(row)
            }

            let config = theme.configuration
            cell.contentView.backgroundColor = config.backgroundColor
            cell.backgroundColor = config.backgroundColor
            cell.rows = rows
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        }
        return "Followers"
    }

    var graphCachedHeigh: [IndexPath: CGFloat] = [:]

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 65
        }

        switch indexPath.row {
        case 0:
            if let height = self.graphCachedHeigh[indexPath] {
                return height
            }
            return 404
        default:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section > 0 else {
            self.animateThemeSwitch()
            self.theme = self.theme.configuration.isLight ? Theme(style: .dark) : Theme(style: .light)
            self.tableView.reloadData()
            return
        }

//        let section = self.section[indexPath.section - 1]
//        let cell = tableView.cellForRow(at: indexPath)
//
//        let row = indexPath.row - 1
//        let shouldSelect: Bool
//        if section.enabledRows.contains(row) {
//            section.enabledRows.removeAll(where: { $0 == row })
//            shouldSelect = false
//        } else {
//            section.enabledRows.append(row)
//            shouldSelect = true
//        }
//
//        let graphCell = tableView.cellForRow(at: IndexPath(row: 0, section: indexPath.section)) as! GraphTableViewCell
//        let graphView = graphCell.graphView
//        graphView.updateEnabledRows(section.enabledRows, animated: true)
//
//        cell?.accessoryType = shouldSelect ? .checkmark : .none
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.configuration.isLight ? .default : .lightContent
    }

    func animateThemeSwitch() {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: false) {
            self.view.addSubview(snapshotView)
            UIView.animate(withDuration: 0.25, animations: {
                snapshotView.alpha = 0
            }) { (_) in
                snapshotView.removeFromSuperview()
            }
        }
    }
}

func image(from color: UIColor) -> UIImage? {
    let rect = CGRect(origin: .zero, size: CGSize(width: 19, height: 19))
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
    color.setFill()
    UIRectFill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

extension UIImage{
    var roundedImage: UIImage? {
        let rect = CGRect(origin:CGPoint(x: 0, y: 0), size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        UIBezierPath(
            roundedRect: rect,
            cornerRadius: 4
            ).addClip()
        self.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}


public extension UIColor {
    convenience init(hex: String) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            self.init(white: 0, alpha: 1.0)
            return
        }

        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UIImage {
    convenience init?(size: CGSize, gradientColor: [UIColor]) {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColor.map({ $0.cgColor }) as CFArray, locations: nil) else {
            return nil
        }

        context.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 0, y: size.height), options: CGGradientDrawingOptions())
        guard let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        self.init(cgImage: image)
        defer { UIGraphicsEndImageContext() }
    }
}
