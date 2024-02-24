//
//  NewWordAddingLayoutManager.swift
//  Polyglot
//
//  Created by Ho on 2/24/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation
import UIKit

// From https://github.com/rajdeep/proton

/// Shadow style for `backgroundStyle` attribute
public class ShadowStyle {

    /// Color of the shadow
    public let color: UIColor

    /// Shadow offset
    public let offset: CGSize

    /// Shadow blur
    public let blur: CGFloat

    public init(color: UIColor, offset: CGSize, blur: CGFloat) {
        self.color = color
        self.offset = offset
        self.blur = blur
    }
}

/// Border style for `backgroundStyle` attribute
public class BorderStyle {

    /// Color of border
    public let color: UIColor

    /// Width of the border
    public let lineWidth: CGFloat

    public init(lineWidth: CGFloat, color: UIColor) {
        self.lineWidth = lineWidth
        self.color = color
    }
}

/// Rounding style for  `backgroundStyle` attribute
public enum RoundedCornerStyle {
    /// Rounding based on an absolute value for corner radii
    case absolute(value: CGFloat)
    /// Rounding based on relative percent value of the content height. For e.g. 50% would provide a capsule appearance
    /// for shorter content.
    case relative(percent: CGFloat)

    public var isRelative: Bool {
        switch self {
        case .absolute:
            return false
        case .relative:
            return true
        }
    }
}

/// Defines the mode for height/width used for the background for the text
public enum BackgroundMode {
    /// Background matches the height/width of text with font leading padding all around
    case matchText
    /// Background matches the height of text based on font with minimal padding all around.
    case matchTextExact
    /// Background matches entire line irrespective of font height/used character width in the given line
    case matchLine
}

/// Style for background color attribute. Adding `backgroundStyle` attribute will add border, background and shadow
/// as per the styles specified.
/// - Important:
/// This attribute is separate from `backgroundColor` attribute. Applying `backgroundColor` takes precedence over backgroundStyle
/// i.e. the background color shows over color of `backgroundStyle` and will not show rounded corners.
/// - Note:
/// Ideally `backgroundStyle` may be used instead of `backgroundColor` as it can mimic standard background color as well as
/// border, shadow and rounded corners.
public class BackgroundStyle {

    /// Background color
    public let color: UIColor

    /// Rounding style for the background
    public let roundedCornerStyle: RoundedCornerStyle

    /// Optional border style for the background
    public let border: BorderStyle?

    /// Optional shadow style for the background
    public let shadow: ShadowStyle?

    /// Determines if the background has squared off joins at the point of wrapping of content.
    /// When set to `true`, the background will be squared off at inner/wrapping edges
    /// in case the background wraps across multiple lines. Defaults to `false`.
    /// - Note: This may be desirable to use in cases of short length content that is ideal to be shown as a single continued entity.
    /// When combined with `RoundedCornerStyle.relative` with a value of `50%`, it can help mimic appearance of a broken capsule
    /// when content wraps to next line.
    public let hasSquaredOffJoins: Bool

    /// Defines if the background should be drawn based on height of text range with style, or that of the height of line fragment containing
    /// styled text.
    public let heightMode: BackgroundMode

    /// Defines if the background should be drawn based on width of text range with style, or that of the entire width of line fragment containing
    /// styled text.
    public let widthMode: BackgroundMode

    /// Insets for drawn background. Defaults to `.zero`
    public let insets: UIEdgeInsets

    public init(color: UIColor,
                roundedCornerStyle: RoundedCornerStyle = .absolute(value: 0),
                border: BorderStyle? = nil,
                shadow: ShadowStyle? = nil,
                hasSquaredOffJoins: Bool = false,
                heightMode: BackgroundMode = .matchLine,
                widthMode: BackgroundMode = .matchLine,
                insets: UIEdgeInsets = .zero) {
        self.color = color
        self.roundedCornerStyle = roundedCornerStyle
        self.border = border
        self.shadow = shadow
        self.hasSquaredOffJoins = hasSquaredOffJoins
        self.heightMode = heightMode
        self.widthMode = widthMode
        self.insets = insets
    }
}

extension NSAttributedString.Key {
    static let viewOnly = NSAttributedString.Key("_viewOnly")

    static let isBlockAttachment = NSAttributedString.Key("_isBlockAttachment")
    static let isInlineAttachment = NSAttributedString.Key("_isInlineAttachment")
}

public extension NSAttributedString.Key {
    /// Applying this attribute makes the range of text act as a single block/unit.
    /// The content can still be deleted and selected but cursor cannot be moved into textBlock range
    /// using taps or mouse/keys (macOS Catalyst). Selection and delete on part of the range works atomically on the entire range.
    /// - Note: In successive ranges, if the `textblock` is provided with a value type with same value e.g. `true`, the behaviour
    /// will be combined for the ranges as one text block i.e. it will work as single textblock even though the attribute was added separately.
    /// However, if the value provided is different in successive ranges, these will work independent of each other even if one range
    /// immediately follows the other.
    static let textBlock = NSAttributedString.Key("_textBlock")

    /// Identifies block based attributes. A block acts as a container for other content types. For e.g. a Paragraph is a block content
    /// that contains Text as inline content. A block content may contain multiple inline contents of different types.
    /// This is utilized only when using `editor.contents(in:)` or `NSAttributedString.enumerateContents(in:)`.
    /// Both these utility functions allow breaking content in the editor into sub-parts that can be used to encode content.
    /// - SeeAlso:
    /// `EditorContentEncoder`
    /// `EditorView`
    static let blockContentType = NSAttributedString.Key("_blockContentType")

    /// Identifies inline content attributes. An inline acts as a content in another content types. For e.g. an emoji is an inline content
    /// that may be contained in a Paragraph along side another inline content of Text.
    /// This is utilized only when using  using `NSAttributedString.enumerateInlineContents(in:)`.
    /// This utility functions allow breaking content in a block based content string into sub-parts that can then be used to encode content.
    /// - SeeAlso:
    /// `EditorContentEncoder`
    /// `EditorView`
    static let inlineContentType = NSAttributedString.Key("_inlineContentType")

    /// Additional style attribute for background color. Using this attribute in addition to `backgroundColor` attribute allows applying
    /// shadow and corner radius to the background.
    /// - Note:
    /// This attribute only takes effect with `.backgroundColor`. In absence of `.backgroundColor`, this attribute has no effect.
    static let backgroundStyle = NSAttributedString.Key("_backgroundStyle")

    /// Attribute denoting the range as a list item. This attribute enables use of `ListTextProcessor` to indent/outdent list
    /// using tab/shift-tab (macOS) as well as create a new list item on hitting enter key.
    static let listItem = NSAttributedString.Key("_listItem")

    /// When applied to a new line char alongside `listItem` attribute, skips the rendering of list marker on subsequent line.
    static let skipNextListMarker = NSAttributedString.Key("_skipNextListMarker")

    /// Array of `NSAttributedString.Key` that must be locked in the applied range.
    /// - Note: This can be used to prevent atttributes from bleeding into the following text as content is typed in the editor. By default, any attribute from preceeding range
    /// is automatically carried forward via typing attributes in the `EditorView`. One or more attributes may be marked as locked to prevent the bleeding.
    /// - Example:  To prevent `.backgroundStyle` attribute, following may be used:
    /// `let backgroundStyle = BackgroundStyle(color: .green)`
    /// `editor.addAttributes([`
    /// `.backgroundStyle: backgroundStyle,`
    /// `.lockedAttributes: [NSAttributedString.Key.backgroundStyle]`
    /// `], at: editor.selectedRange)`
    static let lockedAttributes = NSAttributedString.Key("_lockedAttributes")


    static let asyncTextResolver = NSAttributedString.Key("_asyncTextResolver")
}

protocol LayoutManagerDelegate: AnyObject {
//    var typingAttributes: [NSAttributedString.Key: Any] { get }
//    var selectedRange: NSRange { get }
    var paragraphStyle: NSMutableParagraphStyle? { get }
    var font: UIFont? { get }
//    var textColor: UIColor? { get }
//    var textContainerInset: UIEdgeInsets { get }
//
//    var listLineFormatting: LineFormatting { get }
//    
//    var isLineNumbersEnabled: Bool { get }
//    var lineNumberFormatting: LineNumberFormatting { get }
//    var lineNumberWrappingMarker: String? { get }
//
//    func listMarkerForItem(at index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker
//    func lineNumberString(for index: Int) -> String?
}

class LayoutManager: NSLayoutManager {

//    private let defaultBulletColor = UIColor.black
//    private var counters = [Int: Int]()
//
    weak var layoutManagerDelegate: LayoutManagerDelegate?
//
//    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
//        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
//        guard let textStorage = self.textStorage else { return }
//
//        textStorage.enumerateAttribute(.listItem, in: textStorage.fullRange, options: []) { (value, range, _) in
//            if value != nil {
//                drawListMarkers(textStorage: textStorage, listRange: range, attributeValue: value)
//            }
//        }
//    }
//
    var defaultParagraphStyle: NSParagraphStyle {
        return layoutManagerDelegate?.paragraphStyle ?? NSParagraphStyle()
    }

    var defaultFont: UIFont {
        return layoutManagerDelegate?.font ?? UIFont.preferredFont(forTextStyle: .body)
    }
//
//    private func drawListMarkers(textStorage: NSTextStorage, listRange: NSRange, attributeValue: Any?) {
//        var lastLayoutRect: CGRect?
//        var lastLayoutParaStyle: NSParagraphStyle?
//        var lastLayoutFont: UIFont?
//
//        var previousLevel = 0
//        var level = 0
//
//        let defaultFont = self.layoutManagerDelegate?.font ?? UIFont.preferredFont(forTextStyle: .body)
//        let listIndent = layoutManagerDelegate?.listLineFormatting.indentation ?? 25.0
//
//        var prevStyle: NSParagraphStyle?
//
//        if listRange.location > 0,
//           textStorage.attribute(.listItem, at: listRange.location - 1, effectiveRange: nil) != nil {
//            prevStyle = textStorage.attribute(.paragraphStyle, at: listRange.location - 1, effectiveRange: nil) as? NSParagraphStyle
//        }
//
//        if prevStyle == nil {
//            counters = [:]
//        }
//
//        var levelToSet = 0
//        textStorage.enumerateAttribute(.paragraphStyle, in: listRange, options: []) { value, range, _ in
//            levelToSet = 0
//            if let paraStyle = (value as? NSParagraphStyle)?.mutableParagraphStyle {
//                let previousLevel = Int(prevStyle?.firstLineHeadIndent ?? 0)/Int(listIndent)
//                let currentLevel = Int(paraStyle.firstLineHeadIndent)/Int(listIndent)
//
//                if currentLevel - previousLevel > 1 {
//                    levelToSet = previousLevel + 1
//                    let indentation = CGFloat(levelToSet) * listIndent
//                    paraStyle.firstLineHeadIndent = indentation
//                    paraStyle.headIndent = indentation
//                    textStorage.addAttribute(.paragraphStyle, value: paraStyle, range: range)
//                    prevStyle = paraStyle
//                } else {
//                    prevStyle = value as? NSParagraphStyle
//                }
//            }
//        }
//
//        let listGlyphRange = glyphRange(forCharacterRange: listRange, actualCharacterRange: nil)
//        previousLevel = 0
//        enumerateLineFragments(forGlyphRange: listGlyphRange) { [weak self] (rect, usedRect, textContainer, glyphRange, stop) in
//            guard let self = self else { return }
//            let characterRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
//
//            var newLineRange = NSRange.zero
//            if characterRange.location > 0 {
//                newLineRange.location = characterRange.location - 1
//                newLineRange.length = 1
//            }
//
//            // Determines if previous line is completed i.e. terminates with a newline char. Absence of newline character means that the
//            // line is wrapping and rendering the number/bullet should be skipped.
//            var isPreviousLineComplete = true
//            var skipMarker = false
//
//            if newLineRange.length > 0 {
//                let newLineString = textStorage.substring(from: newLineRange)
//                isPreviousLineComplete = newLineString == "\n"
//                skipMarker = textStorage.attribute(.skipNextListMarker, at: newLineRange.location, effectiveRange: nil) != nil
//            }
//
//            let font = textStorage.attribute(.font, at: characterRange.location, effectiveRange: nil) as? UIFont ?? defaultFont
//            let previousParaStyle: NSParagraphStyle?
//
//            if characterRange.location == 0 {
//                previousParaStyle = nil
//            } else {
//                previousParaStyle  = textStorage.attribute(.paragraphStyle, at: max(characterRange.location - 1, 0), effectiveRange: nil) as? NSParagraphStyle
//            }
//
//            let paraStyle = textStorage.attribute(.paragraphStyle, at: characterRange.location, effectiveRange: nil) as? NSParagraphStyle ?? self.defaultParagraphStyle
//            previousLevel = Int(previousParaStyle?.firstLineHeadIndent ?? 0)/Int(listIndent)
//            if isPreviousLineComplete, skipMarker == false {
//
//                level = Int(paraStyle.firstLineHeadIndent/listIndent)
//                var index = (self.counters[level] ?? 0)
//                self.counters[level] = index + 1
//
//                // reset index counter for level when list indentation (level) changes.
//                if level > previousLevel, level > 1 {
//                    index = 0
//                    self.counters[level] = 1
//                }
//
//                var adjustedRect = rect
//                // Account for height of line fragment based on styles defined in paragraph, like paragraphSpacing
//                adjustedRect.size.height = usedRect.height
//                if level > 0 {
//                    self.drawListItem(level: level, previousLevel: previousLevel, index: index, rect: adjustedRect, paraStyle: paraStyle, font: font, attributeValue: attributeValue)
//                }
//
//                // TODO: should this be moved inside level > 0 check above?
//            }
//            lastLayoutParaStyle = paraStyle
//            lastLayoutRect = rect
//            lastLayoutFont = font
//            previousLevel = level
//        }
//
//        var skipMarker = false
//
//        if textStorage.length > 0 {
//            let range = NSRange(location: textStorage.length - 1, length: 1)
//            let lastChar = textStorage.substring(from: range)
//            skipMarker = lastChar == "\n" && textStorage.attribute(.skipNextListMarker, at: range.location, effectiveRange: nil) != nil
//        }
//
//        guard skipMarker == false,
//              let lastRect = lastLayoutRect,
//              textStorage.length > 1,
//              textStorage.substring(from: NSRange(location: listRange.endLocation - 1, length: 1)) == "\n",
//              let paraStyle = lastLayoutParaStyle
//        else { return }
//
//        var index = (counters[level] ?? 0)
//        let origin = CGPoint(x: lastRect.minX, y: lastRect.maxY)
//
//        var para: NSParagraphStyle?
//        if textStorage.length > listRange.endLocation {
//            para = textStorage.attribute(.paragraphStyle, at: listRange.endLocation, effectiveRange: nil) as? NSParagraphStyle
//            let paraLevel = Int((para?.firstLineHeadIndent ?? 0)/listIndent)
//            // don't draw last rect if there's a following list item (in another indent level)
//            if para != nil, paraLevel != level {
//                return
//            }
//        }
//
//        let newLineRect = CGRect(origin: origin, size: lastRect.size)
//
//        if level > previousLevel, level > 1 {
//            index = 0
//            counters[level] = 1
//        }
//        previousLevel = level
//
//        let font = lastLayoutFont ?? defaultFont
//        drawListItem(level: level, previousLevel: previousLevel, index: index, rect: newLineRect.integral, paraStyle: paraStyle, font: font, attributeValue: attributeValue)
//    }
//
//    private func drawListItem(level: Int, previousLevel: Int, index: Int, rect: CGRect, paraStyle: NSParagraphStyle, font: UIFont, attributeValue: Any?) {
//        guard level > 0 else { return }
//
//        let color = layoutManagerDelegate?.textColor ?? self.defaultBulletColor
//        color.set()
//
//        let marker = layoutManagerDelegate?.listMarkerForItem(at: index, level: level, previousLevel: previousLevel, attributeValue: attributeValue) ?? .string(NSAttributedString(string: "*"))
//
//        let listMarkerImage: UIImage
//        let markerRect: CGRect
////        let topInset = layoutManagerDelegate?.textContainerInset.top ?? 0
//        switch marker {
//        case let .string(text):
//            let markerSize = text.boundingRect(with: CGSize(width: paraStyle.firstLineHeadIndent, height: rect.height), options: [], context: nil).size
//            markerRect = rectForNumberedList(markerSize: markerSize, rect: rect, indent: paraStyle.firstLineHeadIndent, yOffset: paraStyle.paragraphSpacingBefore)
//            listMarkerImage = self.generateBitmap(string: text, rect: markerRect)
//        case let .image(image, size):
//            markerRect = rectForBullet(markerSize: size, rect: rect, indent: paraStyle.firstLineHeadIndent, yOffset: paraStyle.paragraphSpacingBefore)
//            listMarkerImage = image.resizeImage(to: markerRect.size)
//        }
//
////        let lineSpacing = paraStyle.lineSpacing
//        let lineHeightMultiple = max(paraStyle.lineHeightMultiple, 1)
//        let lineHeightMultipleOffset = (rect.size.height - rect.size.height/lineHeightMultiple)
//        listMarkerImage.draw(at: markerRect.offsetBy(dx: 0, dy: lineHeightMultipleOffset).origin)
//    }
//
//    private func generateBitmap(string: NSAttributedString, rect: CGRect) -> UIImage {
//        let renderer = UIGraphicsImageRenderer(size: rect.size)
//        let image = renderer.image { context in
//            string.draw(at: .zero)
//        }
//        return image
//    }
//
//    private func rectForBullet(markerSize: CGSize, rect: CGRect, indent: CGFloat, yOffset: CGFloat) -> CGRect {
//        let topInset = layoutManagerDelegate?.textContainerInset.top ?? 0
//        let leftInset = layoutManagerDelegate?.textContainerInset.left ?? 0
//        let spacerRect = CGRect(origin: CGPoint(x: rect.minX + leftInset, y: rect.minY + topInset), size: CGSize(width: indent, height: rect.height))
//        let scaleFactor = markerSize.height / spacerRect.height
//        var markerSizeToUse = markerSize
//        // Resize maintaining aspect ratio if bullet height is more than available line height
//        if scaleFactor > 1 {
//            markerSizeToUse = CGSize(width: markerSize.width/scaleFactor, height: markerSize.height/scaleFactor)
//        }
//
//        let stringRect = CGRect(origin: CGPoint(x: spacerRect.maxX - markerSizeToUse.width, y: spacerRect.midY - markerSizeToUse.height/2), size: markerSizeToUse)
//        return stringRect
//    }
//
//    private func rectForNumberedList(markerSize: CGSize, rect: CGRect, indent: CGFloat, yOffset: CGFloat) -> CGRect {
//        let topInset = layoutManagerDelegate?.textContainerInset.top ?? 0
//        let leftInset = layoutManagerDelegate?.textContainerInset.left ?? 0
//        let spacerRect = CGRect(origin: CGPoint(x: rect.minX + leftInset, y: rect.minY + topInset), size: CGSize(width: indent, height: rect.height))
//
//        let scaleFactor = markerSize.height / spacerRect.height
//        var markerSizeToUse = markerSize
//        // Resize maintaining aspect ratio if bullet height is more than available line height
//        if scaleFactor > 1 {
//            markerSizeToUse = CGSize(width: markerSize.width/scaleFactor, height: markerSize.height/scaleFactor)
//        }
//
//        let stringRect = CGRect(origin: CGPoint(x: spacerRect.maxX - markerSizeToUse.width, y: spacerRect.minY + yOffset), size: markerSizeToUse)
//
//        return stringRect
//    }
//
//    private func rectForLineNumbers(markerSize: CGSize, rect: CGRect, width: CGFloat) -> CGRect {
//        let topInset = layoutManagerDelegate?.textContainerInset.top ?? 0
//        let spacerRect = CGRect(origin: CGPoint(x: 0, y: topInset), size: CGSize(width: width, height: rect.height))
//
//        let scaleFactor = markerSize.height / spacerRect.height
//        var markerSizeToUse = markerSize
//        // Resize maintaining aspect ratio if bullet height is more than available line height
//        if scaleFactor > 1 {
//            markerSizeToUse = CGSize(width: markerSize.width/scaleFactor, height: markerSize.height/scaleFactor)
//        }
//
//        let trailingPadding: CGFloat = 2
//        let yPos = topInset + rect.minY
//        let stringRect = CGRect(origin: CGPoint(x: spacerRect.maxX - markerSizeToUse.width - trailingPadding, y: yPos), size: markerSizeToUse)
//
//        //        debugRect(rect: spacerRect, color: .blue)
//        //        debugRect(rect: stringRect, color: .red)
//
//        return stringRect
//    }
//
//    override func drawsOutsideLineFragment(forGlyphAt glyphIndex: Int) -> Bool {
//        true
//    }
//
//    var hasLineSpacing: Bool {
//        var lineCount = 0
//        guard let textStorage else { return false}
//        enumerateLineFragments(forGlyphRange: textStorage.fullRange, using: { _, _, _, _, stop in
//            lineCount += 1
//            if lineCount > 1 {
//                stop.pointee = true
//            }
//        })
//        return lineCount > 1 || (lineCount > 0 && extraLineFragmentRect.height > 0)
//    }
//
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage = textStorage,
              let currentCGContext = UIGraphicsGetCurrentContext()
        else { return }
        currentCGContext.saveGState()

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(.backgroundStyle, in: characterRange) { attr, bgStyleRange, _ in
            var rects = [CGRect]()
            if let backgroundStyle = attr as? BackgroundStyle {
                let bgStyleGlyphRange = self.glyphRange(forCharacterRange: bgStyleRange, actualCharacterRange: nil)
                enumerateLineFragments(forGlyphRange: bgStyleGlyphRange) { rect1, usedRect, textContainer, lineRange, _ in
                    let rangeIntersection = NSIntersectionRange(bgStyleGlyphRange, lineRange)
                    let paragraphStyle = textStorage.attribute(.paragraphStyle, at: rangeIntersection.location, effectiveRange: nil) as? NSParagraphStyle ?? self.defaultParagraphStyle
                    let font = textStorage.attribute(.font, at: rangeIntersection.location, effectiveRange: nil) as? UIFont ?? self.defaultFont
                    let lineHeightMultiple = max(paragraphStyle.lineHeightMultiple, 1)
                    var rect = self.boundingRect(forGlyphRange: rangeIntersection, in: textContainer)
                    let lineHeightMultipleOffset = (rect.size.height - rect.size.height/lineHeightMultiple)
                    let lineSpacing = paragraphStyle.lineSpacing
                    if backgroundStyle.widthMode == .matchText {
                        let content = textStorage.attributedSubstring(from: rangeIntersection)
                        let contentWidth = content.boundingRect(with: rect.size, options: [.usesDeviceMetrics, .usesFontLeading], context: nil).width
                            rect.size.width = contentWidth
                    }

                    switch backgroundStyle.heightMode {
                    case .matchTextExact:
                        let styledText = textStorage.attributedSubstring(from: bgStyleGlyphRange)
                        var textRect = styledText.boundingRect(with: rect.size, options: [.usesFontLeading, .usesDeviceMetrics], context: nil)
                        textRect.origin = rect.origin
                        textRect.size.width = rect.width

                        textRect.origin.y += abs(font.descender)

                        let delta = usedRect.height - (font.lineHeight + font.leading)
                        textRect.origin.y += delta
                        let hasLineSpacing = (usedRect.height - font.lineHeight) == paragraphStyle.lineSpacing
                        let isExtraLineHeight = ((usedRect.height - font.lineHeight) - font.leading) > 0.001

                        if hasLineSpacing || isExtraLineHeight {
                            textRect.origin.y -= (paragraphStyle.lineSpacing - font.leading)
                        }

                        rect = textRect
                    case .matchText:
                        let styledText = textStorage.attributedSubstring(from: bgStyleGlyphRange)
                        let textRect = styledText.boundingRect(with: rect.size, options: .usesFontLeading, context: nil)

                        rect.origin.y = usedRect.origin.y + (rect.size.height - textRect.height) + lineHeightMultipleOffset - lineSpacing
                        rect.size.height = textRect.height - lineHeightMultipleOffset
                    case .matchLine:
                        // Glyphs can take space outside of the line fragment, and we cannot draw outside of it.
                        // So it is best to restrict the height just to the line fragment.
                        rect.origin.y = usedRect.origin.y
                        rect.size.height = usedRect.height
                    }

//                    if lineRange.endLocation == textStorage.length, font.leading == 0 {
//                        rect.origin.y += abs(font.descender/2)
//                    }
                    rects.append(rect.offsetBy(dx: origin.x, dy: origin.y))
                }
                drawBackground(backgroundStyle: backgroundStyle, rects: rects, currentCGContext: currentCGContext)
            }
        }
//        drawLineNumbers(textStorage: textStorage, currentCGContext: currentCGContext)
        currentCGContext.restoreGState()
    }
//
//    private func drawLineNumbers(textStorage: NSTextStorage, currentCGContext: CGContext) {
//        var lineNumber = 1
//        guard layoutManagerDelegate?.isLineNumbersEnabled == true,
//              let lineNumberFormatting = layoutManagerDelegate?.lineNumberFormatting else { return }
//
//        let lineNumberWrappingMarker = layoutManagerDelegate?.lineNumberWrappingMarker
//        enumerateLineFragments(forGlyphRange: textStorage.fullRange) { [weak self] rect, usedRect, _, range, _ in
//            guard let self else { return }
//            let paraRange = self.textStorage?.mutableString.paragraphRange(for: range).firstCharacterRange
//            let lineNumberToDisplay = layoutManagerDelegate?.lineNumberString(for: lineNumber) ?? "\(lineNumber)"
//
//            if range.location == paraRange?.location {
//                self.drawLineNumber(lineNumber: lineNumberToDisplay, rect: rect.integral, lineNumberFormatting: lineNumberFormatting, currentCGContext: currentCGContext)
//                lineNumber += 1
//            } else if let lineNumberWrappingMarker {
//                self.drawLineNumber(lineNumber: lineNumberWrappingMarker, rect: rect.integral, lineNumberFormatting: lineNumberFormatting, currentCGContext: currentCGContext)
//            }
//        }
//
//        // Draw line number for additional new line with \n, if exists
//        drawLineNumber(lineNumber: "\(lineNumber)", rect: extraLineFragmentRect.integral, lineNumberFormatting: lineNumberFormatting, currentCGContext: currentCGContext)
//    }
//    
//    func drawLineNumber(lineNumber: String, rect: CGRect, lineNumberFormatting: LineNumberFormatting, currentCGContext: CGContext) {
//        let gutterWidth = lineNumberFormatting.gutter.width
//        let attributes = lineNumberAttributes(lineNumberFormatting: lineNumberFormatting)
//        let text = NSAttributedString(string: "\(lineNumber)", attributes: attributes)
//        let markerSize = text.boundingRect(with: .zero, options: [], context: nil).integral.size
//        var markerRect = self.rectForLineNumbers(markerSize: markerSize, rect: rect, width: gutterWidth)
//        let listMarkerImage = self.generateBitmap(string: text, rect: markerRect)
//        listMarkerImage.draw(at: markerRect.origin)
//    }
//
//    private func lineNumberAttributes(lineNumberFormatting: LineNumberFormatting) -> [NSAttributedString.Key: Any] {
//        let font = lineNumberFormatting.font
//        let textColor = lineNumberFormatting.textColor
//        let paraStyle = NSMutableParagraphStyle()
//        paraStyle.alignment = .right
//
//        return [
//            NSAttributedString.Key.font: font,
//            NSAttributedString.Key.foregroundColor: textColor,
//            NSAttributedString.Key.paragraphStyle: paraStyle
//        ]
//    }
//
    private func drawBackground(backgroundStyle: BackgroundStyle, rects: [CGRect], currentCGContext: CGContext) {
        currentCGContext.saveGState()

        let rectCount = rects.count
        let rectArray = rects

        let color = backgroundStyle.color

        for i in 0..<rectCount {
            var previousRect = CGRect.zero
            var nextRect = CGRect.zero

            let currentRect = rectArray[i].insetIfRequired(by: backgroundStyle.insets)

            if currentRect.isEmpty {
                continue
            }

            let cornerRadius: CGFloat

            switch backgroundStyle.roundedCornerStyle {
            case let .absolute(value):
                cornerRadius = value
            case let .relative(percent):
                cornerRadius = currentRect.height * (percent/100.0)
            }

            if i > 0 {
                previousRect = rectArray[i - 1].insetIfRequired(by: backgroundStyle.insets)
            }

            if i < rectCount - 1 {
                nextRect = rectArray[i + 1].insetIfRequired(by: backgroundStyle.insets)
            }

            let corners: UIRectCorner
            if backgroundStyle.hasSquaredOffJoins {
                corners = calculateCornersForSquaredOffJoins(previousRect: previousRect, currentRect: currentRect, nextRect: nextRect, cornerRadius: cornerRadius)
            } else {
               corners = calculateCornersForBackground(previousRect: previousRect, currentRect: currentRect, nextRect: nextRect, cornerRadius: cornerRadius)
            }

            let rectanglePath = UIBezierPath(roundedRect: currentRect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            color.set()

            currentCGContext.setAllowsAntialiasing(true)
            currentCGContext.setShouldAntialias(true)

            if let shadowStyle = backgroundStyle.shadow {
                currentCGContext.setShadow(offset: shadowStyle.offset, blur: shadowStyle.blur, color: shadowStyle.color.cgColor)
            }

            currentCGContext.setFillColor(color.cgColor)
            currentCGContext.addPath(rectanglePath.cgPath)
            currentCGContext.drawPath(using: .fill)

            let lineWidth = backgroundStyle.border?.lineWidth ?? 0
            let overlappingLine = UIBezierPath()

            // TODO: Revisit shadow drawing logic to simplify a bit

            let leftVerticalJoiningLine = UIBezierPath()
            let rightVerticalJoiningLine = UIBezierPath()
            // Shadow for vertical lines need to be drawn separately to get the perfect alignment with shadow on rectangles.
            let leftVerticalJoiningLineShadow = UIBezierPath()
            let rightVerticalJoiningLineShadow = UIBezierPath()
            var lineLength: CGFloat = 0

            if backgroundStyle.heightMode != .matchTextExact,
                !previousRect.isEmpty, (currentRect.maxX - previousRect.minX) > cornerRadius {
                let yDiff = currentRect.minY - previousRect.maxY
                var overLapMinX = max(previousRect.minX, currentRect.minX) + lineWidth/2
                var overlapMaxX = min(previousRect.maxX, currentRect.maxX) - lineWidth/2
                lineLength = overlapMaxX - overLapMinX

                // Adjust overlap line length if the rounding on current and previous overlaps
                // accounting for relative rounding as it rounds at both top and bottom vs. fixed which rounds
                // only at top when in an overlap
                if (currentRect.maxX - previousRect.minX <= cornerRadius)
                    || (previousRect.minX - currentRect.maxX <= cornerRadius) && backgroundStyle.roundedCornerStyle.isRelative  {
                    overLapMinX += cornerRadius
                    overlapMaxX -= cornerRadius
                }

                overlappingLine.move(to: CGPoint(x: overLapMinX , y: previousRect.maxY + yDiff/2))
                overlappingLine.addLine(to: CGPoint(x: overlapMaxX, y: previousRect.maxY + yDiff/2))

                let leftX = max(previousRect.minX, currentRect.minX)
                let rightX = min(previousRect.maxX, currentRect.maxX)

                leftVerticalJoiningLine.move(to: CGPoint(x: leftX, y: previousRect.maxY))
                leftVerticalJoiningLine.addLine(to: CGPoint(x: leftX, y: currentRect.minY))

                rightVerticalJoiningLine.move(to: CGPoint(x: rightX, y: previousRect.maxY))
                rightVerticalJoiningLine.addLine(to: CGPoint(x: rightX, y: currentRect.minY))

                let leftShadowX = max(previousRect.minX, currentRect.minX) + lineWidth
                let rightShadowX = min(previousRect.maxX, currentRect.maxX) - lineWidth

                leftVerticalJoiningLineShadow.move(to: CGPoint(x: leftShadowX, y: previousRect.maxY))
                leftVerticalJoiningLineShadow.addLine(to: CGPoint(x: leftShadowX, y: currentRect.minY))

                rightVerticalJoiningLineShadow.move(to: CGPoint(x: rightShadowX, y: previousRect.maxY))
                rightVerticalJoiningLineShadow.addLine(to: CGPoint(x: rightShadowX, y: currentRect.minY))
            }

            if let borderColor = backgroundStyle.border?.color {
                currentCGContext.setLineWidth(lineWidth * 2)
                currentCGContext.setStrokeColor(borderColor.cgColor)

                // always draw vertical joining lines
                currentCGContext.addPath(leftVerticalJoiningLineShadow.cgPath)
                currentCGContext.addPath(rightVerticalJoiningLineShadow.cgPath)

                currentCGContext.drawPath(using: .stroke)
            }

            currentCGContext.setShadow(offset: .zero, blur:0, color: UIColor.clear.cgColor)

            if !currentRect.isEmpty,
                let borderColor = backgroundStyle.border?.color {
                currentCGContext.setLineWidth(lineWidth)
                currentCGContext.setStrokeColor(borderColor.cgColor)
                currentCGContext.addPath(rectanglePath.cgPath)

                // always draw vertical joining lines
                currentCGContext.addPath(leftVerticalJoiningLine.cgPath)
                currentCGContext.addPath(rightVerticalJoiningLine.cgPath)

                currentCGContext.drawPath(using: .stroke)
            }

            // draw over the overlapping bounds of previous and next rect to hide shadow/borders
            // if the border color is defined and different from background
            // Also, account for rounding so that the overlap line does not eat into rounding lines
            if let borderColor = backgroundStyle.border?.color,
               lineLength > (cornerRadius * 2),
                color != borderColor {
                currentCGContext.setStrokeColor(color.cgColor)
                currentCGContext.addPath(overlappingLine.cgPath)
            }
            // account for the spread of shadow
            let blur = (backgroundStyle.shadow?.blur ?? 1) * 2
            let offsetHeight = abs(backgroundStyle.shadow?.offset.height ?? 1)
            currentCGContext.setLineWidth(lineWidth + (currentRect.minY - previousRect.maxY) + blur + offsetHeight + 1)
            currentCGContext.drawPath(using: .stroke)
        }
        currentCGContext.restoreGState()
    }
//
    private func calculateCornersForSquaredOffJoins(previousRect: CGRect, currentRect: CGRect, nextRect: CGRect, cornerRadius: CGFloat) -> UIRectCorner {
        var corners = UIRectCorner()

        let isFirst = previousRect.isEmpty  && !currentRect.isEmpty
        let isLast = nextRect.isEmpty && !currentRect.isEmpty

        if isFirst {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
        }

        if isLast {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomRight)
        }

        return corners
    }
//
    private func calculateCornersForBackground(previousRect: CGRect, currentRect: CGRect, nextRect: CGRect, cornerRadius: CGFloat) -> UIRectCorner {
        var corners = UIRectCorner()

        if previousRect.minX > currentRect.minX {
            corners.formUnion(.topLeft)
        }

        if previousRect.maxX < currentRect.maxX {
            corners.formUnion(.topRight)
        }

        if currentRect.maxX > nextRect.maxX {
            corners.formUnion(.bottomRight)
        }

        if currentRect.minX < nextRect.minX {
            corners.formUnion(.bottomLeft)
        }

        if nextRect.isEmpty || nextRect.maxX <= currentRect.minX + cornerRadius {
            corners.formUnion(.bottomLeft)
            corners.formUnion(.bottomRight)
        }

        if previousRect.isEmpty || (currentRect.maxX <= previousRect.minX + cornerRadius) {
            corners.formUnion(.topLeft)
            corners.formUnion(.topRight)
        }

        return corners
    }
//
//    // Helper function to debug rectangles by drawing in context
//    private func debugRect(rect: CGRect, color: UIColor) {
//        let path = UIBezierPath(rect: rect).cgPath
//        debugPath(path: path, color: color)
//    }
//
//    // Helper function to debug Bezier Path by drawing in context
//    private func debugPath(path: CGPath, color: UIColor) {
//        let currentCGContext = UIGraphicsGetCurrentContext()
//        currentCGContext?.saveGState()
//
//        currentCGContext?.setStrokeColor(color.cgColor)
//        currentCGContext?.addPath(path)
//        currentCGContext?.drawPath(using: .stroke)
//
//        currentCGContext?.restoreGState()
//    }
}

extension CGRect {
    func insetIfRequired(by insets: UIEdgeInsets) -> CGRect {
        return isEmpty ? self : inset(by: insets)
    }
}
//
//extension UIImage {
//    func resizeImage(to size: CGSize) -> UIImage {
//        let renderer = UIGraphicsImageRenderer(
//            size: size
//        )
//
//        let scaledImage = renderer.image { _ in
//            self.draw(in: CGRect(
//                origin: .zero,
//                size: size
//            ))
//        }
//
//        return scaledImage
//    }
//}
//
//extension CGFloat {
//    func isBetween(_ first: CGFloat, _ second: CGFloat) -> Bool {
//        return self > first && self < second
//    }
//}
