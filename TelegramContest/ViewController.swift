//
//  ViewController.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
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

class SelectioTableViewCell: UITableViewCell {
    var theme: Theme = .light {
        didSet {
            self.updateTheme()
        }
    }

    func updateTheme() {
        let config = self.theme.configuration
        self.textLabel?.textColor = config.nameColor
        self.contentView.backgroundColor = config.backgroundColor
        self.textLabel?.backgroundColor = config.backgroundColor
        self.accessoryView?.backgroundColor = config.backgroundColor
        self.backgroundColor = config.backgroundColor
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.updateTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView(frame: .zero, style: .grouped)
    var section: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let path = Bundle.main.path(forResource: "chart_data", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)

        let jsonResult = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        if let jsonResult = jsonResult as? [Any] {
            for result in jsonResult {
                if let value = result as? [String: Any],
                    let dataSource = GraphDataSource(json: value) {
                    self.section.append(Section(dataSource: dataSource, selectedRange: 0..<1, enabledRows: Array(0..<dataSource.yRows.count)))
                }
            }
        }

        self.view.addSubview(self.tableView)
        self.tableView.canCancelContentTouches = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.allowsMultipleSelection = true
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.tableView.register(GraphTableViewCell.self, forCellReuseIdentifier: "GraphTableViewCell")
        self.tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: "ButtonTableViewCell")
        self.tableView.register(SelectioTableViewCell.self, forCellReuseIdentifier: "SelectionUITableViewCell")
    }

    var theme: Theme = Theme.light {
        didSet {
            let config = theme.configuration
            self.tableView.separatorColor = config.lineColor
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
            return self.section[section - 1].dataSource.yRows.count + 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonTableViewCell", for: indexPath) as! ButtonTableViewCell
            cell.theme = theme
            return cell
        }

        let section = self.section[indexPath.section - 1]
        let dataSource = section.dataSource
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GraphTableViewCell", for: indexPath) as! GraphTableViewCell
            cell.graphView.theme = theme
            cell.graphView.dataSource = dataSource
            cell.graphView.rangeUpdated = { value in
                section.selectedRange = value
            }
            cell.graphView.updatedZoomStep = { value in
                section.zoomStep = value
            }
            cell.graphView.updateZoomStep(newValue: section.zoomStep)
            cell.graphView.selectedRange = section.selectedRange
            cell.graphView.updateEnabledRows(section.enabledRows, animated: false)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionUITableViewCell", for: indexPath) as! SelectioTableViewCell
            cell.theme = self.theme
            let index = indexPath.row - 1
            let row = dataSource.yRows[index]
            cell.imageView?.image = image(from: row.color)?.roundedImage
            cell.textLabel?.text = row.name
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
            cell.accessoryType = section.enabledRows.contains(indexPath.row - 1) ? .checkmark : .none
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        }
        return "Followers"
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 65
        }

        switch indexPath.row {
        case 0:
            return 362
        default:
            return 65
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section > 0 else {
            self.theme = self.theme == .light ? .dark : .light
            self.tableView.reloadData()
            return
        }

        guard indexPath.row > 0 else {
            return
        }

        let section = self.section[indexPath.section - 1]
        let cell = tableView.cellForRow(at: indexPath)

        let row = indexPath.row - 1
        let shouldSelect: Bool
        if section.enabledRows.contains(row) {
            section.enabledRows.removeAll(where: { $0 == row })
            shouldSelect = false
        } else {
            section.enabledRows.append(row)
            shouldSelect = true
        }

        let graphCell = tableView.cellForRow(at: IndexPath(row: 0, section: indexPath.section)) as! GraphTableViewCell
        let graphView = graphCell.graphView
        graphView.updateEnabledRows(section.enabledRows, animated: true)

        cell?.accessoryType = shouldSelect ? .checkmark : .none
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme == .light ? .default : .lightContent
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
