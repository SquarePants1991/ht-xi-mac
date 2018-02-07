// Copyright 2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Cocoa

struct PendingNotification {
    let method: String
    let params: Any
    let callback: ((Any?) -> ())?
}

class Document: NSDocument {

    /// used internally to keep track of groups of tabs
    static fileprivate var _nextTabbingIdentifier = 0

    /// returns the next available tab group identifer. When we create a new window, if it is not part of an existing tab group it is assigned a new one.
    static private func nextTabbingIdentifier() -> String {
        _nextTabbingIdentifier += 1
        return "tab-group-\(_nextTabbingIdentifier)"
    }

    /// if set, should be used as the tabbingIdentifier of new documents' windows.
    static var preferredTabbingIdentifier: String?

    /// Used to determine initial locations for new windows.
    fileprivate static var _lastWindowFrame: NSRect = {
        if let saved = UserDefaults.standard.string(forKey: USER_DEFAULTS_NEW_WINDOW_FRAME) {
            return NSRectFromString(saved)
        } else {
            return NSRect(x: 200, y: 200, width: 600, height: 600)
        }
    }()

    var dispatcher: Dispatcher!
    
    /// coreViewIdentifier is the name used to identify this document when communicating with the Core.
    var coreViewIdentifier: ViewIdentifier? {
        didSet {
            guard coreViewIdentifier != nil else { return }
            // apply initial updates when coreViewIdentifier is set
            for pending in self.pendingNotifications {
                self.sendRpcAsync(pending.method, params: pending.params, callback: pending.callback)
            }
            self.pendingNotifications.removeAll()
        }
    }
    
    /// Identifier used to group windows together into tabs.
    /// - Todo: I suspect there is some potential confusion here around dragging tabs into and out of windows? 
    /// I.e I'm not sure if the system ever modifies the tabbingIdentifier on our windows,
    /// which means these could get out of sync. But: nothing obviously bad happens when I test it.
    /// If this is problem we could use KVO to keep these in sync.
    var tabbingIdentifier: String
    
	var pendingNotifications: [PendingNotification] = [];
    var editViewController: EditViewController?

    /// Returns `true` if this document contains no data.
    var isEmpty: Bool {
        return editViewController?.lines.isEmpty ?? false
    }
    
    override init() {
        dispatcher = (NSApplication.shared.delegate as? AppDelegate)?.dispatcher
        tabbingIdentifier = Document.preferredTabbingIdentifier ?? Document.nextTabbingIdentifier()
        super.init()
        // I'm not 100% sure this is necessary but it can't _hurt_
        self.hasUndoManager = false
    }
    
    static var baseWindowController: NSWindowController?
 
    override func makeWindowControllers() {
        if Document.baseWindowController == nil {
            let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
            Document.baseWindowController = storyboard.instantiateController(
                withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Document Window Controller")) as? NSWindowController
            Document.baseWindowController?.window?.makeKeyAndOrderFront(self)
            Document.baseWindowController?.window?.appearance = NSAppearance(named:NSAppearance.Name.vibrantDark)
        }
        let storyboard = NSStoryboard.init(name: NSStoryboard.Name.init("Main"), bundle: Bundle.main)
        self.editViewController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier.init("EditViewController")) as? EditViewController
        if let mainVC = Document.baseWindowController?.contentViewController as? XiMainViewController, let editViewController = self.editViewController {
            mainVC.addEditViewController(editVC: editViewController)
            editViewController.document = self
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(Document.windowChangedNotification(_:)),
            name: NSWindow.didMoveNotification, object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(Document.windowChangedNotification(_:)),
            name: NSWindow.didResizeNotification, object: nil)
    }

    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void) {
        self.fileURL = url
        self.save(url.path)
        //TODO: save operations should report success, and we should pass any errors to the completion handler
        completionHandler(nil)
    }

    // Document.close() can be called multiple times (on window close and application terminate)
    override func close() {
        if let identifier = self.coreViewIdentifier {
            Events.CloseView(viewIdentifier: identifier).dispatch(dispatcher!)
            super.close()
        }
    }
    
    override var isEntireFileLoaded: Bool {
        return false
    }
    
    override class var autosavesInPlace: Bool {
        return false
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // required override. xi-core handles file reading.
    }
    
    fileprivate func save(_ filename: String) {
        Events.Save(viewIdentifier: coreViewIdentifier!, path: filename).dispatch(dispatcher!)
    }
    
    /// Send a notification specific to the tab. If the tab name hasn't been set, then the
    /// notification is queued, and sent when the tab name arrives.
    func sendRpcAsync(_ method: String, params: Any, callback: ((Any?) -> ())? = nil) {
        Trace.shared.trace(method, .rpc, .begin)
        if let coreViewIdentifier = coreViewIdentifier {
            let inner = ["method": method, "params": params, "view_id": coreViewIdentifier] as [String : Any]
            dispatcher?.coreConnection.sendRpcAsync("edit", params: inner, callback: callback)
        } else {
            pendingNotifications.append(PendingNotification(method: method, params: params, callback: callback))
        }
        Trace.shared.trace(method, .rpc, .end)
    }

    /// Note: this is a blocking call, and will also fail if the tab name hasn't been set yet.
    /// We should try to migrate users to either fully async or callback based approaches.
    func sendRpc(_ method: String, params: Any) -> Any? {
        Trace.shared.trace(method, .rpc, .begin)
        let inner = ["method": method as AnyObject, "params": params, "view_id": coreViewIdentifier as AnyObject] as [String : Any]
        let result = dispatcher?.coreConnection.sendRpc("edit", params: inner)
        Trace.shared.trace(method, .rpc, .end)
        return result
    }

    /// Send a custom plugin command.
    func sendPluginRpc(_ method: String, receiver: String, params innerParams: [String: AnyObject]) {
        var innerParams = innerParams;
        if innerParams["view"] != nil {
            innerParams["view"] = coreViewIdentifier! as AnyObject
        }

        let params = ["command": "plugin_rpc",
                      "view_id": coreViewIdentifier!,
                      "receiver": receiver,
                      "rpc": [
                        "rpc_type": "notification",
                        "method": method,
                        "params": innerParams]] as [String: Any]

        dispatcher.coreConnection.sendRpcAsync("plugin", params: params)
    }
        
    func sendWillScroll(first: Int, last: Int) {
        self.sendRpcAsync("scroll", params: [first, last])
    }

    func updateAsync(update: [String: AnyObject]) {
        if let editVC = editViewController {
            editVC.updateAsync(update: update)
        }
    }
    
    /// Returns the frame to be used for the next new window.
    /// - Note: This attempts to replicate the behaviour of native macOS applications.
    /// On launch, an initial location is chosen, generally based on the position of
    /// the last manually moved view during the application's last run; subsequent
    /// windows are offset from this by approximately the width of the title bar.
    /// If a window clips the screen, the position starts again from the beginning
    /// of the clipped axis.
    func frameForNewWindow() -> NSRect {
        let offsetSize: CGFloat = 22
        let screenBounds = NSScreen.main!.visibleFrame
        var nextFrame = NSOffsetRect(Document._lastWindowFrame, offsetSize, -offsetSize)
        if nextFrame.maxX > screenBounds.maxX {
            nextFrame.origin.x = screenBounds.minX + offsetSize
        }
        if nextFrame.minY <= 0 {
            nextFrame.origin.y = screenBounds.maxY - nextFrame.height
        }
        Document._lastWindowFrame = nextFrame
        return nextFrame
    }
    
    /// Updates the location used for creating new windows on launch
    @objc func windowChangedNotification(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            let frameString = NSStringFromRect(window.frame)
            UserDefaults.standard.setValue(frameString, forKey: USER_DEFAULTS_NEW_WINDOW_FRAME)
        }
    }
}
