//
//  TmpViewController1.swift
//  Polyglot
//
//  Created by Sola on 2023/2/11.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

import UIKit

//enum CellModel {
//    case simple(color: UIColor)
////    case availableToDrop
//}

class TmpViewController1: UIViewController {
    
    // https://stackoverflow.com/questions/39080807/drag-and-reorder-uicollectionview-with-sections
    // https://medium.com/hackernoon/drag-it-drop-it-in-collection-table-ios-11-6bd28795b313
    
    private lazy var cellIdentifier = "cellIdentifier"
    private lazy var supplementaryViewIdentifier = "supplementaryViewIdentifier"
    private lazy var sections = 2
    private lazy var itemsInSection = 6
    private lazy var numberOfElementsInRow = 3
    
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
    private lazy var data: [[UIColor]] = {
        var count = 0
        return (0 ..< sections).map { section in
            return (0 ..< itemsInSection).map { row -> UIColor in
                count += 1
                return colors[section][row]
            }
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewFlowLayout.minimumLineSpacing = 5
        collectionViewFlowLayout.minimumInteritemSpacing = 5
        //        let _numberOfElementsInRow = CGFloat(numberOfElementsInRow)
        //        let allWidthBetwenCells = _numberOfElementsInRow == 0 ? 0 : collectionViewFlowLayout.minimumInteritemSpacing*(_numberOfElementsInRow-1)
        //        let width = (view.frame.width - allWidthBetwenCells)/_numberOfElementsInRow
        collectionViewFlowLayout.itemSize = CGSize(width: view.bounds.width / 3.2, height: view.bounds.width / 3.2)
        collectionViewFlowLayout.headerReferenceSize = CGSize(width: 0, height: 40)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewFlowLayout)
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        //        collectionView.register(SupplementaryView.self,
        //                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
        //                                withReuseIdentifier: supplementaryViewIdentifier)
        
        collectionView.dragInteractionEnabled = true
        collectionView.reorderingCadence = .fast
        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
        // https://stackoverflow.com/questions/53561281/collection-view-drag-and-drop-delay
        collectionView.gestureRecognizers?.forEach { (recognizer) in
            if let longPressRecognizer = recognizer as? UILongPressGestureRecognizer {
                print(type(of: recognizer))
                longPressRecognizer.minimumPressDuration = 0
            }
        }
        
        //        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

//extension TmpViewController1: UICollectionViewDelegate { }

extension TmpViewController1: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //        switch data[indexPath.section][indexPath.item] {
        //            case .simple(let color):
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        cell.backgroundColor = data[indexPath.section][indexPath.row]
        //                cell.backgroundColor = .gray
        return cell
        //            case .availableToDrop:
        //                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        //                cell.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        //                return cell
        //        }
    }
    
    //    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    //        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: supplementaryViewIdentifier, for: indexPath as IndexPath) as! SupplementaryView
    //        return headerView
    //    }
}

extension TmpViewController1: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        print(11)
        
        if indexPath.section == 1 {
            return []
        }
        
        let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = data[indexPath.section][indexPath.row]
        return [dragItem]
    }
    
    //    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
    //
    //        print(11)
    //
    //        let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
    //        let dragItem = UIDragItem(itemProvider: itemProvider)
    //        dragItem.localObject = data[indexPath.section][indexPath.row]
    //        return [dragItem]
    //    }
    
    
    //    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
    //
    //        print(12)
    //
    //        var itemsToInsert = [IndexPath]()
    //        (0 ..< data.count).forEach {
    //            itemsToInsert.append(IndexPath(item: data[$0].count, section: $0))
    //            data[$0].append(.availableToDrop)
    //        }
    //        collectionView.insertItems(at: itemsToInsert)
    //    }
    //
    //    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
    //
    //        print(13)
    //
    //        var removeItems = [IndexPath]()
    //        for section in 0..<data.count {
    //            for item in  0..<data[section].count {
    //                switch data[section][item] {
    //                    case .availableToDrop: removeItems.append(IndexPath(item: item, section: section))
    //                    case .simple: break
    //                }
    //            }
    //        }
    //        removeItems.forEach { data[$0.section].remove(at: $0.item) }
    //        collectionView.deleteItems(at: removeItems)
    //    }
}

extension TmpViewController1: UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        print(21)
        
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        switch coordinator.proposal.operation {
        case .move:
            reorderItems(coordinator: coordinator, destinationIndexPath:destinationIndexPath, collectionView: collectionView)
            //            case .copy:
        //                copyItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        default: return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        
        print(22)
        
        return true
        
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath
        destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        print(23)
        
        if collectionView.hasActiveDrag, let destinationIndexPath = destinationIndexPath {
            //            switch data[destinationIndexPath.section][destinationIndexPath.row] {
            //                case .simple:
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            //                case .availableToDrop:
            //                    return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
            //            }
        } else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
    
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        
        print(24)
        
        let items = coordinator.items
        if  items.count == 1, let item = items.first,
            let sourceIndexPath = item.sourceIndexPath,
            let localObject = item.dragItem.localObject as? UIColor {
            
            collectionView.performBatchUpdates ({
                data[sourceIndexPath.section].remove(at: sourceIndexPath.item)
                data[destinationIndexPath.section].insert(localObject, at: destinationIndexPath.item)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            })
        }
    }
    
    //    private func copyItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
    //
    //        print(25)
    //
    //        collectionView.performBatchUpdates({
    //            var indexPaths = [IndexPath]()
    //            for (index, item) in coordinator.items.enumerated() {
    //                if let localObject = item.dragItem.localObject as? CellModel {
    //                    let indexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
    //                    data[indexPath.section].insert(localObject, at: indexPath.row)
    //                    indexPaths.append(indexPath)
    //                }
    //            }
    //            collectionView.insertItems(at: indexPaths)
    //        })
    //    }
}
