//
//  DuolingoOnlySelectionViewController.swift
//  Polyglot
//
//  Created by Ho on 2/6/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

class DuolingoOnlySelectionViewController: UIViewController {

    enum PracticeType {
        
        case shadowing
        case speaking
        case reading
        case podcast

        var text: String {
            switch self {
            case .shadowing: return Strings.listening
            case .speaking: return Strings.speaking
            case .reading: return Strings.reading
            case .podcast: return Strings.podcast
            }
        }

        var image: UIImage {
            switch self {
            case .shadowing: return Images.listeningPracticeImage
            case .speaking: return Images.translationPracticeImage
            case .reading: return Images.readingPracticeImage
            case .podcast: return Images.podcastPracticeImage
            }
        }
        
    }
    
    var practiceTypes: [PracticeType] = [
        .shadowing,
        .speaking,
        .reading,
        .podcast
    ]
    var practiceType2isDuolingoOnly: [PracticeType: Bool] = [
        .shadowing: false,
        .speaking: false,
        .reading: false,
        .podcast: false
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
        
        navigationItem.title = "Duolingo Only"  // TODO: - localization
        navigationItem.largeTitleDisplayMode = .never
        
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return practiceTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let practiceType = practiceTypes[indexPath.row]
        
        cell.textLabel?.text = practiceType.text
        cell.imageView?.image = practiceType.image
        cell.selectionStyle = .none
        if practiceType2isDuolingoOnly[practiceType]! {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
}

extension DuolingoOnlySelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedPracticeType = practiceTypes[indexPath.row]
        practiceType2isDuolingoOnly[selectedPracticeType]!.toggle()
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = practiceType2isDuolingoOnly[selectedPracticeType]! ?
                .checkmark : .none
        }
        
        self.delegate.updateselectionMapping(with: practiceType2isDuolingoOnly)
        
    }
    
}

protocol DuolingoOnlySelectionViewControllerDelegate {
    
    func updateselectionMapping(with selectionMapping: [DuolingoOnlySelectionViewController.PracticeType: Bool])
    
}
