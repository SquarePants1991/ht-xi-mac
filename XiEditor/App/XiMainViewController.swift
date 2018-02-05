//
//  XiMainViewController.swift
//  XiEditor
//
//  Created by ocean on 2018/2/5.
//  Copyright © 2018年 Raph Levien. All rights reserved.
//

import Cocoa

class XiMainViewController: NSSplitViewController {

    var editorViewController: EditViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.splitView.delegate = self
        // Create Document Tree Panel
        if let documentTreePanelVC = XiDirectoryTreePanel.instance() {
            let splitItem = NSSplitViewItem.init(sidebarWithViewController: documentTreePanelVC)
            splitItem.minimumThickness = 10
            splitItem.maximumThickness = 800
            self.addSplitViewItem(splitItem)
        }
        
        // Create Editor VC
        let storyboard = NSStoryboard.init(name: NSStoryboard.Name.init("Main"), bundle: Bundle.main)
        let editorVC = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier.init("EditViewController")) as! EditViewController
        self.addSplitViewItem(NSSplitViewItem.init(viewController: editorVC))
        self.editorViewController = editorVC
        
        self.splitView.setPosition(180, ofDividerAt: 0)
    }
}
