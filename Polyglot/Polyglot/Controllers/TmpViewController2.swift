//
//  TmpViewController2.swift
//  Polyglot
//
//  Created by Sola on 2023/2/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit
import NaturalLanguage

class TmpViewController2: UIViewController {

    private var wordCentersInPool: [CGPoint] = []
    private var wordButtonsInRowStack: [UIView] = []
    private var wordCentersInRowStack: [CGPoint] = []
    
    private var wordBankWidth: CGFloat!
    private var rowStackWidth: CGFloat!
    
    // MARK: - Models
    
    private var words: [String]!
    
    // MARK: - Views
    
    private lazy var rowStack: UIStackView = {
    
        func calculateRowNumber() -> Int {
            
            var rowNumber: Int = 1
            var summedWidth: CGFloat = 0
            for word in self.words {
                
                let itemWidth = (
                    WordBank.itemHorizontalPadding
                        + word.textSize(withFont: WordBankItem.labelFont).width
                        + WordBank.itemHorizontalPadding
                )
                
                summedWidth += itemWidth
                if summedWidth > self.rowStackWidth {
                    rowNumber += 1
                    summedWidth = 0
                }
            }
            // Handle the last row.
            if summedWidth != 0 {
                rowNumber += 1
            }
            
            return rowNumber
        }
        
        let rowNumber: Int = calculateRowNumber()
        let rows: [WordBankItemRow] = (0..<rowNumber).map { (_) -> WordBankItemRow in
            return WordBankItemRow()
        }
        
        let stackView = UIStackView(arrangedSubviews: rows)
        stackView.backgroundColor = Colors.lightGrayBackgroundColor
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = Sizes.defaultStackSpacing
        stackView.spacing = TmpViewController2.rowStackVerticalSpacing
        return stackView
    }()
    
    private lazy var wordBank: WordBank = WordBank(words: words)
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateSetups()
        updateViews()
        updateLayouts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        wordBank.snp.updateConstraints { (make) in
                        
            make.width.equalTo(wordBankWidth)
            // https://stackoverflow.com/questions/42437966/how-to-adjust-height-of-uicollectionview-to-be-the-height-of-the-content-size-of
            make.height.equalTo(wordBank.collectionViewLayout.collectionViewContentSize.height)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(200)
        }
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        makeDraggableWordBankItems()
    }
    
    private func updateSetups() {
        wordBankWidth = view.frame.width
        rowStackWidth = view.frame.width
    }
    
    private func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(rowStack)
        view.addSubview(wordBank)
    }
    
    private func updateLayouts() {
        rowStack.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(300)
            make.width.equalTo(rowStackWidth)
            make.centerX.equalToSuperview()
        }
        for row in rowStack.arrangedSubviews {
            row.snp.makeConstraints { (make) in
                make.width.equalToSuperview()
                make.height.equalTo(TmpViewController2.rowHeight)
            }
        }
    }
    
    func updateValues(words: [String]) {
        self.words = words
    }
}

extension TmpViewController2 {
    
    private func makeDraggableWordBankItems() {
        var panGestureRecognizer: UIPanGestureRecognizer {
            return UIPanGestureRecognizer(
                target: self,
                action: #selector(cellPanned(_:))
            )
        }
        var tapGestureRecognizer: UITapGestureRecognizer {
            return UITapGestureRecognizer(
                target: self,
                action: #selector(cellTapped(_:))
            )
        }
        for i in 0..<words.count {
            let indexPath = IndexPath(row: i, section: 0)
            guard let cell = wordBank.cellForItem(at: indexPath) as? WordBankItem else {
                continue
            }
            guard let labelSnapShot = cell.label.snapshotView(afterScreenUpdates: false) else {
                continue
            }
            
            labelSnapShot.frame = CGRect(
                x: wordBank.frame.origin.x + cell.frame.minX,
                y: wordBank.frame.origin.y + cell.frame.minY,
                width: cell.frame.width,
                height: cell.frame.height
            )
            labelSnapShot.addGestureRecognizer(panGestureRecognizer)
            labelSnapShot.addGestureRecognizer(tapGestureRecognizer)
            labelSnapShot.tag = i
            
            view.addSubview(labelSnapShot)
            
            wordCentersInPool.append(labelSnapShot.center)
            
            // Hide the original label.
            cell.label.backgroundColor = Colors.lightGrayBackgroundColor
            cell.label.text = nil
        }
    }
}

extension TmpViewController2 {
    
    private func updateCenterOf(view: UIView, to newCenter: CGPoint) {
        UIView.animate(withDuration: 0.3) {
            view.center = newCenter
        }
    }
    
    private func isInRowStack(_ view: UIView) -> Bool {
        return rowStack.frame.intersects(view.frame)
    }
    
    private func updateRowStack(_ view: UIView, translation: CGPoint) {
        
        print("###")
        print("translation.x:", translation.x)
        print("translation.y:", translation.y)
        
        var indexOfDraggingButton = wordButtonsInRowStack.firstIndex(of: view)!
        print("index of current button:", indexOfDraggingButton)
        
        if translation.x < 0 {  // <-.
            
            // Obtain the maxX of the previous button.
            var indexOfPreviousButton = indexOfDraggingButton - 1
            if indexOfPreviousButton < 0 {
                return
            }
            print("index of previous button:", indexOfPreviousButton)
            let previousButton = wordButtonsInRowStack[indexOfPreviousButton]
            let maxXOfPreviousButton = previousButton.frame.maxX
            print("maxX of previous button:", maxXOfPreviousButton)
            if !previousButton.frame.intersects(view.frame) {
                return
            }
            
            // Obtain the minX of the dragging button.
            let minXOfDraggingButton = view.frame.minX
            print("minX of dragging button:", minXOfDraggingButton)
        
            if maxXOfPreviousButton > minXOfDraggingButton {
                print("intersected with the previous button")
                
                // Swap the two buttons.
                wordButtonsInRowStack.swapAt(indexOfPreviousButton, indexOfDraggingButton)
                wordCentersInRowStack.swapAt(indexOfPreviousButton, indexOfDraggingButton)
                // Update the indices.
                (indexOfPreviousButton, indexOfDraggingButton) = (indexOfDraggingButton, indexOfPreviousButton)
                
                // Recalculate the centers.
                wordCentersInRowStack[indexOfPreviousButton].x += (TmpViewController2.rowStackHorizontalSpacing + view.frame.width)
                wordCentersInRowStack[indexOfDraggingButton].x -= (TmpViewController2.rowStackHorizontalSpacing + previousButton.frame.width)
                
                // Perform moving.
                updateCenterOf(view: previousButton, to: wordCentersInRowStack[indexOfPreviousButton])
            }
        } else if translation.x > 0 {
            
            // Obtain the minX of the next button.
            var indexOfNextButton = indexOfDraggingButton + 1
            if indexOfNextButton > wordButtonsInRowStack.count - 1 {
                return
            }
            print("index of next button:", indexOfNextButton)
            let nextButton = wordButtonsInRowStack[indexOfNextButton]
            let maxXOfNextButton = nextButton.frame.maxX
            print("maxX of next button:", maxXOfNextButton)
            if !view.frame.intersects(nextButton.frame) {
                return
            }
            
            // Obtain the maxX of the dragging button.
            let maxXOfDraggingButton = view.frame.maxX
            print("maxX of dragging button:", maxXOfDraggingButton)
            
            if maxXOfDraggingButton > maxXOfNextButton {
                print("intersected with the next button")
                
                // Swap the two buttons.
                wordButtonsInRowStack.swapAt(indexOfDraggingButton, indexOfNextButton)
                wordCentersInRowStack.swapAt(indexOfDraggingButton, indexOfNextButton)
                // Update the indices.
                (indexOfDraggingButton, indexOfNextButton) = (indexOfNextButton, indexOfDraggingButton)
                
                // Recalculate the centers.
                wordCentersInRowStack[indexOfDraggingButton].x += (TmpViewController2.rowStackHorizontalSpacing + nextButton.frame.width)
                wordCentersInRowStack[indexOfNextButton].x -= (TmpViewController2.rowStackHorizontalSpacing + view.frame.width)
                
                // Perform moving.
                updateCenterOf(view: nextButton, to: wordCentersInRowStack[indexOfNextButton])
            }
        }
        
        if translation.y < 0 {
            
            // Calculate the vertical offset.
            let currentMinY = view.frame.minY
            print("current minY:", currentMinY)
            let originalMinY = wordCentersInRowStack[indexOfDraggingButton].y - TmpViewController2.rowHeight / 2
            print("original minY:", originalMinY)
            let verticalOffset = -(currentMinY - originalMinY)
            print("vertical offset:", verticalOffset)
            
            if verticalOffset > TmpViewController2.rowStackVerticalSpacing {
                print("intersected with the upper row.")
                
                // Calculate the new center y.
                let newCenterY: CGFloat = wordCentersInRowStack[indexOfDraggingButton].y - TmpViewController2.rowHeight - TmpViewController2.rowStackVerticalSpacing
                print("new center y:", newCenterY)
                
                // Obtain first button in the same row.
                var indexOfFirstButtonInSameRow: Int = 0
                for i in 0..<indexOfDraggingButton {
                    let wordCenterY = wordCentersInRowStack[i].y
                    if wordCenterY != newCenterY {
                        indexOfFirstButtonInSameRow += 1
                    } else {
                        break
                    }
                }
                print("index of first button in same row:", indexOfFirstButtonInSameRow)
                
                // Calculate the new index.
                var newIndex = indexOfFirstButtonInSameRow
                for i in indexOfFirstButtonInSameRow..<wordButtonsInRowStack.count {
                    // The y of the current button is in the same row as the new center y.
                    let wordButton = wordButtonsInRowStack[i]
                    if wordButton.frame.maxX < view.frame.minX {
                        newIndex = i + 1
                    } else {
                        break
                    }
                }
                print("new index:", newIndex)
                
                // Update the word buttons.
                let button = wordButtonsInRowStack.remove(at: indexOfDraggingButton)
                wordButtonsInRowStack.insert(button, at: newIndex)
                
                // Update the centers.
                // TODO: - Not needed to update all.
                updateCenters()
                
                // Perform moving.
                for i in 0..<wordCentersInRowStack.count {
                    if i != newIndex {
                        updateCenterOf(view: wordButtonsInRowStack[i], to: wordCentersInRowStack[i])
                    }
                }
            }
            
        } else if translation.y > 0 {
            // Calculate the vertical offset.
            let currentMinY = view.frame.minY
            print("current minY:", currentMinY)
            let originalMinY = wordCentersInRowStack[indexOfDraggingButton].y - TmpViewController2.rowHeight / 2
            print("original minY:", originalMinY)
            let verticalOffset = currentMinY - originalMinY
            print("vertical offset:", verticalOffset)
            
            if verticalOffset > TmpViewController2.rowStackHorizontalSpacing + TmpViewController2.rowHeight {
                print("intersected with the lower row.")
                
                // Calculate the new center y.
                let newCenterY: CGFloat = wordCentersInRowStack[indexOfDraggingButton].y + TmpViewController2.rowHeight + TmpViewController2.rowStackVerticalSpacing
                print("new center y:", newCenterY)
                
                // Obtain the first button in the same row.
                var indexOfFirstButtonInSameRow: Int = indexOfDraggingButton
                for i in indexOfDraggingButton..<wordButtonsInRowStack.count {
                    let wordCenterY = wordCentersInRowStack[i].y
                    if wordCenterY != newCenterY {
                        indexOfFirstButtonInSameRow += 1
                    } else {
                        break
                    }
                }
                print("index of first button in same row:", indexOfFirstButtonInSameRow)
                
                // Calculate the new index.
                var newIndex = indexOfFirstButtonInSameRow
                for i in indexOfFirstButtonInSameRow..<wordButtonsInRowStack.count {
                    // The y of the current button is in the same row as the new center y.
                    let wordButton = wordButtonsInRowStack[i]
                    if wordButton.frame.maxX < view.frame.minX {
                        newIndex = i + 1
                    } else {
                        break
                    }
                }
                if newIndex > wordButtonsInRowStack.count - 1 {  // When moved to an empty row.
                    newIndex = wordButtonsInRowStack.count - 1
                }
                print("new index:", newIndex)
                
                // Update the word buttons.
                let button = wordButtonsInRowStack.remove(at: indexOfDraggingButton)
                wordButtonsInRowStack.insert(button, at: newIndex)
                
                // Update the centers.
                // TODO: - Not needed to update all.
                updateCenters()
                
                // Perform moving.
                for i in 0..<wordCentersInRowStack.count {
                    if i != newIndex {
                        updateCenterOf(view: wordButtonsInRowStack[i], to: wordCentersInRowStack[i])
                    }
                }
            }
        }
    }
    
    private func updateCenters() {
        
        if wordButtonsInRowStack.isEmpty {
            return
        }
        
        var newCenters: [CGPoint] = []
        var centerX: CGFloat = rowStack.frame.minX
        var centerY: CGFloat = rowStack.frame.minY + TmpViewController2.rowHeight / 2
        for i in 0..<wordButtonsInRowStack.count {
            
            let wordButton = wordButtonsInRowStack[i]
            centerX += wordButton.frame.width / 2
            if i - 1 >= 0 {
                centerX += TmpViewController2.rowStackHorizontalSpacing + wordButtonsInRowStack[i - 1].frame.width / 2
            }
            if centerX + wordButton.frame.width / 2 > rowStack.frame.maxX {
                centerX = rowStack.frame.minX + wordButton.frame.width / 2
                centerY += TmpViewController2.rowHeight + TmpViewController2.rowStackVerticalSpacing
            }
            
            newCenters.append(CGPoint(
                x: centerX,
                y: centerY
            ))
        }
        wordCentersInRowStack = newCenters
    }
    
    private func addToRowStack(_ view: UIView) {
        
        if !wordButtonsInRowStack.contains(view) {
            
            // Determine the center.
            var centerX: CGFloat = rowStack.frame.minX + view.frame.width / 2
            var centerY: CGFloat = rowStack.frame.minY + TmpViewController2.rowHeight / 2
            if let lastButton = wordButtonsInRowStack.last {
                
                centerX = TmpViewController2.rowStackHorizontalSpacing + lastButton.frame.maxX + view.frame.width / 2
                centerY = lastButton.center.y
                if centerX + view.frame.width / 2 > rowStack.frame.maxX {
                    centerX = rowStack.frame.minX + view.frame.width / 2
                    centerY += TmpViewController2.rowHeight + TmpViewController2.rowStackVerticalSpacing
                }
            }
            
            // Add the button.
            wordCentersInRowStack.append(CGPoint(
                x: centerX,
                y: centerY
            ))
            wordButtonsInRowStack.append(view)
        }
    }
    
    private func moveToRowStack(_ view: UIView) {
        if let indexOfButtonToMove = wordButtonsInRowStack.firstIndex(of: view) {
            updateCenterOf(view: view, to: wordCentersInRowStack[indexOfButtonToMove])
        }
    }
    
    private func removeFromRowStack(_ view: UIView) {

        if let buttonIndex = wordButtonsInRowStack.firstIndex(of: view) {
            
            // Remove the button.
            wordCentersInRowStack.remove(at: buttonIndex)
            wordButtonsInRowStack.remove(at: buttonIndex)
            
            // TODO: - Not needed to update if the remove button was the last.
            
            updateCenters()
        }
    }
    
    private func moveOutOfRowStack(_ view: UIView) {
        
        updateCenterOf(view: view, to: wordCentersInPool[view.tag])
        for (wordButton, wordCenter) in zip(wordButtonsInRowStack, wordCentersInRowStack) {
            updateCenterOf(view: wordButton, to: wordCenter)
        }
    }
    
    // MARK: - Selectors
    
    @objc private func cellPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        // https://stackoverflow.com/questions/25503537/swift-uigesturerecogniser-follow-finger
        
        guard let draggingButton = gestureRecognizer.view else {
            return
        }
        
        func drag() {
            
            let translation = gestureRecognizer.translation(in: self.view)
            draggingButton.center = CGPoint(
                x: draggingButton.center.x + translation.x,
                y: draggingButton.center.y + translation.y
            )
            
            if isInRowStack(draggingButton) {
                if !wordButtonsInRowStack.contains(draggingButton) {
                    addToRowStack(draggingButton)
                }
            } else {
                if wordButtonsInRowStack.contains(draggingButton) {
                removeFromRowStack(draggingButton)
                }
            }
            
            if isInRowStack(draggingButton) {
                updateRowStack(draggingButton, translation: translation)
            } else {
                updateCenters()
                for (wordButton, wordCenter) in zip(wordButtonsInRowStack, wordCentersInRowStack) {
                    updateCenterOf(view: wordButton, to: wordCenter)
                }
            }
        }
        
        func drop() {
            
            // https://stackoverflow.com/questions/46436856/how-to-check-to-see-if-one-view-is-on-top-of-another-view
            
            if isInRowStack(draggingButton) {
                // Place into the rowstack.
                moveToRowStack(draggingButton)
            } else {
                // Place back.
                moveOutOfRowStack(draggingButton)
            }
        }
        
        switch gestureRecognizer.state {
        case .began:
            self.view.bringSubviewToFront(draggingButton)
            drag()
        case .changed:
            drag()
        case .ended:
            drop()
        default:
            print("default")
        }
        
        gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @objc private func cellTapped(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        guard let draggingButton = gestureRecognizer.view else {
            return
        }
        
        if isInRowStack(draggingButton) {  // Place back to the pool.
            removeFromRowStack(draggingButton)
            moveOutOfRowStack(draggingButton)
        } else {  // Place to the rows.
            addToRowStack(draggingButton)
            moveToRowStack(draggingButton)
        }
        
    }
}

extension TmpViewController2 {
    
    // MARK: - Constants
    
    static let rowHeight: CGFloat = TmpViewController2.rowStackVerticalSpacing
        + " ".textSize(withFont: WordBankItem.labelFont).height
        + TmpViewController2.rowStackVerticalSpacing
    static let rowStackHorizontalSpacing: CGFloat = 3
    static let rowStackVerticalSpacing: CGFloat = 6
}
