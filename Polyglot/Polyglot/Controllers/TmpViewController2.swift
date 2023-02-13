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
    private var wordButtonsInRowStack: [UIView] = [] {
        didSet {
//            print("wordButtonsInRowStack: \(wordButtonsInRowStack.count)")
        }
    }
    private var wordCentersInRowStack: [CGPoint] = [] {
        didSet {
//            print("wordCentersInRowStack: \(wordCentersInRowStack.count)")
        }
    }
    
//    private var indexOfDraggingButton: Int?
//    private var frameOfDraggingButton: CGRect?
    
    // MARK: - Models
    
    private var words: [String]!
    
    // MARK: - Views
    
    private lazy var rowStack: UIStackView = {
    
        var lines: [UIView] = []
        for _ in 0..<3 {  // TODO: - Dynamic.
            lines.append({
                let view = UIView()
                view.backgroundColor = Colors.lightGrayBackgroundColor
                return view
            }())
        }
        
        let stackView = UIStackView(arrangedSubviews: lines)
        stackView.backgroundColor = Colors.lightGrayBackgroundColor
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = Sizes.defaultStackSpacing
        stackView.spacing = TmpViewController2.rowStackVerticalSpacing
        return stackView
    }()
    
    private lazy var wordPoolCollectionView: UICollectionView = {
        
        let layout: UICollectionViewFlowLayout = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.minimumInteritemSpacing = TmpViewController2.horizontalMargin
            layout.minimumLineSpacing = TmpViewController2.verticalMargin
            return layout
        }()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = Colors.defaultBackgroundColor
        
        return collectionView
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateSetups()
        updateViews()
        updateLayouts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // https://stackoverflow.com/questions/42437966/how-to-adjust-height-of-uicollectionview-to-be-the-height-of-the-content-size-of
        let height = wordPoolCollectionView.collectionViewLayout.collectionViewContentSize.height
        wordPoolCollectionView.snp.updateConstraints { (make) in
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalTo(height)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(200)
        }
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Draw dragable buttons.
        // TODO: - Move elsewhere?
        for i in 0..<words.count {
            let indexPath = IndexPath(row: i, section: 0)
            guard let cell = wordPoolCollectionView.cellForItem(at: indexPath) as? TmpCollectionViewCell else {
                return
            }
            
            let button = TmpCollectionViewCell.createButton()
            // TODO: - Move the button creation code into the collection view cell.
            button.frame = CGRect(
                x: wordPoolCollectionView.frame.origin.x + cell.frame.minX,
                y: wordPoolCollectionView.frame.origin.y + cell.frame.minY,
                width: cell.frame.width,
                height: cell.frame.height
            )
            button.backgroundColor = Colors.strongLightBlue
            button.setTitle(words[i], for: .normal)
            button.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(cellPanned(_:))))
            button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:))))
            button.tag = i
            view.addSubview(button)
            wordCentersInPool.append(button.center)
            
            cell.backgroundButton.backgroundColor = Colors.lightGrayBackgroundColor
            cell.backgroundButton.setTitle(nil, for: .normal)
        }
    }
    
    private func updateSetups() {
        wordPoolCollectionView.dataSource = self
        wordPoolCollectionView.delegate = self
        wordPoolCollectionView.register(TmpCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    private func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(rowStack)
        view.addSubview(wordPoolCollectionView)
    }
    
    private func updateLayouts() {
        rowStack.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(300)
            make.width.equalToSuperview().multipliedBy(0.9)
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

extension TmpViewController2: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? TmpCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.backgroundButton.setTitle(words[indexPath.row], for: .normal)
        
        return cell
    }
    
}

extension TmpViewController2: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // https://stackoverflow.com/questions/23134986/dynamic-cell-width-of-uicollectionview-depending-on-label-width
        
        // TODO: - Wrap.
        let item = words[indexPath.row]
        let textSize = item.size(withAttributes: [
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: TmpViewController2.labelFontSize)
        ])
        
        let itemSize = CGSize(
            width: textSize.width + TmpViewController2.labelHorizontalPadding * 2,
            height: textSize.height + TmpViewController2.labelVerticalPadding * 2
        )
        
        return itemSize
        
    }
}

extension TmpViewController2 {
    
    private func updateCenterOf(view: UIView, to newCenter: CGPoint) {
        UIView.animate(withDuration: 0.3) {
            view.center = newCenter
        }
    }
    
}

extension TmpViewController2 {
    
    private func isInRowStack(_ view: UIView) -> Bool {
//        print("isInRowStack")
        return rowStack.frame.intersects(view.frame)
    }
    
    private func updateRowStack(_ view: UIView, translation: CGPoint) {
//        print("updateRowStack")
                
//        if indexOfDraggingButtonInRowStack != nil {
//            let maxX = view.frame.maxX
//            for indexOfFollowingWordButton in (indexOfDraggingButtonInRowStack! + 1)..<wordButtonsInRowStack.count {
//                let followingButton = wordButtonsInRowStack[indexOfFollowingWordButton]
//                if maxX > followingButton.frame.maxX && centerOfDraggingButtonInRowStack!.x < followingButton.frame.minx {
//
//                    centerOfDraggingButtonInRowStack = CGPoint(
//                        x: followingButton.frame.maxX - wordButtonsInRowStack[indexOfDraggingButtonInRowStack!].frame.width / 2,
//                        y: wordCentersInRowStack[indexOfDraggingButtonInRowStack!].y
//                    )
//
//                    wordCentersInRowStack[indexOfFollowingWordButton] = CGPoint(
//                        x: wordCentersInRowStack[indexOfFollowingWordButton].x - wordButtonsInRowStack[indexOfDraggingButtonInRowStack!].frame.width,
//                        y: wordCentersInRowStack[indexOfFollowingWordButton].y
//                    )
//                    updateCenterOf(view: followingButton, to: wordCentersInRowStack[indexOfFollowingWordButton])
//                }
//            }
//        }
        
        // ----------------
        
//        guard let oriIndexOfDraggingButton = indexOfDraggingButton else {
//            return
//        }
//
//        // Calculate the offset of the origin.
//        var horizontalOffset = view.frame.minX - rowStack.frame.minX
//        var verticalOffset = view.frame.minY - rowStack.frame.minY
//        if horizontalOffset < 0 {  // TODO: - necessary?
//            horizontalOffset = 0
//        }
//        if verticalOffset < 0 {  // TODO: - necessary?
//            verticalOffset = 0
//        }
//        let rowOffset = Int(verticalOffset / (TmpViewController2.rowHeight + TmpViewController2.rowStackSpacing))
//        let offset = horizontalOffset + CGFloat(rowOffset) * rowStack.frame.width
//        print("horizontalOffset: \(horizontalOffset), verticalOffset: \(verticalOffset), rowOffset: \(rowOffset), offset: \(offset)")
//
//        var swapIndex: Int = oriIndexOfDraggingButton
//        var summedX: CGFloat = {
//            var summedX: CGFloat = 0
//            for i in 0...oriIndexOfDraggingButton {
//                summedX += wordButtonsInRowStack[i].frame.maxX
//            }
//            return summedX
//        }()
//        print("summedX: \(summedX)")
//        for i in (oriIndexOfDraggingButton + 1)..<wordButtonsInRowStack.count {
//            let wordButton = wordButtonsInRowStack[i]
//            summedX += wordButton.frame.width
//            if summedX < offset {
//                swapIndex += 1
//            } else {
//                break
//            }
//        }
//        print("swapIndex: \(swapIndex), wordText: \((wordButtonsInRowStack[swapIndex] as! UIButton).titleLabel?.text)")
//        if oriIndexOfDraggingButton == swapIndex {
//            return
//        } else {
//            self.indexOfDraggingButton = swapIndex
//        }
//        wordButtonsInRowStack.swapAt(oriIndexOfDraggingButton, swapIndex)
////        wordCentersInRowStack.swapAt(oriIndexOfDraggingButton, swapIndex)
//
//        // Update the centers.
//        // TODO: - Wrap.
//        var centerX: CGFloat = rowStack.frame.minX
//        var centerY: CGFloat = rowStack.frame.minY + TmpViewController2.rowHeight / 2
//        var newWordCentersInRowStack: [CGPoint] = []  // TODO: - do not create a new arr.
//        for i in 0..<wordButtonsInRowStack.count {
//
//            let wordButton = wordButtonsInRowStack[i]
//
//            centerX += wordButton.frame.width / 2
//            if i - 1 >= 0 {
//                centerX += wordButtonsInRowStack[i - 1].frame.width / 2
//            }
//            if centerX + wordButton.frame.width / 2 > rowStack.frame.maxX {
//                centerX = rowStack.frame.minX + wordButton.frame.width / 2
//                centerY += TmpViewController2.rowHeight
//            }
//
//            newWordCentersInRowStack.append(CGPoint(
//                x: centerX,
//                y: centerY
//            ))
//        }
//        wordCentersInRowStack = newWordCentersInRowStack
//
//        for i in 0..<wordButtonsInRowStack.count {
//            print((wordButtonsInRowStack[i] as! UIButton).titleLabel!.text, wordCentersInRowStack[i], separator: ", ", terminator: " ")
//        }
//        print()
//
//        // Perform moving.
//        // TODO: - wrap.
//        for (wordButton, wordCenter) in zip(wordButtonsInRowStack, wordCentersInRowStack) {
//            if wordButton.tag != view.tag {
//                updateCenterOf(view: wordButton, to: wordCenter)
//            }
//        }
        
        
        // ----------------
        
//        print("######")
//        if indexOfDraggingButton == nil {
//            return
//        }
//        print("index before moving: \(indexOfDraggingButton)")
//        print("frame before moving: \(frameOfDraggingButton)")
//        print("-")
//
//        func handleRightAndDownMoves() {
//
//            // Calculate moving index.
//            let horizontalOffset: CGFloat = view.frame.minX - frameOfDraggingButton!.minX
////            print("horizontal offset: \(horizontalOffset)")
//            let verticalOffset: CGFloat = view.frame.minY - frameOfDraggingButton!.minY
//            let rowOffset: Int = Int(verticalOffset / (TmpViewController2.rowHeight + TmpViewController2.rowStackVerticalSpacing))
////            print("vertical offset: \(verticalOffset), row offset: \(rowOffset)")
//
//            var totalOffset: CGFloat = 0
//            if horizontalOffset > 0 {
//                totalOffset += horizontalOffset
//            }
//            if verticalOffset > 0 {
//                totalOffset += CGFloat(rowOffset) * rowStack.frame.width
//            }
//
////            let totalOffset: CGFloat = horizontalOffset + CGFloat(rowOffset) * rowStack.frame.width
////            print("total offset: \(totalOffset)")
////            print("-")
//
//            // Calculate the index to swap.
//            var summedOffset: CGFloat = 0
//            var newIndex: Int = indexOfDraggingButton!
//            for indexOfWordButton in (indexOfDraggingButton! + 1)..<wordButtonsInRowStack.count {
//
//                let wordButton = wordButtonsInRowStack[indexOfWordButton] as! UIButton
//                summedOffset += TmpViewController2.rowStackHorizontalSpacing + wordButton.frame.width
//
//                if summedOffset > totalOffset {
//                    break
//                }
//
//                newIndex += 1
////                print("  hit \(wordButton.titleLabel!.text), summed offset: \(summedOffset)",  terminator: "\n")
//            }
////            print()
////            print("old index: \(indexOfDraggingButton!), new index: \(newIndex)")
////            print("-")
//
//            if newIndex == indexOfDraggingButton {
//                return
//            } else {
////                print("old word buttons:", terminator: " ")
//                for wordButton in wordButtonsInRowStack {
//                    let wordButton = wordButton as! UIButton
////                    print(wordButton.titleLabel!.text!, terminator: ", ")
//                }
////                print()
//
//                let item = wordButtonsInRowStack.remove(at: indexOfDraggingButton!)
//                wordButtonsInRowStack.insert(item, at: newIndex)
//                indexOfDraggingButton = newIndex  // It's important to update the index.
//
////                print("new word buttons:", terminator: " ")
//                for wordButton in wordButtonsInRowStack {
//                    let wordButton = wordButton as! UIButton
////                    print(wordButton.titleLabel!.text!, terminator: ", ")
//                }
////                print()
//            }
//
//            updateCenters()
//
////            print("old frame: \(frameOfDraggingButton)", terminator: " ")
//            frameOfDraggingButton = wordButtonsInRowStack[indexOfDraggingButton!].frame
////            print("new frame: \(frameOfDraggingButton)")
//
//            // Perform moving.
//            for i in 0..<wordCentersInRowStack.count {
//                if wordButtonsInRowStack[i].tag != view.tag {
//                    updateCenterOf(view: wordButtonsInRowStack[i], to: wordCentersInRowStack[i])
//                }
//            }
//        }
//
//        func handleLeftAndUpMoves() {
//            // Calculate moving index.
//            let horizontalOffset: CGFloat = view.frame.minX - frameOfDraggingButton!.minX
//            print("horizontal offset: \(horizontalOffset)")
//            let verticalOffset: CGFloat = view.frame.minY - frameOfDraggingButton!.minY
//                - TmpViewController2.rowHeight
//            let rowOffset: Int = Int(verticalOffset / (TmpViewController2.rowHeight + TmpViewController2.rowStackVerticalSpacing))
//            print("vertical offset: \(verticalOffset), row offset: \(rowOffset)")
//
//            var totalOffset: CGFloat = 0
//            if horizontalOffset < 0 {
//                totalOffset += horizontalOffset
//            }
//            if verticalOffset < 0 {
//                totalOffset += CGFloat(rowOffset) * rowStack.frame.width
//            }
//
//            //            let totalOffset: CGFloat = horizontalOffset + CGFloat(rowOffset) * rowStack.frame.width
//            print("total offset: \(totalOffset)")
//            print("-")
//
//            // Calculate the index to swap.
//            var summedOffset: CGFloat = 0
//            var newIndex: Int = indexOfDraggingButton!
//            for indexOfWordButton in (0..<(indexOfDraggingButton!)).reversed() {
//
//                summedOffset -= TmpViewController2.rowStackHorizontalSpacing
//
//                if summedOffset < totalOffset {
//                    break
//                }
//                print("summed offset: \(summedOffset)")
//
//                newIndex -= 1
//
//                let wordButton = wordButtonsInRowStack[indexOfWordButton] as! UIButton
//                summedOffset -= wordButton.frame.width
//
//                print("  hit \(wordButton.titleLabel!.text)",  terminator: "\n")
//            }
//            print()
//            print("old index: \(indexOfDraggingButton!), new index: \(newIndex)")
//            print("-")
//
//            if newIndex == indexOfDraggingButton {
//                return
//            } else {
//                print("old word buttons:", terminator: " ")
//                for wordButton in wordButtonsInRowStack {
//                    let wordButton = wordButton as! UIButton
//                    print(wordButton.titleLabel!.text!, terminator: ", ")
//                }
//                print()
//
//                let item = wordButtonsInRowStack.remove(at: indexOfDraggingButton!)
//                wordButtonsInRowStack.insert(item, at: newIndex)
//                indexOfDraggingButton = newIndex
//
//                print("new word buttons:", terminator: " ")
//                for wordButton in wordButtonsInRowStack {
//                    let wordButton = wordButton as! UIButton
//                    print(wordButton.titleLabel!.text!, terminator: ", ")
//                }
//                print()
//            }
//
//            updateCenters()
//
//            print("old frame: \(frameOfDraggingButton)", terminator: " ")
//            frameOfDraggingButton = wordButtonsInRowStack[indexOfDraggingButton!].frame
//            print("new frame: \(frameOfDraggingButton)")
//
//            // Perform moving.
//            for i in (0..<wordCentersInRowStack.count).reversed() {
//                if wordButtonsInRowStack[i].tag != view.tag {
//                    updateCenterOf(view: wordButtonsInRowStack[i], to: wordCentersInRowStack[i])
//                }
//            }
//        }
//
//        handleRightAndDownMoves()
//        handleLeftAndUpMoves()
        
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
            if view.frame.intersects(nextButton.frame) {
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
                centerX += TmpViewController2.horizontalMargin + wordButtonsInRowStack[i - 1].frame.width / 2
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
//            print("addToRowStack")
            
            // Determine the center.
            var centerX: CGFloat = rowStack.frame.minX + view.frame.width / 2
            var centerY: CGFloat = rowStack.frame.minY + TmpViewController2.rowHeight / 2
            if let lastButton = wordButtonsInRowStack.last {
                
                centerX = TmpViewController2.horizontalMargin + lastButton.frame.maxX + view.frame.width / 2
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
//        print("moveToRowStack")
        if let indexOfButtonToMove = wordButtonsInRowStack.firstIndex(of: view) {
            updateCenterOf(view: view, to: wordCentersInRowStack[indexOfButtonToMove])
        }
    }
    
    private func removeFromRowStack(_ view: UIView) {

        if let buttonIndex = wordButtonsInRowStack.firstIndex(of: view) {
//            print("removeFromRowStack")
            
            // Remove the button.
            wordCentersInRowStack.remove(at: buttonIndex)
            wordButtonsInRowStack.remove(at: buttonIndex)
            
            // Update the centers.
//            if wordButtonsInRowStack.isEmpty {
//                return
//            }
//
//            var centerX: CGFloat = rowStack.frame.minX
//            var centerY: CGFloat = rowStack.frame.minY + TmpViewController2.rowHeight / 2
//            var newWordCentersInRowStack: [CGPoint] = []  // TODO: - do not create a new arr.
//            for i in 0..<wordButtonsInRowStack.count {
//
//                let wordButton = wordButtonsInRowStack[i]
//
//                centerX += wordButton.frame.width / 2
//                if i - 1 >= 0 {
//                    centerX += wordButtonsInRowStack[i - 1].frame.width / 2
//                }
//                if centerX + wordButton.frame.width / 2 > rowStack.frame.maxX {
//                    centerX = rowStack.frame.minX + wordButton.frame.width / 2
//                    centerY += TmpViewController2.rowHeight + TmpViewController2.rowStackSpacing
//                }
//
//                newWordCentersInRowStack.append(CGPoint(
//                    x: centerX,
//                    y: centerY
//                ))
//            }
//            wordCentersInRowStack = newWordCentersInRowStack
            
            // TODO: - Not needed to update if the remove button was the last.
            
            updateCenters()
        }
    }
    
    private func moveOutOfRowStack(_ view: UIView) {
//        print("moveOutOfRowStack")
        
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
//            print("began")
            self.view.bringSubviewToFront(draggingButton)
//            if let indexOfDraggingButton = wordButtonsInRowStack.firstIndex(of: draggingButton) {
//                self.indexOfDraggingButton = indexOfDraggingButton
//                self.frameOfDraggingButton = wordButtonsInRowStack[indexOfDraggingButton].frame
//            }
            drag()
        case .changed:
//            print("changed")
            drag()
        case .ended:
//            print("ended")
//            if indexOfDraggingButton != nil {
//                indexOfDraggingButton = nil
//                frameOfDraggingButton = nil
//            }
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
    
    static let labelFontSize: CGFloat = Sizes.mediumFontSize
    static let horizontalMargin: CGFloat = 3
    static let verticalMargin: CGFloat = 6
    static let labelHorizontalPadding: CGFloat = 6
    static let labelVerticalPadding: CGFloat = 6
    static let rowHeight = " ".size(withAttributes: [  // TODO: - Update
        NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: TmpViewController2.labelFontSize)
    ]).height + TmpViewController2.labelVerticalPadding * 2
    static let rowStackHorizontalSpacing: CGFloat = 3
    static let rowStackVerticalSpacing: CGFloat = 6
}
