//
//  LanguageSelectionViewController.swift
//  Polyglot
//
//  Created by Ho on 2/13/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class LanguageSelectionViewController: UIViewController {
    
    var langs: [LangCode]!
    var selectedLang: LangCode!
    
    // MARK: - Controllers
    
    var delegate: LanguageSelectionViewControllerDelegate!
    
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
        navigationItem.title = Strings.languageSelectionViewControllerTitle
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(tableView)
    }

    private func updateLayouts() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}

extension LanguageSelectionViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return langs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let langCode = langs[indexPath.row]
        
        cell.textLabel?.text = Strings.languageNamesOfAllLanguages[langCode]?[LangCode.currentLanguage] ?? ""
        cell.imageView?.image = Images.langImages[langCode]?.scaledToListIconSize()
        cell.selectionStyle = .none
        if langs[indexPath.row] == selectedLang {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
}

extension LanguageSelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return Sizes.mediumFontSize * 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Sizes.mediumFontSize * 3
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLang = langs[indexPath.row]
        self.delegate.updateLanguage(as: selectedLang)
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        navigationController?.popViewController(animated: true)
    }
    
}

protocol LanguageSelectionViewControllerDelegate {
    
    func updateLanguage(as language: LangCode)
    
}
