////
////  TmpViewController2.swift
////  Polyglot
////
////  Created by Sola on 2023/2/12.
////  Copyright © 2023 Sola. All rights reserved.
////
//
//import UIKit
//import NaturalLanguage
//
//class TmpViewController2: UIViewController {
//
//    // Original centers of the word bank items.
//    private var centersInWordBank: [CGPoint] = []
//    
//    private var itemsInRowStack: [UIView] = []
//    private var centersInRowStack: [CGPoint] = []
//    
//    private var wordBankWidth: CGFloat!
//    private var rowStackWidth: CGFloat!
//    
//    private lazy var initialCenterXInRowStack: CGFloat = rowStack.frame.minX
//    private lazy var initialCenterYInRowStack: CGFloat = rowStack.frame.minY + TmpViewController2.rowHeight / 2
//    
//    // MARK: - Models
//    
//    private var allWords: [String]!
//    
//    // MARK: - Views
//    
//    private lazy var rowStack: UIStackView = {
//        let rowNumber: Int = calculateRowNumber()
//        let rows: [RowStackItem] = (0..<rowNumber).map { (_) -> RowStackItem in
//            return RowStackItem()
//        }
//        
//        let stackView = UIStackView(arrangedSubviews: rows)
//        stackView.backgroundColor = Colors.lightGrayBackgroundColor
//        stackView.axis = .vertical
//        stackView.alignment = .center
//        stackView.distribution = .equalSpacing
//        stackView.spacing = TmpViewController2.rowStackVerticalSpacing
//        return stackView
//    }()
//    
//    private lazy var wordBank: WordBank = WordBank(words: allWords)
//    
//    // MARK: - Init
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        updateSetups()
//        updateViews()
//        updateLayouts()
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        wordBank.snp.updateConstraints { (make) in
//            make.width.equalTo(wordBankWidth)
//            // https://stackoverflow.com/questions/42437966/how-to-adjust-height-of-uicollectionview-to-be-the-height-of-the-content-size-of
//            make.height.equalTo(wordBank.collectionViewLayout.collectionViewContentSize.height)
//            make.centerX.equalToSuperview()
//            make.bottom.equalToSuperview().inset(200)
//        }
//        
//        rowStack.snp.makeConstraints { (make) in
//            make.bottom.equalTo(wordBank.snp.top).offset(-50)
//            make.width.equalTo(rowStackWidth)
//            make.centerX.equalToSuperview()
//        }
//        for row in rowStack.arrangedSubviews {
//            row.snp.makeConstraints { (make) in
//                make.width.equalToSuperview()
//                make.height.equalTo(TmpViewController2.rowHeight)
//            }
//        }
//        
//        self.view.layoutIfNeeded()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        makeDraggableWordBankItems()
//    }
//    
//    private func updateSetups() {
//        wordBankWidth = view.frame.width * 0.85
//        rowStackWidth = view.frame.width * 0.85
//    }
//    
//    private func updateViews() {
//        view.backgroundColor = Colors.defaultBackgroundColor
//        view.addSubview(rowStack)
//        view.addSubview(wordBank)
//    }
//    
//    private func updateLayouts() {
//        
//    }
//    
//    func updateValues(words: [String]) {
//        self.allWords = words
//    }
//}
//
//extension TmpViewController2 {
//    
//    private func makeDraggableWordBankItems() {
//        var panGestureRecognizer: UIPanGestureRecognizer {
//            return UIPanGestureRecognizer(
//                target: self,
//                action: #selector(cellPanned(_:))
//            )
//        }
//        var tapGestureRecognizer: UITapGestureRecognizer {
//            return UITapGestureRecognizer(
//                target: self,
//                action: #selector(cellTapped(_:))
//            )
//        }
//        for i in 0..<allWords.count {
//            let indexPath = IndexPath(row: i, section: 0)
//            guard let cell = wordBank.cellForItem(at: indexPath) as? WordBankItem else {
//                continue
//            }
//            guard let labelSnapShot = cell.label.snapshotView(afterScreenUpdates: false) else {
//                continue
//            }
//            
//            labelSnapShot.frame = CGRect(
//                x: wordBank.frame.origin.x + cell.frame.minX,
//                y: wordBank.frame.origin.y + cell.frame.minY,
//                width: cell.frame.width,
//                height: cell.frame.height
//            )
//            labelSnapShot.addGestureRecognizer(panGestureRecognizer)
//            labelSnapShot.addGestureRecognizer(tapGestureRecognizer)
//            labelSnapShot.tag = i
//            
//            view.addSubview(labelSnapShot)
//            
//            centersInWordBank.append(labelSnapShot.center)
//            
//            // Hide the original label.
//            cell.label.backgroundColor = Colors.lightGrayBackgroundColor
//            cell.label.text = nil
//        }
//    }
//    
//    private func calculateRowNumber() -> Int {
//        
//        var rowNumber: Int = 1
//        var summedWidth: CGFloat = 0
//        for word in self.allWords {
//            
//            let itemWidth = (
//                WordBank.itemHorizontalPadding
//                    + word.textSize(withFont: WordBankItem.labelFont).width
//                    + WordBank.itemHorizontalPadding
//            )
//            
//            summedWidth += itemWidth
//            if summedWidth > self.rowStackWidth {
//                rowNumber += 1
//                summedWidth = 0
//            }
//        }
//        
//        return rowNumber
//    }
//}
//
//extension TmpViewController2 {
//    
//    private func move(_ item: UIView, to newCenter: CGPoint, animated: Bool = true) {
//        // https://stackoverflow.com/questions/46436856/how-to-check-to-see-if-one-view-is-on-top-of-another-view
//
//        func _move() {
//            item.center = newCenter
//        }
//        
//        if animated {
//            UIView.animate(withDuration: 0.3) {
//                _move()
//            }
//        } else {
//            _move()
//        }
//    }
//    
//    private func isInAnswerArea(_ item: UIView) -> Bool {
//        return item.frame.maxY >= rowStack.frame.minY
//            && item.frame.maxY < wordBank.frame.minY
//    }
//    
//    private func updateCentersInRowStack() {
//        
//        if itemsInRowStack.isEmpty {
//            return
//        }
//        
//        centersInRowStack = []
//        var centerX: CGFloat = initialCenterXInRowStack
//        var centerY: CGFloat = initialCenterYInRowStack
//        for i in 0..<itemsInRowStack.count {
//            let item = itemsInRowStack[i]
//            
//            if i - 1 >= 0 {
//                centerX += itemsInRowStack[i - 1].frame.halfWidth
//                    + TmpViewController2.rowStackHorizontalSpacing
//            }
//            centerX += item.frame.halfWidth
//
//            if centerX + item.frame.halfWidth > rowStack.frame.maxX {
//                centerX = initialCenterXInRowStack + item.frame.halfWidth
//                centerY += TmpViewController2.rowStackVerticalSpacing
//                    + TmpViewController2.rowHeight
//            }
//            
//            centersInRowStack.append(CGPoint(
//                x: centerX,
//                y: centerY
//            ))
//        }
//    }
//    
//    private func updateRowStackLayouts(exceptItem excludedItem: UIView? = nil) {
//        for (item, center) in zip(itemsInRowStack, centersInRowStack) {
//            if excludedItem != nil, item == excludedItem! {
//                continue
//            }
//            move(item, to: center)
//        }
//    }
//    
//    private func addToRowStack(_ item: UIView) {
//        
//        // Determine the center.
//        var centerX: CGFloat!
//        var centerY: CGFloat!
//        if let lastItem = itemsInRowStack.last {
//            centerX = lastItem.frame.maxX
//                + TmpViewController2.rowStackHorizontalSpacing
//                + item.frame.halfWidth
//            centerY = lastItem.center.y
//            
//            if centerX + item.frame.halfWidth > rowStack.frame.maxX {
//                centerX = initialCenterXInRowStack + item.frame.halfWidth
//                centerY += TmpViewController2.rowStackVerticalSpacing
//                    + TmpViewController2.rowHeight
//            }
//        } else {
//            centerX = initialCenterXInRowStack + item.frame.halfWidth
//            centerY = initialCenterYInRowStack
//        }
//        
//        itemsInRowStack.append(item)
//        centersInRowStack.append(CGPoint(
//            x: centerX,
//            y: centerY
//        ))
//    }
//    
//    private func removeFromRowStack(_ item: UIView) {
//
//        if let itemIndex = itemsInRowStack.firstIndex(of: item) {
//            
//            centersInRowStack.remove(at: itemIndex)
//            itemsInRowStack.remove(at: itemIndex)
//            
//            if itemIndex != itemsInRowStack.count {
//                updateCentersInRowStack()
//            }
//        }
//    }
//    
//    private func moveWithinRowStack(_ item: UIView, translation: CGPoint) {
//        
//        print("###")
//        print("translation.x:", translation.x)
//        print("translation.y:", translation.y)
//        
//        var itemIndex = itemsInRowStack.firstIndex(of: item)!
//        print("index of current item:", itemIndex)
//        
//        func updateHorizontalMoving() {
//            if translation.x < 0 {  // To left.
//                
//                var indexOfPreviousItem = itemIndex - 1
//                if indexOfPreviousItem < 0 {
//                    return
//                }
//                print("index of previous item:", indexOfPreviousItem)
//                
//                let previousItem = itemsInRowStack[indexOfPreviousItem]
//                if !previousItem.frame.intersects(item.frame) {
//                    return
//                }
//                
//                // Obtain the maxX of the previous item.
//                let maxXOfPreviousItem = previousItem.frame.maxX
//                print("maxX of previous item:", maxXOfPreviousItem)
//                
//                // Obtain the minX of the dragging item.
//                let minXOfDraggingItem = item.frame.minX
//                print("minX of dragging item:", minXOfDraggingItem)
//            
//                if maxXOfPreviousItem > minXOfDraggingItem {
//                    print("intersected with the previous item")
//                    
//                    // Swap the two items.
//                    itemsInRowStack.swapAt(indexOfPreviousItem, itemIndex)
//                    centersInRowStack.swapAt(indexOfPreviousItem, itemIndex)
//                    // Update the indices.
//                    (indexOfPreviousItem, itemIndex) = (itemIndex, indexOfPreviousItem)
//                    
//                    // Recalculate the centers.
//                    centersInRowStack[indexOfPreviousItem].x += (TmpViewController2.rowStackHorizontalSpacing + item.frame.width)
//                    centersInRowStack[itemIndex].x -= (TmpViewController2.rowStackHorizontalSpacing + previousItem.frame.width)
//                }
//            } else if translation.x > 0 {  // To right.
//                
//                var indexOfNextItem = itemIndex + 1
//                if indexOfNextItem > itemsInRowStack.count - 1 {
//                    return
//                }
//                print("index of next item:", indexOfNextItem)
//                
//                let nextItem = itemsInRowStack[indexOfNextItem]
//                if !item.frame.intersects(nextItem.frame) {
//                    return
//                }
//                
//                // Obtain the minX of the next item.
//                let maxXOfNextItem = nextItem.frame.maxX
//                print("maxX of next item:", maxXOfNextItem)
//                
//                // Obtain the maxX of the dragging item.
//                let maxXOfDraggingItem = item.frame.maxX
//                print("maxX of dragging item:", maxXOfDraggingItem)
//                
//                if maxXOfDraggingItem > maxXOfNextItem {
//                    print("intersected with the next item")
//                    
//                    // Swap the two items.
//                    itemsInRowStack.swapAt(itemIndex, indexOfNextItem)
//                    centersInRowStack.swapAt(itemIndex, indexOfNextItem)
//                    // Update the indices.
//                    (itemIndex, indexOfNextItem) = (indexOfNextItem, itemIndex)
//                    
//                    // Recalculate the centers.
//                    centersInRowStack[itemIndex].x += (TmpViewController2.rowStackHorizontalSpacing + nextItem.frame.width)
//                    centersInRowStack[indexOfNextItem].x -= (TmpViewController2.rowStackHorizontalSpacing + item.frame.width)
//                }
//            }
//        }
//        
//        func updateVerticalMoving() {
//            if translation.y < 0 {  // Up.
//                
//                // Calculate the vertical offset.
//                let currentMinY = item.frame.minY
//                print("current minY:", currentMinY)
//                let originalMinY = centersInRowStack[itemIndex].y - TmpViewController2.rowHeight / 2
//                print("original minY:", originalMinY)
//                let verticalOffset = -(currentMinY - originalMinY)
//                print("vertical offset:", verticalOffset)
//                
//                if verticalOffset > TmpViewController2.rowStackVerticalSpacing {
//                    print("intersected with the upper row.")
//                    
//                    // Calculate the new center y.
//                    let newCenterY: CGFloat = centersInRowStack[itemIndex].y
//                        - TmpViewController2.rowHeight / 2
//                        - TmpViewController2.rowStackVerticalSpacing
//                        - TmpViewController2.rowHeight / 2
//                    print("new center y:", newCenterY)
//                    
//                    // Obtain the first item in the same row.
//                    var indexOfFirstItemInSameRow: Int = 0
//                    for i in 0..<itemIndex {
//                        let wordCenterY = centersInRowStack[i].y
//                        if wordCenterY != newCenterY {
//                            indexOfFirstItemInSameRow += 1
//                        } else {
//                            break
//                        }
//                    }
//                    print("index of first item in same row:", indexOfFirstItemInSameRow)
//                    
//                    // Calculate the new index.
//                    var newIndex = indexOfFirstItemInSameRow
//                    for i in indexOfFirstItemInSameRow..<itemsInRowStack.count {
//                        // The y of the current item is in the same row as the new center y.
//                        let wordItem = itemsInRowStack[i]
//                        if wordItem.frame.maxX < item.frame.minX {
//                            newIndex = i + 1
//                        } else {
//                            break
//                        }
//                    }
//                    print("new index:", newIndex)
//                    
//                    // Update the word items.
//                    let item = itemsInRowStack.remove(at: itemIndex)
//                    itemsInRowStack.insert(item, at: newIndex)
//                    
//                    // Update the centers.
//                    updateCentersInRowStack()
//                }
//                
//            } else if translation.y > 0 {  // Down.
//                                
//                // Calculate the vertical offset.
//                let currentMinY = item.frame.minY
//                print("current minY:", currentMinY)
//                let originalMinY = centersInRowStack[itemIndex].y - TmpViewController2.rowHeight / 2
//                print("original minY:", originalMinY)
//                let verticalOffset = currentMinY - originalMinY
//                print("vertical offset:", verticalOffset)
//                
//                if verticalOffset > TmpViewController2.rowHeight {
//                    print("intersected with the lower row.")
//                    
//                    // Calculate the new center y.
//                    let newCenterY: CGFloat = centersInRowStack[itemIndex].y
//                        + TmpViewController2.rowHeight / 2
//                        + TmpViewController2.rowStackVerticalSpacing
//                        + TmpViewController2.rowHeight / 2
//                    print("new center y:", newCenterY)
//                    
//                    // Obtain the first item in the same row.
//                    var indexOfFirstItemInSameRow: Int = itemIndex
//                    for i in itemIndex..<itemsInRowStack.count {
//                        let wordCenterY = centersInRowStack[i].y
//                        if wordCenterY != newCenterY {
//                            indexOfFirstItemInSameRow += 1
//                        } else {
//                            break
//                        }
//                    }
//                    print("index of first item in same row:", indexOfFirstItemInSameRow)
//                    
//                    // Calculate the new index.
//                    var newIndex = indexOfFirstItemInSameRow
//                    for i in indexOfFirstItemInSameRow..<itemsInRowStack.count {
//                        // The y of the current item is in the same row as the new center y.
//                        let wordItem = itemsInRowStack[i]
//                        if wordItem.frame.maxX < item.frame.minX {
//                            newIndex = i + 1
//                        } else {
//                            break
//                        }
//                    }
//                    if newIndex > itemsInRowStack.count - 1 {  // When moved to an empty row.
//                        newIndex = itemsInRowStack.count - 1
//                    }
//                    print("new index:", newIndex)
//                    
//                    // Update the item items.
//                    let item = itemsInRowStack.remove(at: itemIndex)
//                    itemsInRowStack.insert(item, at: newIndex)
//                    
//                    // Update the centers.
//                    updateCentersInRowStack()
//                }
//            }
//        }
//        
//        updateHorizontalMoving()
//        updateVerticalMoving()
//    }
//    
//    // MARK: - Selectors
//    
//    @objc private func cellPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
//        
//        // https://stackoverflow.com/questions/25503537/swift-uigesturerecogniser-follow-finger
//        
//        guard let item = gestureRecognizer.view else {
//            return
//        }
//        
//        func drag() {
//            
//            let translation = gestureRecognizer.translation(in: self.view)
//            let newCenter = CGPoint(
//                x: item.center.x + translation.x,
//                y: item.center.y + translation.y
//            )
//            move(item, to: newCenter, animated: false)
//            
//            if isInAnswerArea(item) {
//                if !itemsInRowStack.contains(item) {
//                    addToRowStack(item)
//                } else {
//                    moveWithinRowStack(item, translation: translation)
//                }
//            } else {
//                removeFromRowStack(item)
//            }
//            updateRowStackLayouts(exceptItem: item)
//        }
//        
//        func drop() {
//            if isInAnswerArea(item) {
//                updateRowStackLayouts()
//            } else {
//                move(item, to: centersInWordBank[item.tag])
//            }
//        }
//        
//        switch gestureRecognizer.state {
//        case .began:
//            self.view.bringSubviewToFront(item)
//            drag()
//        case .changed:
//            drag()
//        case .ended:
//            drop()
//        default:
//            break
//        }
//        
//        gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
//    }
//    
//    @objc private func cellTapped(_ gestureRecognizer: UITapGestureRecognizer) {
//        
//        guard let item = gestureRecognizer.view else {
//            return
//        }
//        
//        if !isInAnswerArea(item) {
//            addToRowStack(item)
//        } else {
//            removeFromRowStack(item)
//            move(item, to: centersInWordBank[item.tag])
//        }
//        updateRowStackLayouts()
//    }
//    
//}
//
//extension TmpViewController2 {
//    
//    // MARK: - Constants
//    
//    static let rowHeight: CGFloat = (
//        WordBank.itemVerticalPadding
//            + " ".textSize(withFont: WordBankItem.labelFont).height
//            + WordBank.itemVerticalPadding
//    )
//    static let rowStackHorizontalSpacing: CGFloat = 3
//    static let rowStackVerticalSpacing: CGFloat = 6
//}
