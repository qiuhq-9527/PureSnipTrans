//
//  TranslationOverlayView.swift
//  test6
//
//  Created by qiuhq on 2024/10/15.
//

import Cocoa

class TranslationOverlayView: NSView {
    var translatedObservations: [ProcessedTextObservation] = []
    var isShowingTranslation = true

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTranslations(_ translations: [ProcessedTextObservation]) {
        self.translatedObservations = translations
        self.needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard isShowingTranslation else { return }
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        for observation in translatedObservations {
            let rect = observation.boundingBox
            
            // 绘制背景以隐藏原文
            context.setFillColor(NSColor.windowBackgroundColor.cgColor)
            context.fill(rect)
            
            // 绘制译文
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
            
            let attributedString = NSAttributedString(string: observation.text, attributes: attributes)
            attributedString.draw(in: rect)
        }
    }

    func toggleTranslation() {
        isShowingTranslation.toggle()
        self.needsDisplay = true
    }
}
