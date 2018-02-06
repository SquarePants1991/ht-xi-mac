//
//  XiDirectoryTreePanel.swift
//  XiEditor
//
//  Created by ocean on 2018/2/5.
//  Copyright © 2018年 Raph Levien. All rights reserved.
//

import Cocoa
import SnapKit

class XiDirectoryTreePanel: NSViewController {

    @IBOutlet var tableView: NSTableView!
    var datasource: [XiDirectoryTreeItem]?
    var tree: XiDirectoryTree?
    var selectedItems: [String: XiDirectoryTreeItem] = [String: XiDirectoryTreeItem]()
    
    class func instance() -> XiDirectoryTreePanel? {
        let storyboard = NSStoryboard.init(name: NSStoryboard.Name("Panels"), bundle: Bundle.main)
        let vc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("XiDirectoryTreePanel"))
        return vc as? XiDirectoryTreePanel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.tableView.dataSource = self
        self.tableView.delegate = self
        loadData()
    }
    
    func loadData() {
        tree = XiDirectoryTree.init(rootPath: "/Users/ocean/Documents/Projects/GitHub/xi-mac")
        if let tree = tree {
            datasource = tree.flatItems(unfolderItems: [])
            self.tableView.reloadData()
        }
    }
    
    func updateTree() {
        let unfolderItems = self.selectedItems.values.map { $0 }
        if let tree = tree {
            datasource = tree.flatItems(unfolderItems: unfolderItems)
            self.tableView.reloadData()
        }
    }
}

extension XiDirectoryTreePanel: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.datasource?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.datasource?[row]
    }
}

extension XiDirectoryTreePanel: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if let selectedItem = self.datasource?[row] {
            switch selectedItem.type {
            case .directory:
                if selectedItems[selectedItem.path] != nil {
                    selectedItems.removeValue(forKey: selectedItem.path)
                } else {
                    selectedItems[selectedItem.path] = selectedItem
                }
            case .file(let _):
                let fileUrl = URL.init(fileURLWithPath: selectedItem.path)
                (NSDocumentController.shared as! XiDocumentController).openDocument(withContentsOf: fileUrl, display: true, completionHandler: { (doc, result, error) in
                    
                })
            
            }
            
        }
        updateTree()
        return true;
    }
}
