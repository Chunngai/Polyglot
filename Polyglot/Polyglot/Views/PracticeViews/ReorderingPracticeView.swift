//
//  ReorderingPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/2/16.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit
import NaturalLanguage

class ReorderingPracticeView: WordPracticeView {
    
    var words: [String]!
    var shuffledWords: [String]!
        
    private var items: [(view: UIView, originalCenter: CGPoint)] = []
    
    // TODO: - Merge the two arrs?
    private var itemsInRowStack: [UIView] = []
    private var centersInRowStack: [CGPoint] = []
    
    private lazy var initialCenterXInRowStack: CGFloat = rowStack.frame.minX
    private lazy var initialCenterYInRowStack: CGFloat = rowStack.frame.minY + ReorderingPracticeView.rowHeight / 2
        
    var answer: String {
        let wordsInRowStack = itemsInRowStack.map { (item) -> String in
            return (item as! UILabel).text!
        }
        
        let answer = wordsInRowStack.joined(separator: Strings.wordSeparator)
        return answer
    }
    
    // MARK: - Controllers
    
    var delegate: WordsPracticeViewController!
    
    // MARK: - Views
        
    // Should init the row stack after
    // the frame width is determined.
    var rowStack: UIStackView!
    
    // Should init the word bank after
    // textWords and randomWords are provided.
    var wordBank: WordBank!
    
    var translationLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.weakTextColor
        label.font = UIFont.systemFont(ofSize: Sizes.practiceFontSize)
        label.numberOfLines = 0
        return label
    }()
    
    var referenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.normalTextColor
        label.font = WordBankItem.labelFont
        label.isHidden = true
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var counter: Int = 0  // TODO: - a workaround for preventing recursions.
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if counter == 2 {
            return
        }
        counter += 1
        
        if frame != .zero {
            rowStack = {
                let rowNumber: Int = ReorderingPracticeView.calculateRowNumber(words: self.words)
                let rows: [RowStackItem] = (0..<rowNumber).map { _ in RowStackItem() }
                
                let stackView = UIStackView(arrangedSubviews: rows)
                stackView.axis = .vertical
                stackView.alignment = .center
                stackView.distribution = .equalSpacing
                stackView.spacing = ReorderingPracticeView.rowStackVerticalSpacing
                return stackView
            }()
            addSubview(rowStack)
            // Move to back, otherwise will obscure the items.
            sendSubviewToBack(rowStack)
            
            wordBank.snp.updateConstraints { (make) in
                make.width.equalTo(Sizes.reorderingWordBankWidth)
                // https://stackoverflow.com/questions/42437966/how-to-adjust-height-of-uicollectionview-to-be-the-height-of-the-content-size-of
                make.height.equalTo(wordBank.collectionViewLayout.collectionViewContentSize.height)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-10)
            }
            referenceLabel.snp.makeConstraints { (make) in
                make.top.equalTo(wordBank.snp.top)
                make.left.equalTo(wordBank.snp.left)
                make.width.equalTo(wordBank.snp.width)
            }
            
            rowStack.snp.makeConstraints { (make) in
                make.bottom.equalTo(wordBank.snp.top).offset(-(
                    ReorderingPracticeView.rowHeight
                        + ReorderingPracticeView.rowStackVerticalSpacing * 2
                ))
                make.width.equalTo(Sizes.reorderingRowStackWidth)
                make.centerX.equalToSuperview()
            }
            for row in rowStack.arrangedSubviews {
                row.snp.makeConstraints { (make) in
                    make.width.equalToSuperview()
                    make.height.equalTo(ReorderingPracticeView.rowHeight)
                }
            }
        }
    }
    
    private func updateSetups() {
        
    }
    
    private func updateViews() {
        addSubview(translationLabel)
    }
    
    private func updateLayouts() {
        translationLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    func updateValues(words: [String]) {
        
        GoogleTranslator(
            srcLang: LangCode.currentLanguage,
            trgLang: LangCode.pairedLanguage
        ).translate(query: words.joined(separator: Strings.wordSeparator)) { (res) in
            if let translation = res.first {
                DispatchQueue.main.async {
                    self.translationLabel.text = translation
                }
            }
        }
        
        self.words = words
        self.shuffledWords = words.shuffled()
                
        wordBank = WordBank(words: shuffledWords)
        addSubview(wordBank)
        
        addSubview(referenceLabel)
        
    }
    
    // MARK: - Methods from the Super Class
    
    override func submit() -> String {
        isUserInteractionEnabled = false
        return answer
    }
    
    override func updateViewsAfterSubmission(for correctness: WordPractice.Correctness, key: String, tokenizer: NLTokenizer) {
        
//        let keyComponents = key.components(from: tokenizer)
//
//        // TODO: - Update here.
//        for item in itemsInRowStack {
//            let text = words[item.tag]
//            if keyComponents.contains(text) {
//                item.backgroundColor = Colors.lightCorrectColor
//            } else {
//                item.backgroundColor = Colors.lightInorrectColor
//            }
//        }
        
        if correctness == .correct {
            for item in itemsInRowStack {
                item.backgroundColor = Colors.correctColor
            }
        } else {
            wordBank.isHidden = true
            items.forEach { (item) in
                if !itemsInRowStack.contains(item.view) {
                    item.view.removeFromSuperview()
                }
            }
            
            referenceLabel.isHidden = false
            referenceLabel.text = "\(Strings.referenceLabelPrefix)\(key)"
        }
        
    }
}

extension ReorderingPracticeView {
    
    private func afterDragAndDrop() {
        if itemsInRowStack.isEmpty {
            delegate.deactivateDoneButton()
        } else {
            delegate.activateDoneButton()
        }
    }
    
}

extension ReorderingPracticeView {
    
    // MARK: - DragAndDrop Views and Layouts
    
    func makeDraggableWordBankItems() {
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
        for i in 0..<self.shuffledWords.count {
            let indexPath = IndexPath(row: i, section: 0)
            guard let cell = wordBank.cellForItem(at: indexPath) as? WordBankItem else {
                continue
            }
            
            let pseudoLabel = WordBankItem.makeLabel()
            pseudoLabel.text = cell.label.text
            pseudoLabel.frame = CGRect(
                x: wordBank.frame.origin.x + cell.frame.minX,
                y: wordBank.frame.origin.y + cell.frame.minY,
                width: cell.frame.width,
                height: cell.frame.height
            )
            pseudoLabel.isUserInteractionEnabled = true
            pseudoLabel.addGestureRecognizer(panGestureRecognizer)
            pseudoLabel.addGestureRecognizer(tapGestureRecognizer)
            pseudoLabel.tag = i
            
            addSubview(pseudoLabel)
            
            items.append((view: pseudoLabel, originalCenter: pseudoLabel.center))
            
            // Hide the original label.
            cell.label.backgroundColor = Colors.lightGrayBackgroundColor
            cell.label.text = nil
        }
    }
    
    static func calculateRowNumber(words: [String]) -> Int {
        
        var rowNumber: Int = 1
        var summedWidth: CGFloat = 0
        for word in words {
            
            let itemWidth = (
                WordBank.itemHorizontalPadding
                    + word.textSize(withFont: WordBankItem.labelFont).width
                    + WordBank.itemHorizontalPadding
            )
            
            summedWidth += itemWidth
            if summedWidth > Sizes.reorderingRowStackWidth {
                rowNumber += 1
                summedWidth = itemWidth
            }
            summedWidth += ReorderingPracticeView.rowStackHorizontalSpacing
        }
        
        return rowNumber
    }
}

extension ReorderingPracticeView {
    
    // MARK: - DragAndDrop Logic
    
    private func move(_ item: UIView, to newCenter: CGPoint, animated: Bool = true) {
        // https://stackoverflow.com/questions/46436856/how-to-check-to-see-if-one-view-is-on-top-of-another-view

        func _move() {
            item.center = newCenter
        }
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                _move()
            }
        } else {
            _move()
        }
    }
    
    private func isInAnswerArea(_ item: UIView) -> Bool {
        return item.frame.maxY >= rowStack.frame.minY
            && item.frame.maxY < wordBank.frame.minY
    }
    
    private func updateCentersInRowStack() {
        
        if itemsInRowStack.isEmpty {
            return
        }
        
        centersInRowStack = []
        var centerX: CGFloat = initialCenterXInRowStack
        var centerY: CGFloat = initialCenterYInRowStack
        for i in 0..<itemsInRowStack.count {
            let item = itemsInRowStack[i]
            
            if i - 1 >= 0 {
                centerX += itemsInRowStack[i - 1].frame.halfWidth
                    + ReorderingPracticeView.rowStackHorizontalSpacing
            }
            centerX += item.frame.halfWidth

            if centerX + item.frame.halfWidth > rowStack.frame.maxX {
                centerX = initialCenterXInRowStack + item.frame.halfWidth
                centerY += ReorderingPracticeView.rowStackVerticalSpacing
                    + ReorderingPracticeView.rowHeight
            }
            
            centersInRowStack.append(CGPoint(
                x: centerX,
                y: centerY
            ))
        }
    }
    
    private func updateRowStackLayouts(exceptItem excludedItem: UIView? = nil) {
        for (item, center) in zip(itemsInRowStack, centersInRowStack) {
            if excludedItem != nil, item == excludedItem! {
                continue
            }
            move(item, to: center)
        }
    }
    
    private func addToRowStack(_ item: UIView) {
        
        // Determine the center.
        var centerX: CGFloat!
        var centerY: CGFloat!
        if let lastItem = itemsInRowStack.last {
            centerX = lastItem.frame.maxX
                + ReorderingPracticeView.rowStackHorizontalSpacing
                + item.frame.halfWidth
            centerY = lastItem.center.y
            
            if centerX + item.frame.halfWidth > rowStack.frame.maxX {
                centerX = initialCenterXInRowStack + item.frame.halfWidth
                centerY += ReorderingPracticeView.rowStackVerticalSpacing
                    + ReorderingPracticeView.rowHeight
            }
        } else {
            centerX = initialCenterXInRowStack + item.frame.halfWidth
            centerY = initialCenterYInRowStack
        }
        
        itemsInRowStack.append(item)
        centersInRowStack.append(CGPoint(
            x: centerX,
            y: centerY
        ))
    }
    
    private func removeFromRowStack(_ item: UIView) {

        if let itemIndex = itemsInRowStack.firstIndex(of: item) {
            
            centersInRowStack.remove(at: itemIndex)
            itemsInRowStack.remove(at: itemIndex)
            
            if itemIndex != itemsInRowStack.count {
                updateCentersInRowStack()
            }
        }
    }
    
    private func moveWithinRowStack(_ item: UIView, translation: CGPoint) {
        
        print("###")
        print("translation.x:", translation.x)
        print("translation.y:", translation.y)
        
        var itemIndex = itemsInRowStack.firstIndex(of: item)!
        print("index of current item:", itemIndex)
        
        func updateHorizontalMoving() {
            if translation.x < 0 {  // To left.
                
                var indexOfPreviousItem = itemIndex - 1
                if indexOfPreviousItem < 0 {
                    return
                }
                print("index of previous item:", indexOfPreviousItem)
                
                let previousItem = itemsInRowStack[indexOfPreviousItem]
                if !previousItem.frame.intersects(item.frame) {
                    return
                }
                
                // Obtain the maxX of the previous item.
                let maxXOfPreviousItem = previousItem.frame.maxX
                print("maxX of previous item:", maxXOfPreviousItem)
                
                // Obtain the minX of the dragging item.
                let minXOfDraggingItem = item.frame.minX
                print("minX of dragging item:", minXOfDraggingItem)
            
                if maxXOfPreviousItem > minXOfDraggingItem {
                    print("intersected with the previous item")
                    Feedbacks.defaultFeedbackGenerator.selectionChanged()
                    
                    // Swap the two items.
                    itemsInRowStack.swapAt(indexOfPreviousItem, itemIndex)
                    centersInRowStack.swapAt(indexOfPreviousItem, itemIndex)
                    // Update the indices.
                    (indexOfPreviousItem, itemIndex) = (itemIndex, indexOfPreviousItem)
                    
                    // Update the centers.
                    // DO NOT ONLY UPDATE THE CENTERS OF
                    // THE CURRENT ITEM AND THE PREVIOUS ITEM.
                    // OTHERWISE THE NEW CENTERS MAY BE INCORRECT
                    // WHEN THE DRAGGING ITEM IS BOTH VERTICALLY AND HORIZONTALLY
                    // DRAGGING.
                    updateCentersInRowStack()
                }
            } else if translation.x > 0 {  // To right.
                
                var indexOfNextItem = itemIndex + 1
                if indexOfNextItem > itemsInRowStack.count - 1 {
                    return
                }
                print("index of next item:", indexOfNextItem)
                
                let nextItem = itemsInRowStack[indexOfNextItem]
                if !item.frame.intersects(nextItem.frame) {
                    return
                }
                
                // Obtain the minX of the next item.
                let maxXOfNextItem = nextItem.frame.maxX
                print("maxX of next item:", maxXOfNextItem)
                
                // Obtain the maxX of the dragging item.
                let maxXOfDraggingItem = item.frame.maxX
                print("maxX of dragging item:", maxXOfDraggingItem)
                
                if maxXOfDraggingItem > maxXOfNextItem {
                    print("intersected with the next item")
                    Feedbacks.defaultFeedbackGenerator.selectionChanged()
                    
                    // Swap the two items.
                    itemsInRowStack.swapAt(itemIndex, indexOfNextItem)
                    centersInRowStack.swapAt(itemIndex, indexOfNextItem)
                    // Update the indices.
                    (itemIndex, indexOfNextItem) = (indexOfNextItem, itemIndex)
                    
                    // Update the centers.
                    // DO NOT ONLY UPDATE THE CENTERS OF
                    // THE CURRENT ITEM AND THE NEXT ITEM.
                    // OTHERWISE THE NEW CENTERS MAY BE INCORRECT
                    // WHEN THE DRAGGING ITEM IS BOTH VERTICALLY AND HORIZONTALLY
                    // DRAGGING.
                    updateCentersInRowStack()
                }
            }
        }
        
        func updateVerticalMoving() {
            if translation.y < 0 {  // Up.
                
                // Calculate the vertical offset.
                let currentMinY = item.frame.minY
                print("current minY:", currentMinY)
                let originalMinY = centersInRowStack[itemIndex].y - ReorderingPracticeView.rowHeight / 2
                print("original minY:", originalMinY)
                let verticalOffset = -(currentMinY - originalMinY)
                print("vertical offset:", verticalOffset)
                
                if verticalOffset > ReorderingPracticeView.rowStackVerticalSpacing {
                    print("intersected with the upper row.")
                    Feedbacks.defaultFeedbackGenerator.selectionChanged()
                    
                    // Calculate the new center y.
                    let newCenterY: CGFloat = centersInRowStack[itemIndex].y
                        - ReorderingPracticeView.rowHeight / 2
                        - ReorderingPracticeView.rowStackVerticalSpacing
                        - ReorderingPracticeView.rowHeight / 2
                    print("new center y:", newCenterY)
                    
                    // Obtain the first item in the same row.
                    var indexOfFirstItemInSameRow: Int = 0
                    for i in 0..<itemIndex {
                        let wordCenterY = centersInRowStack[i].y
                        if Int(wordCenterY) != Int(newCenterY) {  // TAKE CARE OF FLOATING POINT ERRORS.
                            indexOfFirstItemInSameRow += 1
                        } else {
                            break
                        }
                    }
                    print("index of first item in same row:", indexOfFirstItemInSameRow)
                    
                    // Calculate the new index.
                    var newIndex = indexOfFirstItemInSameRow
                    for i in indexOfFirstItemInSameRow..<itemsInRowStack.count {
                        // The y of the current item is in the same row as the new center y.
                        let wordItem = itemsInRowStack[i]
                        if wordItem.frame.maxX < item.frame.minX {
                            newIndex = i + 1
                        } else {
                            break
                        }
                    }
                    print("new index:", newIndex)
                    
                    // Update the word items.
                    let item = itemsInRowStack.remove(at: itemIndex)
                    itemsInRowStack.insert(item, at: newIndex)
                    
                    // Update the centers.
                    updateCentersInRowStack()
                }
                
            } else if translation.y > 0 {  // Down.
                                
                // Calculate the vertical offset.
                let currentMinY = item.frame.minY
                print("current minY:", currentMinY)
                let originalMinY = centersInRowStack[itemIndex].y - ReorderingPracticeView.rowHeight / 2
                print("original minY:", originalMinY)
                let verticalOffset = currentMinY - originalMinY
                print("vertical offset:", verticalOffset)
                
                if verticalOffset > ReorderingPracticeView.rowHeight {
                    print("intersected with the lower row.")
                    Feedbacks.defaultFeedbackGenerator.selectionChanged()
                    
                    // Calculate the new center y.
                    let newCenterY: CGFloat = centersInRowStack[itemIndex].y
                        + ReorderingPracticeView.rowHeight / 2
                        + ReorderingPracticeView.rowStackVerticalSpacing
                        + ReorderingPracticeView.rowHeight / 2
                    print("new center y:", newCenterY)
                    
                    // Obtain the first item in the same row.
                    var indexOfFirstItemInSameRow: Int = itemIndex
                    for i in itemIndex..<itemsInRowStack.count {
                        let wordCenterY = centersInRowStack[i].y
                        if wordCenterY != newCenterY {
                            indexOfFirstItemInSameRow += 1
                        } else {
                            break
                        }
                    }
                    print("index of first item in same row:", indexOfFirstItemInSameRow)
                    
                    // Calculate the new index.
                    var newIndex = indexOfFirstItemInSameRow
                    for i in indexOfFirstItemInSameRow..<itemsInRowStack.count {
                        // The y of the current item is in the same row as the new center y.
                        let wordItem = itemsInRowStack[i]
                        if wordItem.frame.maxX < item.frame.minX {
                            newIndex = i + 1
                        } else {
                            break
                        }
                    }
                    if newIndex > itemsInRowStack.count - 1 {  // When moved to an empty row.
                        newIndex = itemsInRowStack.count - 1
                    }
                    print("new index:", newIndex)
                    
                    // Update the item items.
                    let item = itemsInRowStack.remove(at: itemIndex)
                    itemsInRowStack.insert(item, at: newIndex)
                    
                    // Update the centers.
                    updateCentersInRowStack()
                }
            }
        }
        
        updateHorizontalMoving()
        updateVerticalMoving()
    }
    
    // MARK: - Selectors
    
    @objc private func cellPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        // https://stackoverflow.com/questions/25503537/swift-uigesturerecogniser-follow-finger
        
        guard let item = gestureRecognizer.view else {
            return
        }
        
        func drag() {
            
            let translation = gestureRecognizer.translation(in: self)
            let newCenter = CGPoint(
                x: item.center.x + translation.x,
                y: item.center.y + translation.y
            )
            move(item, to: newCenter, animated: false)
            
            if isInAnswerArea(item) {
                if !itemsInRowStack.contains(item) {
                    addToRowStack(item)
                } else {
                    moveWithinRowStack(item, translation: translation)
                }
            } else {
                removeFromRowStack(item)
            }
            updateRowStackLayouts(exceptItem: item)
        }
        
        func drop() {
            if isInAnswerArea(item) {
                updateRowStackLayouts()
            } else {
                move(item, to: items[item.tag].originalCenter)
            }
        }
        
        switch gestureRecognizer.state {
        case .began:
            bringSubviewToFront(item)
            drag()
        case .changed:
            drag()
        case .ended:
            drop()
            afterDragAndDrop()
        default:
            break
        }
        
        gestureRecognizer.setTranslation(CGPoint.zero, in: self)
    }
    
    @objc private func cellTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        
        guard let item = gestureRecognizer.view else {
            return
        }
        
        Feedbacks.defaultFeedbackGenerator.selectionChanged()
        
        if !isInAnswerArea(item) {
            addToRowStack(item)
        } else {
            removeFromRowStack(item)
            move(item, to: items[item.tag].originalCenter)
        }
        updateRowStackLayouts()
        
        afterDragAndDrop()
    }
    
}

extension ReorderingPracticeView {
    
    // MARK: - Constants
    
    static let rowHeight: CGFloat = (
        WordBank.itemVerticalPadding
            + " ".textSize(withFont: WordBankItem.labelFont).height
            + WordBank.itemVerticalPadding
    )
    static let rowStackHorizontalSpacing: CGFloat = 3
    static let rowStackVerticalSpacing: CGFloat = 6
}
