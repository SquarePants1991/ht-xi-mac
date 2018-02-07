//
//  XiDirectoryTree.swift
//  XiEditor
//
//  Created by ocean on 2018/2/5.
//  Copyright © 2018年 Raph Levien. All rights reserved.
//

import Foundation

enum XiDirectoryTreeItemType {
    case directory
    case file(String)
}

class XiDirectoryTreeItem {
    public var type: XiDirectoryTreeItemType = .directory
    public var path: String = ""
    public var filename: String = ""
    public var fileExt: String = ""
    public var children: [XiDirectoryTreeItem] = [XiDirectoryTreeItem]()
    
    public weak var parent: XiDirectoryTreeItem?
    
    init(rootPath: String, subpath: String) {
        let pathComponents = subpath.split(separator: "/")
        let filename = String(pathComponents.last ?? "")
        let fullpath = "\(rootPath)/\(subpath)"
        var isDirectory: ObjCBool = ObjCBool(false)
        FileManager.default.fileExists(atPath: fullpath, isDirectory: &isDirectory)
        if isDirectory.boolValue {
            self.type = .directory
        } else {
            self.type = .file(filename)
        }
        self.path = fullpath
        self.filename = filename
        if let ext = self.filename.split(separator: ".").last {
            self.fileExt = String(ext)
        }
    }
    
    public func level() -> NSInteger {
        var level = 0;
        var currentItem: XiDirectoryTreeItem? = self.parent
        while currentItem != nil {
            level += 1
            currentItem = currentItem?.parent
        }
        return level
    }
    
    public func isDir() -> Bool {
        return children.count > 0
    }
}

class XiDirectoryTree {
    public var items: [XiDirectoryTreeItem] = [XiDirectoryTreeItem]()
    
    init(rootPath: String) {
        let rootPathComponents = rootPath.split(separator: "/")
        if let projectFolderName = rootPathComponents.last {
            let path = rootPath[..<rootPath.index(rootPath.endIndex, offsetBy: -projectFolderName.count)]
            let rootItem = XiDirectoryTreeItem(rootPath: String(path), subpath: String(projectFolderName))
            items.append(rootItem)
            buildItems(rootPath: rootPath, rootItem: rootItem)
        }
    }
    
    func buildItems(rootPath: String, rootItem: XiDirectoryTreeItem?) {
        if let subpaths = try? FileManager.default.contentsOfDirectory(atPath: rootPath) {
            for subpath in subpaths {
                let item = XiDirectoryTreeItem(rootPath: rootPath, subpath: subpath)
                
                if let rootItem = rootItem {
                    rootItem.children.append(item)
                    item.parent = rootItem
                } else {
                    items.append(item)
                    item.parent = nil
                }
                
                if case XiDirectoryTreeItemType.directory = item.type {
                    buildItems(rootPath: item.path, rootItem: item)
                }
            }
        }
    }
    
    private func _flatItems(parentItem: XiDirectoryTreeItem, collector: inout [XiDirectoryTreeItem], unfolderItems: [XiDirectoryTreeItem]) {
        collector.append(parentItem)
        if unfolderItems.contains(where: { $0 === parentItem }) {
            for item in parentItem.children {
                _flatItems(parentItem: item, collector: &collector, unfolderItems: unfolderItems)
            }
        }
    }
    
    public func flatItems(unfolderItems: [XiDirectoryTreeItem]) -> [XiDirectoryTreeItem] {
        var flatItems = [XiDirectoryTreeItem]()
        for item in items {
            _flatItems(parentItem: item, collector: &flatItems, unfolderItems: unfolderItems)
        }
        return flatItems
    }
}

