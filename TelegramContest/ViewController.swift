//
//  ViewController.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

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
        self.tableView.separatorStyle = .none
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.allowsMultipleSelection = true
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.tableView.register(GraphTableViewCell.self, forCellReuseIdentifier: "GraphTableViewCell")
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
            return 2
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "FiltersTableViewCell", for: indexPath) as! FiltersTableViewCell
            let yRows = dataSource.yRows
            let section = self.section[indexPath.section - 1]
            var rows: [Row] = []

            for (index, yRow) in yRows.enumerated() {
                let row = Row(name: yRow.name, color: yRow.color, isSelected: section.enabledRows.contains(index)) {
                    if section.enabledRows.contains(index) {
                        section.enabledRows.removeAll(where: { $0 == index })
                    } else {
                        section.enabledRows.append(index)
                    }
                    let graphCell = tableView.cellForRow(at: IndexPath(row: 0, section: indexPath.section)) as! GraphTableViewCell
                    let graphView = graphCell.graphView
                    graphView.updateEnabledRows(section.enabledRows, animated: true)
//                    graphView.transform(to: self.section[indexPath.section].dataSource, range: 0.4..<0.6)
                }
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 65
        }

        switch indexPath.row {
        case 0:
            return 390
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
