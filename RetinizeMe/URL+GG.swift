//
//  URL+GG.swift
//  RetinizeMe
//
//  Created by Guillaume GUFFROY on 16/03/2017.
//  Copyright © 2017 Guillaume GUFFROY. All rights reserved.
//

import Foundation

extension URL {
    
    
    /// Method to check if URL is directory
    ///
    /// - Returns: <#return value description#>
    func isDirectory() -> Bool {
        var isDir:ObjCBool = false
        FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    
    /// Method to check if URL represent Image
    ///
    /// - Returns: Bool
    func isImage() -> Bool {
        return FileManager.default.fileExists(atPath: self.path) && ["png","jpg","gif"].contains(pathExtension)
    }
}
