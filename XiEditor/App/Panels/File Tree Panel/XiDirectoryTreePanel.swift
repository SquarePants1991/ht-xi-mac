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
    var theme: Theme?
    
    class func instance() -> XiDirectoryTreePanel? {
        let storyboard = NSStoryboard.init(name: NSStoryboard.Name("Panels"), bundle: Bundle.main)
        let vc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("XiDirectoryTreePanel"))
        return vc as? XiDirectoryTreePanel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged(notification:)), name: NSNotification.Name("kThemeChanged"), object: nil)
        
        self.tableView.backgroundColor = NSColor.clear
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.target = self
        self.tableView.action = #selector(tableViewCellClicked(sender:))
        
        loadFileTree()
    }
    
    func loadFileTree() {
        self.fileTree = XiDirectoryTree.init(rootPath: "/Users/ocean/Documents/Projects/GitHub/xi-mac/XiEditor")
        updateTree()
    }
    
    func updateTree() {
        let selectedIndexes = self.tableView.selectedRowIndexes
        if let tree = self.fileTree {
            let unfolderItems: [XiDirectoryTreeItem] = self.selectedItems.values.map { $0 }
            datasource = tree.flatItems(unfolderItems: unfolderItems)
            self.tableView.reloadData()
        }
        self.tableView.selectRowIndexes(selectedIndexes, byExtendingSelection: false)
    }
    
    func setupAppearance(theme: Theme) {
        self.theme = theme
        self.tableView.backgroundColor = theme.background
        XiDirectoryTreePanelCell.textColor = theme.foreground
        XiDirectoryTreePanelCell.selectionColor = theme.selection
        XiDirectoryTreePanelCell.iconConfig = [
            kIconKeyDir: ("\u{e2c8}", NSColor.white),
            kIconKeyFileDefault: ("\u{e24d}", NSColor.lightGray),
            "swift": ("\u{e86f}", NSColor.orange),
        ]
        self.tableView.reloadData()
    }
    
    @objc
    func themeChanged(notification: Notification) {
        if let theme = notification.object as? Theme {
            setupAppearance(theme: theme)
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
    @objc
    func tableViewCellClicked(sender: Any?) {
        let row = tableView.clickedRow
        if let datasource = self.datasource, row >= 0 && row <= datasource.count - 1 {
            let item = datasource[row]
            switch item.type {
            case .directory:
                if selectedItems[item.path] != nil {
                    selectedItems[item.path] = nil
                } else {
                    selectedItems[item.path] = item
                }
            case .file:
                let url = URL.init(fileURLWithPath: item.path)
                (NSDocumentController.shared as! XiDocumentController).openDocument(withContentsOf: url, display: true) { document, b, error in
                    
                }
            }
        }
        updateTree()
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return XiDirectoryTreePanelCell()
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20
    }
}

