//
//  XiDirectoryTreePanelCell.swift
//  XiEditor
//
//  Created by ocean on 2018/2/5.
//  Copyright © 2018年 Raph Levien. All rights reserved.
//

import Cocoa

class XiDirectoryTreePanelCell: NSView {
    
    @IBOutlet var iconImageView: NSImageView!
    @IBOutlet var fileNameLabel: NSTextField!
    @IBOutlet weak var cellLeftPaddingConstraint: NSLayoutConstraint!
    
    private var _objectValue: Any?
    @objc
    var objectValue: Any? {
        set(value) {
            _objectValue = value
            self.updateViews()
        }
        get {
            return _objectValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.fileNameLabel.backgroundColor = NSColor.clear
        self.fileNameLabel.stringValue = "Hello World"
    }
    
    func updateViews() {
        if let item = self.objectValue as? XiDirectoryTreeItem {
            self.fileNameLabel.stringValue = item.filename
            self.cellLeftPaddingConstraint.constant = CGFloat(item.level()) * 10.0
        }
        
    }
}
