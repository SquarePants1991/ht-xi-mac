//
//  XiSplitView.swift
//  XiEditor
//
//  Created by ocean on 2018/2/7.
//  Copyright © 2018年 Raph Levien. All rights reserved.
//

import Cocoa

class XiSplitView: NSSplitView {
    public var overrideDividerColor: NSColor?
    override func drawDivider(in rect: NSRect) {
        self.overrideDividerColor?.setFill()
        let selectionPath = NSBezierPath.init(roundedRect: rect, xRadius: 0, yRadius: 0)
        selectionPath.fill()
    }
}
