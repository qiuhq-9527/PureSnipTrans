//
//  OCRManager.swift
//  test6
//
//  Created by qiuhq on 2024/10/15.
//

import Foundation
import Vision
import Cocoa

class OCRManager {
    static let shared = OCRManager()
    
    private init() {}
    
    func performOCR(on image: NSImage, in rect: NSRect, completion: @escaping ([VNRecognizedTextObservation]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion([])
            return
        }
        
        let scale = CGFloat(cgImage.width) / image.size.width
        let cropRect = CGRect(x: rect.origin.x * scale,
                              y: (image.size.height - rect.origin.y - rect.height) * scale,
                              width: rect.width * scale,
                              height: rect.height * scale)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            completion([])
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: croppedCGImage, orientation: .up, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            completion(observations)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "ja-JP", "ko-KR"]
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("OCR失败: \(error)")
            completion([])
        }
    }
    
    func captureScreen(completion: @escaping (NSImage?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let screen = NSScreen.main else {
                completion(nil)
                return
            }
            
            let rect = screen.frame
            let captureRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
            
            if let cgImage = CGWindowListCreateImage(captureRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) {
                let nsImage = NSImage(cgImage: cgImage, size: rect.size)
                completion(nsImage)
            } else {
                completion(nil)
            }
        }
    }
}

// 注释：考虑添加以下功能来增强OCRManager的功能：
// 1. 添加对多种图像格式的支持，如JPEG、PNG等
// 2. 实现一个缓存机制，以提高重复处理相同图像的效率
// 3. 添加错误处理和日志记录功能，以便更好地诊断OCR过程中的问题
// 4. 实现一个异步处理大量图像的方法，以提高性能
// 5. 添加对OCR结果的后处理功能，如去除无意义的字符或合并相近的文本块
