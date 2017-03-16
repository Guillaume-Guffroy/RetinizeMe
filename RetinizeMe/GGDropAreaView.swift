//
//  GGDropAreaView.swift
//  RetinizeMe
//
//  Created by Guillaume GUFFROY on 15/03/2017.
//  Copyright © 2017 Guillaume GUFFROY. All rights reserved.
//

import Cocoa

protocol GGDropAreaViewDelegate {
    func processURLs(_ urls: [URL])
}


class GGDropAreaView: NSView {

    var delegate: GGDropAreaViewDelegate?
    var acceptableTypes: Set<String> { return [NSURLPboardType] }
    let filteringOptions = [NSPasteboardURLReadingContentsConformToTypesKey:NSImage.imageTypes()+[kUTTypeFolder as String]]
    var isReceivingDrag = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        layer?.cornerRadius = 10
        register(forDraggedTypes: Array(acceptableTypes))
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if isReceivingDrag {
            NSColor.selectedControlColor.set()
            
            let path = NSBezierPath(rect:bounds)
            path.lineWidth = 10
            path.stroke()
        }
    }
    
    //we override hitTest so that this view which sits at the top of the view hierachy
    //appears transparent to mouse clicks
    override func hitTest(_ aPoint: NSPoint) -> NSView? {
        return nil
    }
    
    func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        var canAccept = false
        let pasteBoard = draggingInfo.draggingPasteboard()
        if pasteBoard.canReadObject(forClasses: [NSURL.self], options: filteringOptions) {
            canAccept = true
        }
        return canAccept
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let allow = shouldAllowDrag(sender)
        isReceivingDrag = allow
        return allow ? .copy : NSDragOperation()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let allow = shouldAllowDrag(sender)
        return allow
    }
    
    override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        isReceivingDrag = false
        let pasteBoard = draggingInfo.draggingPasteboard()
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options:filteringOptions) as? [URL], urls.count > 0 {
            delegate?.processURLs(urls)
            return true
        }
        return false
    }
}
