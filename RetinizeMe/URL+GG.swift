//
//  URL+GG.swift
//  RetinizeMe
//
//  Created by Guillaume GUFFROY on 16/03/2017.
//  Copyright © 2017 Guillaume GUFFROY. All rights reserved.
//

import Foundation

extension URL {
    func isDirectory() -> Bool {
        var isDir:ObjCBool = false
        FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    func isImage() -> Bool {
        return ["png","jpg","gif"].contains(pathExtension)
    }
}
