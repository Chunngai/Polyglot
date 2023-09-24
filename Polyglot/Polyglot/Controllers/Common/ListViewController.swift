//
//  ListViewController.swift
//  Polyglot
//
//  Created by Sola on 2023/1/5.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {
    
    // MARK: - Controllers
    
    var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()
    
    // MARK: - Views
    
    var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .insetGrouped)
        tableView.backgroundColor = Colors.lightGrayBackgroundColor
        tableView.removeRedundantSeparators()
        return tableView
    }()
    
    var practiceButtonShadowView: RoundButtonWithShadow = {
        let roundShadowView = RoundButtonWithShadow()
        roundShadowView.button.setImage(
            Icons.practiceIcon,
            for: .normal
        )
        roundShadowView.button.backgroundColor = Colors.defaultBackgroundColor
        return roundShadowView
    }()
    
    private lazy var navigationBarAddButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        return button
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    func updateSetups() {

    }
    
    func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(tableView)
        view.addSubview(practiceButtonShadowView)
        
        navigationItem.searchController = searchController
        navigationItem.rightBarButtonItem = navigationBarAddButton
    }
    
    func updateLayouts() {
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        practiceButtonShadowView.snp.makeConstraints { (make) in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
        }
    }
}

extension ListViewController {
    
    // MARK: - Selectors
    
    @objc func addButtonTapped() {
        // https://stackoverflow.com/questions/24111356/swift-class-method-which-must-be-overridden-by-subclass
        fatalError("addButtonTapped() has not been implemented.")
    }
}

extension ListViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchController.searchBar.resignFirstResponder()
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        searchController.searchBar.resignFirstResponder()
    }
    
}
