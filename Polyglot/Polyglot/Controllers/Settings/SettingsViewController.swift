//
//  SettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 8/22/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    var headers: [String] = []
    var cells: [[UITableViewCell]] = []
    
    func saveSettings() {
        
    }
    
    // MARK: - Views
    
    var tableView: UITableView = {
        let tableView = UITableView(
            frame: CGRect.zero,
            style: .insetGrouped
        )
        return tableView
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveSettings()
    }
    
    func updateSetups() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(tableView)
    }
    
    func updateLayouts() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}

extension SettingsViewController: UITableViewDataSource {
    
    // MARK: - UITableView Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.section][indexPath.row]
    }
    
}

extension SettingsViewController: UITableViewDelegate {
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return (
            !cells[indexPath.section][indexPath.row].isHidden
            ? Sizes.mediumFontSize * 3
            : 0
        )
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (
            !cells[indexPath.section][indexPath.row].isHidden
            ? Sizes.mediumFontSize * 3
            : 0
        )
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers[section]
    }
}
