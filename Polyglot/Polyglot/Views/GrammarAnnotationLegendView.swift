//
//  GrammarAnnotationLegendView.swift
//  Polyglot
//
//  Created by Ho on 7/26/26.
//  Copyright © 2026 Sola. All rights reserved.
//

import UIKit

// Reusable verb-aspect / noun-case color legend + attributed-string marking,
// factored out of TextMeaningPracticeView so SelectionPracticeView's prompt
// label can reuse the same coloring scheme.
class GrammarAnnotationLegendView: UIStackView {

    private lazy var impAspectLegendLabel: UILabel = Self.makeLegendLabel(color: .systemCyan, text: "imp.")
    private lazy var perfAspectLegendLabel: UILabel = Self.makeLegendLabel(color: .systemBlue, text: "p.")
    private lazy var biAspectLegendLabel: UILabel = Self.makeLegendLabel(color: .systemPurple, text: "bi.")
    private lazy var ambiguousAspectLegendLabel: UILabel = Self.makeLegendLabel(color: .systemGray, text: "?")

    private lazy var genCaseLegendLabel: UILabel = Self.makeLegendLabel(color: .systemMint, text: "gen.")
    private lazy var datCaseLegendLabel: UILabel = Self.makeLegendLabel(color: .systemOrange, text: "dat.")
    private lazy var instCaseLegendLabel: UILabel = Self.makeLegendLabel(color: UIColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0), text: "inst.")
    private lazy var prepCaseLegendLabel: UILabel = Self.makeLegendLabel(color: .brown, text: "prep.")
    private lazy var ambiguousCaseLegendLabel: UILabel = Self.makeLegendLabel(color: .systemGray, text: "?")

    private lazy var aspectLegendView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [impAspectLegendLabel, perfAspectLegendLabel, biAspectLegendLabel, ambiguousAspectLegendLabel])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()

    private lazy var nounCaseLegendView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            genCaseLegendLabel, datCaseLegendLabel, instCaseLegendLabel,
            prepCaseLegendLabel, ambiguousCaseLegendLabel
        ])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        axis = .vertical
        spacing = 4
        alignment = .center
        isHidden = true

        addArrangedSubview(nounCaseLegendView)
        addArrangedSubview(aspectLegendView)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeLegendLabel(color: UIColor, text: String) -> UILabel {
        let label = UILabel()
        let attrStr = NSMutableAttributedString()
        attrStr.append(NSAttributedString(string: "■ ", attributes: [
            .foregroundColor: color,
            .font: UIFont.systemFont(ofSize: Sizes.smallFontSize)
        ]))
        attrStr.append(NSAttributedString(string: text, attributes: [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: Sizes.smallFontSize)
        ]))
        label.attributedText = attrStr
        return label
    }

    private func updateVisibility() {
        isHidden = aspectLegendView.isHidden && nounCaseLegendView.isHidden
    }

    // Marks verb-aspect annotations directly on an attributed string (e.g., a prompt label's
    // text), mirroring TextMeaningPracticeView.markVerbAspects but without needing a UITextView.
    func markVerbAspects(in attrStr: NSMutableAttributedString, at annotations: [VerbAspectAnnotation]) {
        guard LangCode.currentLanguage.configs.shouldShowVerbAspectsInPractices else { return }

        var hasImp = false, hasPerf = false, hasBi = false, hasAmbiguous = false
        for annotation in annotations {
            let color: UIColor
            switch annotation.label {
            case "(imp.)": color = .systemCyan;   hasImp = true
            case "(p.)":   color = .systemBlue;   hasPerf = true
            case "(bi.)":  color = .systemPurple; hasBi = true
            case "(?)":    color = .systemGray;   hasAmbiguous = true
            default: continue
            }
            let range = NSRange(location: annotation.position, length: annotation.length)
            guard range.location + range.length <= attrStr.length else { continue }
            attrStr.addAttributes([.foregroundColor: color], range: range)
        }

        impAspectLegendLabel.isHidden = !hasImp
        perfAspectLegendLabel.isHidden = !hasPerf
        biAspectLegendLabel.isHidden = !hasBi
        ambiguousAspectLegendLabel.isHidden = !hasAmbiguous
        aspectLegendView.isHidden = !(hasImp || hasPerf || hasBi || hasAmbiguous)
        updateVisibility()
    }

    // Marks noun-case annotations directly on an attributed string, mirroring
    // TextMeaningPracticeView.markNounCases.
    func markNounCases(in attrStr: NSMutableAttributedString, at annotations: [NounCaseAnnotation]) {
        guard LangCode.currentLanguage.configs.shouldShowNounCasesInPractices else { return }

        let excludedWords: Set<String> = Set(
            LangCode.currentLanguage.configs.nounCasesExcludedWords
                .components(separatedBy: "\n")
                .map { $0.components(separatedBy: "#").first ?? "" }
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }
        )

        let text = attrStr.string as NSString

        var hasGen = false, hasDat = false, hasInst = false, hasPrep = false, hasAmbiguous = false
        for annotation in annotations {
            let range = NSRange(location: annotation.position, length: annotation.length)
            guard range.location + range.length <= attrStr.length else { continue }

            let tokenText = text.substring(with: range).lowercased()
            if excludedWords.contains(tokenText) { continue }

            var attrs: [NSAttributedString.Key: Any] = [:]

            if annotation.isItalic {
                attrs[.font] = UIFont.italicSystemFont(ofSize: Sizes.smallFontSize)
            }

            if annotation.label != "prep_motion" {
                let color: UIColor
                switch annotation.label {
                case "nom", "acc", "nom_acc":
                    if !annotation.isItalic { continue }
                    attrStr.addAttributes(attrs, range: range)
                    continue
                case "gen":       color = .systemMint;   hasGen = true
                case "dat":       color = .systemOrange; hasDat = true
                case "inst":      color = UIColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0); hasInst = true
                case "prep":      color = .brown;        hasPrep = true
                default:
                    if annotation.label.hasPrefix("ambiguous_") {
                        color = .systemGray; hasAmbiguous = true
                    } else {
                        continue
                    }
                }
                attrs[.foregroundColor] = color
            }

            attrStr.addAttributes(attrs, range: range)
        }

        genCaseLegendLabel.isHidden = !hasGen
        datCaseLegendLabel.isHidden = !hasDat
        instCaseLegendLabel.isHidden = !hasInst
        prepCaseLegendLabel.isHidden = !hasPrep
        ambiguousCaseLegendLabel.isHidden = !hasAmbiguous
        nounCaseLegendView.isHidden = !(hasGen || hasDat || hasInst || hasPrep || hasAmbiguous)
        updateVisibility()
    }

    func reset() {
        aspectLegendView.isHidden = true
        nounCaseLegendView.isHidden = true
        isHidden = true
    }
}
