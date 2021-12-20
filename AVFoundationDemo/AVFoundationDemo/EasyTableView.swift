//
//  EasyTableView.swift
//  AVFoundationDemo
//
//  Created by Mike Huang on 2021/12/13.
//

import UIKit
import AVFoundation

class EasyTableCellModel {
    
    var title: String
    var asset: AVAsset
    var isVideo = false
    var isSelected = false
    var duration: Int64 = 0
    
    var selectedAction: ((EasyTableCellModel) -> Void)?
    var playAction: ((EasyTableCellModel) -> Void)?
    
    init(title: String, asset:AVAsset, isVideo: Bool, selectedAction: ((EasyTableCellModel) -> Void)?, playAction: ((EasyTableCellModel) -> Void)?) {
        self.title = title
        self.asset = asset
        self.isVideo = isVideo
        self.selectedAction = selectedAction
        self.playAction = playAction
    }
}

class EasyTableView: UIView {

    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    let title: String
    var dataSources: [EasyTableCellModel] {
        didSet {
            tableView.reloadData()
        }
    }
    var didSelectedAction: ((EasyTableCellModel)->Void)?
    
    init(dataSources: [EasyTableCellModel], title: String, frame: CGRect) {
        self.dataSources = dataSources
        self.title = title
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        addSubview(tableView)
        tableView.frame = self.bounds
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.reloadData()
    }
}

extension EasyTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSources.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let model = dataSources[indexPath.row]
        cell.textLabel?.text = model.title
        cell.accessoryType = model.isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let model = dataSources[indexPath.row]
        model.isSelected = !model.isSelected
        tableView.reloadData()
        
        if let action = didSelectedAction {
            action(model)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 40))
        let label = UILabel(frame: CGRect(x: 10, y: 5, width: tableView.bounds.width, height: 30))
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.text = self.title
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
}
