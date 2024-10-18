//
//  AppDelegate.swift
//  test4
//
//  Created by qiuhq on 2024/10/12.
//

import Cocoa
import SwiftUI
import Vision
import NaturalLanguage
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var overlayWindow: NSPanel?
    var selectionView: SelectionView?
    var textOverlayView: TextOverlayView?
    var translationOverlayView: TranslationOverlayView?
    
    let deepLAPI = DeepLTranslationAPI()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
    }
    
    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "截图")
            button.action = #selector(captureScreen)
            button.target = self
        }
    }
    
    @objc func captureScreen() {
        OCRManager.shared.captureScreen { [weak self] image in
            guard let self = self, let image = image else { return }
            self.showOverlayWindow(with: image)
        }
    }
    
    func showOverlayWindow(with image: NSImage) {
        if overlayWindow == nil {
            overlayWindow = NSPanel(contentRect: NSScreen.main!.frame,
                                    styleMask: [.borderless, .nonactivatingPanel],
                                    backing: .buffered,
                                    defer: false)
            overlayWindow?.level = .screenSaver
            overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            overlayWindow?.isOpaque = false
            overlayWindow?.backgroundColor = .clear
            overlayWindow?.isFloatingPanel = true
            overlayWindow?.hidesOnDeactivate = false
        }
        
        let contentView = NSView(frame: (overlayWindow?.contentView?.bounds)!)
        contentView.wantsLayer = true
        contentView.layer?.contents = image
        
        let overlayLayer = CALayer()
        overlayLayer.frame = contentView.bounds
        overlayLayer.backgroundColor = NSColor.black.withAlphaComponent(0.5).cgColor
        overlayLayer.opacity = 0
        contentView.layer?.addSublayer(overlayLayer)
        
        selectionView = SelectionView(frame: contentView.bounds)
        selectionView?.overlayLayer = overlayLayer
        selectionView?.delegate = self
        contentView.addSubview(selectionView!)
        
        textOverlayView = TextOverlayView(frame: contentView.bounds)
        textOverlayView?.isHidden = true
        contentView.addSubview(textOverlayView!)
        
        translationOverlayView = TranslationOverlayView(frame: contentView.bounds)
        translationOverlayView?.isHidden = true
        contentView.addSubview(translationOverlayView!)
        
        let closeButton = NSButton(frame: NSRect(x: 10, y: 10, width: 60, height: 30))
        closeButton.bezelStyle = .rounded
        closeButton.title = "关闭"
        closeButton.target = self
        closeButton.action = #selector(closeOverlayWindow)
        contentView.addSubview(closeButton)
        
        let toggleButton = NSButton(frame: NSRect(x: 80, y: 10, width: 100, height: 30))
        toggleButton.bezelStyle = .rounded
        toggleButton.title = "切换译文"
        toggleButton.target = self
        toggleButton.action = #selector(toggleTranslation)
        contentView.addSubview(toggleButton)
        
        overlayWindow?.contentView = contentView
        overlayWindow?.makeFirstResponder(selectionView)
        overlayWindow?.orderFrontRegardless()
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func closeOverlayWindow() {
        DispatchQueue.main.async {
            self.overlayWindow?.close()
            self.overlayWindow = nil
        }
    }
    
    func performOCR(on image: NSImage, in rect: NSRect) {
        OCRManager.shared.performOCR(on: image, in: rect) { [weak self] observations in
            DispatchQueue.main.async {
                let processedObservations = TextProcessingManager.shared.processObservations(observations, in: rect)
                self?.textOverlayView?.setObservations(processedObservations)
                self?.textOverlayView?.isHidden = false
                
                let filteredTexts = TextProcessingManager.shared.filterAndPrintTexts(processedObservations)
                print("符合条件的文本数组：\(filteredTexts)")
                
                if !filteredTexts.isEmpty {
                    self?.translateAndPrintSentences(filteredTexts)
                }
            }
        }
    }
    
    private func translateAndPrintSentences(_ sentences: [String]) {
        deepLAPI.translateTexts(sentences, sourceLanguage: "EN", targetLanguage: "ZH") { [weak self] result in
            switch result {
            case .success(let translation):
                DispatchQueue.main.async {
                    var translatedObservations: [ProcessedTextObservation] = []
                    for (index, translatedText) in translation.translations.enumerated() {
                        if index < self?.textOverlayView?.textObservations.count ?? 0 {
                            let originalObservation = self?.textOverlayView?.textObservations[index]
                            let translatedObservation = ProcessedTextObservation(
                                boundingBox: originalObservation?.boundingBox ?? .zero,
                                text: translatedText.text
                            )
                            translatedObservations.append(translatedObservation)
                        }
                    }
                    self?.translationOverlayView?.updateTranslations(translatedObservations)
                    self?.translationOverlayView?.isHidden = false
                    self?.textOverlayView?.isHidden = true
                }
            case .failure(let error):
                print("翻译错误: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func toggleTranslation() {
        translationOverlayView?.toggleTranslation()
        textOverlayView?.isHidden = !(translationOverlayView?.isShowingTranslation ?? false)
    }
}

extension AppDelegate: SelectionViewDelegate {
    func selectionView(_ selectionView: SelectionView, didFinishSelectionWith rect: NSRect) {
        guard let image = (overlayWindow?.contentView?.layer?.contents as? NSImage) else { return }
        performOCR(on: image, in: rect)
    }
}
