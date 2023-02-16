//
//  WordBank.swift
//  Polyglot
//
//  Created by Sola on 2023/2/14.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class WordBank: UICollectionView {
    
    var words: [String]!
    
    // MARK: - Init
    
    convenience init(words: [String]) {
        self.init(
            frame: .zero,
            collectionViewLayout: {
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .vertical
                layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                layout.minimumInteritemSpacing = WordBank.minimumInteritemSpacing
                layout.minimumLineSpacing = WordBank.minimumLineSpacing
                return layout
            }()
        )
        self.words = words
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateSetups() {
        dataSource = self
        delegate = self
        register(WordBankItem.self, forCellWithReuseIdentifier: Identifiers.wordBankItemCellIdentifier)
    }
    
    private func updateViews() {
        backgroundColor = Colors.defaultBackgroundColor
    }
    
    private func updateLayouts() {
    }
}

extension WordBank: UICollectionViewDataSource {
    
    // MARK: - UICollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.wordBankItemCellIdentifier, for: indexPath) as? WordBankItem else {
            return UICollectionViewCell()
        }
        
        cell.label.text = words[indexPath.row]
        
        return cell
    }
    
}

extension WordBank: UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // https://stackoverflow.com/questions/23134986/dynamic-cell-width-of-uicollectionview-depending-on-label-width
        let text = words[indexPath.row]
        var textSize = text.textSize(withFont: WordBankItem.labelFont)
        if textSize.width < WordBank.minimumTextSizeWidth {
            textSize.width = WordBank.minimumTextSizeWidth
        }
        
        let itemSize = CGSize(
            width: WordBank.itemHorizontalPadding + textSize.width + WordBank.itemHorizontalPadding,
            height: WordBank.itemVerticalPadding + textSize.height + WordBank.itemVerticalPadding
        )
        
        return itemSize
    }
    
}

extension WordBank {
    
    // MARK: - Constants
    
    static let minimumInteritemSpacing: CGFloat = 6
    static let minimumLineSpacing: CGFloat = 6
    
    static let minimumTextSizeWidth: CGFloat = " ".textSize(withFont: WordBankItem.labelFont).width * 2
    static let itemHorizontalPadding: CGFloat = 6
    static let itemVerticalPadding: CGFloat = 6
    
}
