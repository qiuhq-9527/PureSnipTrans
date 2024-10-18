//
//  TextProcessingManager.swift
//  test6
//
//  Created by qiuhq on 2024/10/15.
//

import Foundation
import NaturalLanguage
import Vision

class TextProcessingManager {
    
    static let shared = TextProcessingManager()
    
    private init() {}
    
    func processObservations(_ observations: [VNRecognizedTextObservation], in rect: NSRect) -> [ProcessedTextObservation] {
        return observations.compactMap { observation in
            guard let text = observation.topCandidates(1).first?.string else { return nil }
            let convertedRect = convertVisionRectToViewRect(observation.boundingBox, in: rect)
            return ProcessedTextObservation(boundingBox: convertedRect, text: text)
        }.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
    }
    
    private func convertVisionRectToViewRect(_ visionRect: CGRect, in selectionRect: NSRect) -> NSRect {
        let x = selectionRect.origin.x + visionRect.minX * selectionRect.width
        let y = selectionRect.origin.y + visionRect.minY * selectionRect.height
        let width = visionRect.width * selectionRect.width
        let height = visionRect.height * selectionRect.height
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    func filterAndPrintTexts(_ observations: [ProcessedTextObservation]) -> [String] {
        let fullText = observations.map { $0.text }.joined(separator: " ")
        print("合并后的文本: \"\(fullText)\"")
        
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = fullText
        
        var sentences: [String] = []
        tagger.enumerateTags(in: fullText.startIndex..<fullText.endIndex, unit: .sentence, scheme: .tokenType) { _, range in
            let sentence = String(fullText[range])
            if isMainlyEnglish(sentence) {
                print("识别出的英文句子: \"\(sentence)\"")
                sentences.append(sentence)
            }
            return true
        }
        
        return sentences
    }
    
    func isMainlyEnglish(_ text: String) -> Bool {
        let englishCharacters = text.filter { $0.isLetter && $0.isASCII }
        let nonSpaceCharacters = text.filter { !$0.isWhitespace }
        
        print("总非空白字符数: \(nonSpaceCharacters.count)")
        print("英文字母数: \(englishCharacters.count)")
        
        if englishCharacters.count > 0 && englishCharacters.count == text.filter({ $0.isLetter }).count {
            print("所有字母都是英文字母")
            return true
        }
        
        let englishRatio = Double(englishCharacters.count) / Double(nonSpaceCharacters.count)
        print("英文字母比例: \(englishRatio)")
        
        return englishRatio >= 0.75
    }
    
    func cleanText(_ text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var cleanedText = ""
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            let token = String(text[tokenRange])
            print("处理标记: \"\(token)\", 标签: \(tag?.rawValue ?? "无标签")")
            
            if let tag = tag {
                switch tag {
                case .noun, .verb, .adjective, .adverb, .pronoun, .determiner, .particle, .preposition, .conjunction:
                    cleanedText += token
                    print("保留标记: \(token)")
                case .number:
                    if token.contains(".") {
                        cleanedText += token
                        print("保留数字标记: \(token)")
                    } else {
                        print("过滤数字标记: \(token)")
                    }
                case .whitespace:
                    cleanedText += token
                    print("保留空白字符")
                default:
                    let cleaned = String(token.filter { $0.isLetter || $0.isNumber })
                    if !cleaned.isEmpty {
                        cleanedText += cleaned
                        print("部分保留标记: \(cleaned)")
                    } else {
                        print("完全过滤标记: \(token)")
                    }
                }
            } else {
                cleanedText += token
                print("保留无标签标记: \(token)")
            }
            
            return true
        }
        
        return cleanedText
    }
}

// 注释：考虑添加以下功能来增强TextProcessingManager的功能：
// 1. 添加一个方法来处理多语言文本，不仅限于英文
// 2. 实现一个缓存机制，以提高重复处理相同文本的效率
// 3. 添加更多的文本清理选项，如去除特殊字符、统一大小写等
// 4. 实现一个异步处理大量文本的方法，以提高性能
