//
//  TextOverlayView.swift
//  test6
//
//  Created by qiuhq on 2024/10/15.
//

import Cocoa

struct ProcessedTextObservation {
    var boundingBox: NSRect
    var text: String
}

class TextOverlayView: NSView {
    var textObservations: [ProcessedTextObservation] = []
    var selectedTextIndex: Int?

    func setObservations(_ observations: [ProcessedTextObservation]) {
        textObservations = observations
        selectedTextIndex = nil
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        for (index, observation) in textObservations.enumerated() {
            let rect = observation.boundingBox
            
            if index == selectedTextIndex {
                context.setFillColor(NSColor.systemBlue.withAlphaComponent(0.3).cgColor)
                context.fill(rect)
            }
            
            context.setStrokeColor(NSColor.systemBlue.cgColor)
            context.stroke(rect)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        for (index, observation) in textObservations.enumerated() {
            if observation.boundingBox.contains(point) {
                selectedTextIndex = index
                needsDisplay = true
                let text = observation.text
                print("选中的文本: \(text)")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                break
            }
        }
    }
}

// 注释：考虑添加以下功能来增强TextOverlayView的功能：
// 1. 实现文本编辑功能，允许用户直接在界面上修改识别出的文本
// 2. 添加文本高亮功能，根据不同的文本类型（如标题、正文）使用不同的颜色
// 3. 实现文本搜索功能，允许用户在识别出的文本中搜索特定内容
// 4. 添加文本导出功能，支持将识别出的文本导出为不同格式（如TXT、PDF）
// 5. 实现文本块合并功能，允许用户手动合并相邻的文本块
