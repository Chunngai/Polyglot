//
//  Separator.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class Separator: UIView {
    
    var color: UIColor!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, color: UIColor = Colors.separatorColor) {
        super.init(frame: frame)
        
        self.color = color
        
        updateViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func updateViews() {
        backgroundColor = color
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
        
        context.addPath(path)
        context.setStrokeColor(color.cgColor)
        context.strokePath()
    }
}
