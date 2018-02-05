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
    var selectedItems: [String: XiDirectoryTreeItem] = [String: XiDirectoryTreeItem]()
    var fileTree: XiDirectoryTree?

    class func instance() -> XiDirectoryTreePanel? {
        let storyboard = NSStoryboard.init(name: NSStoryboard.Name("Panels"), bundle: Bundle.main)
        let vc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("XiDirectoryTreePanel"))
        return vc as? XiDirectoryTreePanel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.tableView.dataSource = self
        self.tableView.delegate = self

        loadFileTree()
    }
    
    func loadFileTree() {
        self.fileTree = XiDirectoryTree.init(rootPath: "/Users/yangwang/Documents/Projects/OnGit/ht-xi-mac")
        updateTree()
    }

    func updateTree() {
        if let tree = self.fileTree {
            let unfolderItems: [XiDirectoryTreeItem] = self.selectedItems.values.map { $0 }
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
        if let item = self.datasource?[row] {
            switch item.type {
                case .directory:
                    if selectedItems[item.path] != nil {
                        selectedItems[item.path] = nil
                    } else {
                        selectedItems[item.path] = item
                    }
                case .file(let file):
                    let url = URL.init(fileURLWithPath: item.path)
                    (NSDocumentController.shared as! XiDocumentController).openDocument(withContentsOf: url, display: true) { document, b, error in

                    }

            }

        }
        updateTree()
        return false;
    }
}
