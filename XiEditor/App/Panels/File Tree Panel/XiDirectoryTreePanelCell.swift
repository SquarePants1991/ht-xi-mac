//
//  XiDirectoryTreePanelCell.swift
//  XiEditor
//
//  Created by ocean on 2018/2/5.
//  Copyright © 2018年 Raph Levien. All rights reserved.
//

import Cocoa

let kIconKeyDir = "kIconKeyDir"
let kIconKeyFileDefault = "kIconKeyFileDefault"

class XiDirectoryTreePanelCell: NSTableRowView {
    
    static var textColor: NSColor = NSColor.black
    static var font: NSFont = NSFont.systemFont(ofSize: 13)
    static var selectionColor: NSColor = NSColor.blue
    static var iconConfig: [String: (String, NSColor)] = [String: (String, NSColor)]()
    
    @IBOutlet var iconImageView: NSTextField!
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
        self.backgroundColor = NSColor.clear
        self.iconImageView.stringValue = "\u{e2c8}"
        self.iconImageView.backgroundColor = NSColor.clear
        self.fileNameLabel.backgroundColor = NSColor.clear
        self.fileNameLabel.stringValue = "Hello World"
    }
    
    func updateViews() {
        self.fileNameLabel.font = XiDirectoryTreePanelCell.font
        self.fileNameLabel.textColor = XiDirectoryTreePanelCell.textColor
        if let item = self.objectValue as? XiDirectoryTreeItem {
            self.fileNameLabel.stringValue = item.filename ?? ""
            self.cellLeftPaddingConstraint.constant = CGFloat(item.level()) * 16.0 + 5
            if item.isDir() {
                if let iconInfo: (String, NSColor) = XiDirectoryTreePanelCell.iconConfig[kIconKeyDir] {
                    self.iconImageView.stringValue = iconInfo.0
                    self.iconImageView.textColor = iconInfo.1
                }
            } else {
                if let iconInfo: (String, NSColor) = XiDirectoryTreePanelCell.iconConfig[item.fileExt] {
                    self.iconImageView.stringValue = iconInfo.0
                    self.iconImageView.textColor = iconInfo.1
                } else if let iconInfo: (String, NSColor) = XiDirectoryTreePanelCell.iconConfig[kIconKeyFileDefault] {
                    self.iconImageView.stringValue = iconInfo.0
                    self.iconImageView.textColor = iconInfo.1
                }
            }
        }
    }
    
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            XiDirectoryTreePanelCell.selectionColor.setFill()
            let selectionPath = NSBezierPath.init(roundedRect: self.bounds, xRadius: 0, yRadius: 0)
            selectionPath.fill()
        }
    }
}
