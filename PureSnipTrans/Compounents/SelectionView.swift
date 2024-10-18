//
//  SelectionView.swift
//  test6
//
//  Created by qiuhq on 2024/10/15.
//

import Cocoa

protocol SelectionViewDelegate: AnyObject {
    func selectionView(_ selectionView: SelectionView, didFinishSelectionWith rect: NSRect)
}

class SelectionView: NSView {
    weak var delegate: SelectionViewDelegate?
    var selectionRect: NSRect?
    var isSelecting = false
    var startPoint: NSPoint?
    var overlayLayer: CALayer?

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        selectionRect = NSRect(origin: startPoint!, size: .zero)
        isSelecting = true
        overlayLayer?.opacity = 1
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard isSelecting, let startPoint = startPoint else { return }
        
        let currentPoint = convert(event.locationInWindow, from: nil)
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let maxX = max(startPoint.x, currentPoint.x)
        let maxY = max(startPoint.y, currentPoint.y)
        
        selectionRect = NSRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        if let selectionRect = selectionRect {
            let maskLayer = CAShapeLayer()
            maskLayer.frame = bounds
            maskLayer.fillRule = .evenOdd
            let path = CGMutablePath()
            path.addRect(bounds)
            path.addRect(selectionRect)
            maskLayer.path = path
            overlayLayer?.mask = maskLayer
        }
        
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        isSelecting = false
        startPoint = nil
        needsDisplay = true
        
        if let selectionRect = selectionRect {
            delegate?.selectionView(self, didFinishSelectionWith: selectionRect)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let selectionRect = selectionRect {
            NSColor.systemBlue.setStroke()
            let path = NSBezierPath(rect: selectionRect)
            path.lineWidth = 2
            path.stroke()
        }
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}

// 注释：考虑添加以下功能来增强SelectionView的功能：
// 1. 添加缩放功能，允许用户调整选择区域的大小
// 2. 实现多选功能，允许用户选择多个区域
// 3. 添加键盘快捷键支持，如使用方向键微调选择区域
// 4. 实现选择区域的保存和恢复功能
// 5. 添加自定义样式选项，如选择框的颜色、线宽等
