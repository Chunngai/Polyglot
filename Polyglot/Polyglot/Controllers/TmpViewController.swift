//
//  TmpViewController.swift
//  Polyglot
//
//  Created by Sola on 2023/2/11.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TmpViewController: UIViewController {

    // https://www.youtube.com/watch?v=VrW_6EixIVQ
    
    private var colors: [[UIColor]] = [
        [.systemGreen,
        .systemBlue,
        .systemRed,
        .systemOrange,
        .systemGray,
        .systemPurple,
        .systemYellow,
        .systemPink,
        .systemTeal],
        [.systemGreen,
         .systemBlue,
         .systemRed,
         .systemOrange,
         .systemGray,
         .systemPurple,
         .systemYellow,
         .systemPink,
         .systemTeal]
    ]
    
    private var collectionView: UICollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.sectionInset = UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.addSubview(collectionView!)
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = .white
        collectionView?.snp.makeConstraints({ (make) in
            make.width.height.equalToSuperview().multipliedBy(0.9)
            make.centerX.centerY.equalToSuperview()
        })
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        collectionView?.addGestureRecognizer(gesture)
    }
}

extension TmpViewController {
    
    @objc private func handleGesture(_ gesture: UIPanGestureRecognizer) {
        guard let collectionView = collectionView else {
            return
        }
        
        switch gesture.state {
        case .began:
            guard let targetIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            
            print("began")
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
            
        case.changed:
            print("changed", Int.random(in: 0..<100))
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            print("ended")
            collectionView.endInteractiveMovement()
        default:
            print("canceled")
            collectionView.cancelInteractiveMovement()
        }
    }
    
}

extension TmpViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.backgroundColor = colors[indexPath.section][indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if sourceIndexPath.section == 0 && destinationIndexPath.section == 0 {
            let item = colors[0].remove(at: sourceIndexPath.row)
            colors[0].insert(item, at: destinationIndexPath.row)
        } else if sourceIndexPath.section == 0 && destinationIndexPath.section == 1 {
            let item = colors[0].remove(at: sourceIndexPath.row)
            colors[1].insert(item, at: destinationIndexPath.row)
        }
    }
    
    
    
}

extension TmpViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            let item = colors[0].remove(at: indexPath.row)
            colors[1].append(item)
            
            collectionView.moveItem(at: indexPath, to: IndexPath(row: colors[1].count - 1, section: 1))
            
        } else if indexPath.section == 1 {
            
            let item = colors[1].remove(at: indexPath.row)
            colors[0].append(item)
            
            collectionView.moveItem(at: indexPath, to: IndexPath(row: colors[0].count - 1, section: 0))
            
        }
    }
}
