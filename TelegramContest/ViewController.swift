//
//  ViewController.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

struct GraphLineRow {
    var color: UIColor
    var name: String
    var values: [Int]
}

struct GraphXRow {
    var dates: [Date]
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
                var values: [Int] = []
                for row in column {
                    if let nameValue = row as? String {
                        name = nameValue
                    } else if let value = row as? Int {
                        values.append(value)
                    }
                }
                if let name = name {
                    if let type = types[name] {
                        switch type {
                        case "line":
                            if let color = colors[name], let realName = names[name] {
                                let lineRow = GraphLineRow(color: color, name: realName, values: values)
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

        if let xRow = xRow, lineRows.count > 0 {
            self.xRow = xRow
            self.yRows = lineRows
        } else {
            return nil
        }
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView(frame: .zero)
    var graphView: GraphView?

    var dataSource: GraphDataSource = {
        var yRow1Values: [Int] = []
        var yRow2Values: [Int] = []
        var xRowValues: [Date] = []

        let date = Date()
        for i in 0..<100 {
            yRow1Values.append(Int.random(in: 0..<(50 + i)))
            yRow2Values.append(Int.random(in: 0..<(100 + i)))
            xRowValues.append(date.addingTimeInterval(60 * 60 * 24 * Double(i)))
        }

        let yRow1 = GraphLineRow(color: UIColor.red, name: "First", values: yRow1Values)
        let yRow2 = GraphLineRow(color: UIColor.blue, name: "Second", values: yRow2Values)

        return GraphDataSource(
            xRow: GraphXRow(dates: xRowValues),
            yRows: [yRow1, yRow2]
        )
    }()
    var enabledRows: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let path = Bundle.main.path(forResource: "chart_data", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonResult = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        if let jsonResult = jsonResult as? [Any], let first = jsonResult[0] as? [String: Any] {
            let graph = GraphDataSource(json: first)
            self.dataSource = graph!
        }

        self.enabledRows = Array(0..<self.dataSource.yRows.count)

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

        //        let controlView = GraphControlView()
        //        controlView.frame = CGRect(x: 0, y: 100, width: UIScreen.main.bounds.width, height: 60)
        //        self.view.addSubview(controlView)
        //        controlView.dataSource = self.dataSource
        //
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        //            controlView.updateEnabledRows([0], animated: true)
        //        }
        // Do any additional setup after loading the view, typically from a nib.
    }




    // MARK: - TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.yRows.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GraphTableViewCell", for: indexPath) as! GraphTableViewCell
            self.graphView = cell.graphView
            self.graphView?.dataSource = self.dataSource
            return cell
        default:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            let index = indexPath.row - 1
            let row = self.dataSource.yRows[index]
            cell.imageView?.image = image(from: row.color)
            cell.textLabel?.text = row.name
            cell.selectionStyle = .none
            cell.isSelected = true
            cell.accessoryType = .checkmark
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 372
        default:
            return 65
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row > 0 else {
            return
        }

        let cell = tableView.cellForRow(at: indexPath)

        let row = indexPath.row - 1
        let shouldSelect: Bool
        if self.enabledRows.contains(row) {
            self.enabledRows.removeAll(where: { $0 == row })
            shouldSelect = false
        } else {
            self.enabledRows.append(row)
            shouldSelect = true
        }

        self.graphView?.updateEnabledRows(self.enabledRows, animated: true)

        cell?.accessoryType = shouldSelect ? .checkmark : .none
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
