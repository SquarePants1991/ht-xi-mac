//
//  XiMainViewController.swift
//  XiEditor
//
//  Created by ocean on 2018/2/5.
//  Copyright © 2018年 Raph Levien. All rights reserved.
//

import Cocoa

@objc
class XiMainViewController: NSSplitViewController {

    var editorViewController: EditViewController!
    var editorViewContainer: NSTabViewController!
    
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
        
        // Create Editor VC Container
        self.editorViewContainer = NSTabViewController()
        self.editorViewContainer.addObserver(self, forKeyPath: "selectedTabViewItemIndex", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        self.addSplitViewItem(NSSplitViewItem.init(viewController: self.editorViewContainer))
        
        self.splitView.setPosition(180, ofDividerAt: 0)
    }
    
    func addEditViewController(editVC: EditViewController) {
        self.editorViewContainer.addTabViewItem(NSTabViewItem.init(viewController: editVC))
        self.editorViewContainer.selectedTabViewItemIndex = self.editorViewContainer.tabViewItems.count - 1
    }

    override func keyDown(with event: NSEvent) {
        let tabItem: NSTabViewItem = self.editorViewContainer.tabViewItems[self.editorViewContainer.selectedTabViewItemIndex]
        if let newEditVC: EditViewController = tabItem.viewController as? EditViewController {
            newEditVC.keyDown(with: event)
        }
    }

    @objc
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let newIndex = (change?[NSKeyValueChangeKey.newKey] as? Int) ?? -1
        let oldIndex = (change?[NSKeyValueChangeKey.oldKey] as? Int) ?? -1
        if newIndex >= 0 {
            let tabItem: NSTabViewItem = self.editorViewContainer.tabViewItems[newIndex]
            if let newEditVC: EditViewController = tabItem.viewController as? EditViewController {
                newEditVC.windowDidBecomeKey(Notification.init(name: Notification.Name("")))
            }
        }
        if oldIndex >= 0 {
            let tabItem: NSTabViewItem = self.editorViewContainer.tabViewItems[oldIndex]
            if let oldEditVC: EditViewController = tabItem.viewController as? EditViewController {
                oldEditVC.windowDidResignKey(Notification.init(name: Notification.Name("")))
            }
        }
    }


}