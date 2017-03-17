//
//  MainViewController.swift
//  RetinizeMe
//
//  Created by Guillaume GUFFROY on 15/03/2017.
//  Copyright © 2017 Guillaume GUFFROY. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var dropAreaView: GGDropAreaView!
    @IBOutlet weak var dragLocationLabel: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        dropAreaView.delegate = self
        pathControl.delegate = self
    }
}

extension MainViewController:GGDropAreaViewDelegate {
    func processURLs(_ urls: [URL]) {
        NSAnimationContext.runAnimationGroup({ (context) in
            dragLocationLabel.animator().alphaValue = 0
        }) { [weak self] in
            self?.loader.startAnimation(nil)
            self?.retinize(fileURLs: urls, completion: {
                self?.loader.stopAnimation(nil)
                self?.dragLocationLabel.animator().alphaValue = 1
            })
        }
    }
    
    func retinize(fileURLs:[URL], completion:@escaping () -> Void) {
        guard let destPath = pathControl.url else {
            completion()
            return
        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async { [weak self] in
            self?.treatUrls(urls: fileURLs, destPath:destPath)
            DispatchQueue.main.async(execute: {
                completion()
                return
            })
        }
    }
    
    func treatUrls(urls:[URL], destPath:URL) {
        urls.forEach { (fileURL) in
            if fileURL.isImage() {
                retinizeImageAtURL(fileURL).forEach({ (imageDict) in
                    guard let filename = imageDict["filename"] as? String, let image = imageDict["image"] as? NSImage else {
                        return
                    }
                    
                    let fullPath = URL(fileURLWithPath: filename, relativeTo: destPath)
                    if let data = image.tiffRepresentation, let bmp = NSBitmapImageRep(data: data) {
                        bmp.size = sizeForImage(image:image)
                        let dataToSave = bmp.representation(using: NSBitmapImageFileType.PNG, properties: [NSImageCompressionFactor : 1])
                        do {
                            try dataToSave?.write(to: fullPath, options:.atomic)
                        } catch {
                            print("unable to write file : \(fullPath)")
                        }
                    }
                })
            } else if fileURL.isDirectory() {
                do {
                    let subURLs = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil, options: [])
                    treatUrls(urls: subURLs, destPath: destPath)
                } catch {
                    print("unable to parse directory : \(fileURL)")
                }
            }
        }
    }
    
    
    func retinizeImageAtURL(_ sourceImageURL:URL) -> [[String:Any]] {
        let imageFullName = sourceImageURL.lastPathComponent
        
        guard let sourceImage = NSImage(contentsOf: sourceImageURL),
            let imageExtension = imageFullName.components(separatedBy: ".").last else { return [] }
        
        let imageName = imageFullName.replacingOccurrences(of: ".\(imageExtension)", with: "")
        
        var images:[[String:Any]] = []
        
        let realImageName:String
        
        if imageName.contains("@3x") {
            realImageName = imageName.replacingOccurrences(of: "@3x", with: "")
            
            images.append(["image":sourceImage, "filename" : "\(realImageName)@3x.\(imageExtension)"])
            if let image2x = resize(image: sourceImage, scaleFactor: CGFloat(0.666666)) {
                images.append(["image":image2x, "filename" : "\(realImageName)@2x.\(imageExtension)"])
            }
            if let image1x = resize(image: sourceImage, scaleFactor: CGFloat(0.333333)) {
                images.append(["image":image1x, "filename" : "\(realImageName).\(imageExtension)"])
            }
            
        }
        return images
    }
    
    func resize(image: NSImage, scaleFactor:CGFloat) -> NSImage? {
        let size = sizeForImage(image: image)
        let newSize = CGSize(width: size.width*scaleFactor, height: size.height*scaleFactor)
        
        guard let inRect = NSScreen.main()?.convertRectFromBacking(NSMakeRect(0, 0, newSize.width, newSize.height)) else {
            return nil
        }
        
        let newImage = NSImage(size: inRect.size)
        
        newImage.lockFocus()
        image.draw(in: inRect,
                   from: NSZeroRect,
                   operation: NSCompositingOperation.copy, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = image.size
        return newImage
    }
    
    func sizeForImage(image:NSImage) -> CGSize {
        return image.representations.reduce(CGSize.zero, { (size: CGSize, rep: NSImageRep) -> CGSize in
            return CGSize(width: max(size.width, CGFloat(rep.pixelsWide)), height: max(size.height, CGFloat(rep.pixelsHigh)))
        })
    }
}

extension MainViewController:NSPathControlDelegate {
    func pathControl(_ pathControl: NSPathControl, willDisplay openPanel: NSOpenPanel) {
        openPanel.canCreateDirectories = true
    }
}
