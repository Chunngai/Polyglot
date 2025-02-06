//
//  DuolingoOnlySelectionViewController.swift
//  Polyglot
//
//  Created by Ho on 2/6/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

class DuolingoOnlySelectionViewController: UIViewController {
    
    var practiceTypes: [String] = [
        "shadowing",
        "speaking",
        "reading",
        "podcast"
    ]
    var practiceType2isDuolingoOnly: [String: Bool] = [
        "shadowing": false,
        "speaking": false,
        "reading": false,
        "podcast": false
    ]
    
    // MARK: - Controllers
    
    var delegate: DuolingoOnlySelectionViewControllerDelegate!
    
    // MARK: - Views
    
    private var tableView: UITableView = {
        let tableView = UITableView(
            frame: .zero,
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
    
    private func updateSetups() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func updateViews() {        
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(tableView)
    }

    private func updateLayouts() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}

extension DuolingoOnlySelectionViewController: UITableViewDataSource {

    // MARK: - Utils

    private func getText(from practiceType: String) -> String? {

        var mapping: [LangCode: String] = [:]
        if practiceType == "shadowing" {
            mapping = Strings.listening
        } else if practiceType == "speaking" {
            mapping = Strings.speaking
        } else if practiceType == "reading" {
            mapping = Strings.reading
        } else if practiceType == "podcast" {
            mapping = Strings.podcast
        } else {
            return nil
        }

        return mapping[LangCode.currentLanguage]
        
    }

    private func getImage(from practiceType: String) -> UIImage? {

        if practiceType == "shadowing" {
            return Images.listeningPracticeImage
        } else if practiceType == "speaking" {
            return Images.translationPracticeImage
        } else if practiceType == "reading" {
            return Images.readingPracticeImage
        } else if practiceType == "podcast" {
            return Images.podcastPracticeImage
        } else {
            return nil
        }        
    }
    
}

extension DuolingoOnlySelectionViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return practiceTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let practiceType = practiceTypes[indexPath.row]
        
        cell.textLabel?.text = getText(from: practiceType)
        cell.imageView?.image = getImage(from: practiceType)?.scaledToListIconSize()
        cell.selectionStyle = .none
        if practiceType2isDuolingoOnly[practiceType] {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
}

extension DuolingoOnlySelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPracticeType = practiceTypes[indexPath.row]
        practiceType2isDuolingoOnly[selectedPracticeType].toggle()
        
        self.delegate.updatePracticeTypes(with: practiceTypes)
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = practiceType2isDuolingoOnly[selectedPracticeType] ?
                .checkmark : .none
        }

    }
    
}

protocol DuolingoOnlySelectionViewControllerDelegate {
    
    func updateselectionMapping(with selectionMapping: [String: Bool])
    
}
