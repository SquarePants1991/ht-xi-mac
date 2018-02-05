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
    
    class func instance() -> XiDirectoryTreePanel? {
        let storyboard = NSStoryboard.init(name: NSStoryboard.Name("Panels"), bundle: Bundle.main)
        let vc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("XiDirectoryTreePanel"))
        return vc as? XiDirectoryTreePanel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.tableView.dataSource = self
        loadData()
    }
    
    func loadData() {
        let tree = XiDirectoryTree.init(rootPath: "/Users/ocean/Documents/Projects/GitHub/xi-mac")
        datasource = tree.flatItems(unfolderItems: [])
        self.tableView.reloadData()
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
        
        return true;
    }
}
