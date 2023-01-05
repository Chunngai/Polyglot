//
//  HistoryViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/29.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class HistoryViewController: UITableViewController {

    struct GroupedHistoryRecords {  // TODO: - Swap for words and history.
        
        // For storing history records grouped by group identifiers.
        
        var groupIdentifier: String
        var historyRecords: [HistoryRecord]
    }
    
    // TODO: - Simplify here.
    // TODO: - Don't make it a computed property. Too time-consuming.
    // TODO: - Sort by date.
    private var groupedHistoryRecords: [GroupedHistoryRecords] {
        var groups: [String: [HistoryRecord]] = [:]
        for historyRecord in historyRecords {
            let groupIdentifier = historyRecord.groupIdentifier
            if !groups.keys.contains(groupIdentifier) {
                groups[groupIdentifier] = []  // TODO: - Simplify here.
            }
            
            groups[groupIdentifier]?.append(historyRecord)
        }
        
        var groupedHistoryRecords: [GroupedHistoryRecords] = []
        for (groupIdentifier, historyRecords) in groups {
            groupedHistoryRecords.append(GroupedHistoryRecords(groupIdentifier: groupIdentifier, historyRecords: historyRecords))
        }
        groupedHistoryRecords.sort { (item1, item2) -> Bool in  // TODO: - Update here.
            item1.historyRecords[0].creationDate > item2.historyRecords[0].creationDate
        }
        return groupedHistoryRecords
    }
    
    private var dataSource: [GroupedHistoryRecords]! {
        didSet {
            // Reload table data.
            tableView.reloadData()
        }
    }
    
    // MARK: - Models
    
    private var historyRecords: [HistoryRecord] = HistoryRecord.load() {
        didSet {
            HistoryRecord.save(&historyRecords)
            
            // Also update the data source.
//            dataSource = groupedWords
        }
    }
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    private func updateSetups() {
        tableView.register(HistoryRecordTableCell.self, forCellReuseIdentifier: HistoryViewController.cellIdentifier)
        tableView.register(WordsTableHeaderView.self, forHeaderFooterViewReuseIdentifier: WordsViewController.headerIdentifier)  // TODO: - Change the class name later.
//
//        searchBar.delegate = self
//
        dataSource = groupedHistoryRecords
    }
    
    private func updateViews() {
//        navigationItem.titleView = searchBar
                
        tableView.removeRedundantSeparators()
    }
    
    private func updateLayouts() {
        
    }
    
    func updateValues() {
        
    }
}

extension HistoryViewController {
    
    // MARK: - UITableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].historyRecords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HistoryViewController.cellIdentifier,
            for: indexPath
        ) as? HistoryRecordTableCell else {
            return UITableViewCell()
        }
        
        let historyRecord = dataSource[indexPath.section].historyRecords[indexPath.row]
        cell.updateValues(practiceType: historyRecord.practiceType, practiceContent: historyRecord.practiceContent, correctness: historyRecord.correctness)
        
        return cell
    }
}

extension HistoryViewController {
   
   // MARK: - UITableView Delegate

   override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
       let headerView = WordsTableHeaderView()  // TODO: - update later.
       headerView.updateValues(text: dataSource[section].groupIdentifier)
       return headerView
   }
}

extension HistoryViewController {
    
    // MARK: - Constants
    
    static let cellIdentifier: String = Identifiers.historyTableCellIdentifier
    
}
