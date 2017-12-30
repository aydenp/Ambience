//
//  AppDelegate.swift
//  Ambience
//
//  Created by Ayden Panhuyzen on 2017-12-30.
//  Copyright © 2017 Ayden Panhuyzen. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, StatusMenuManagerDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: -2)
    var menuManager: StatusMenuManager!
    @IBOutlet weak var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // Setup menu bar icon
        // TODO: New icon
        statusItem.button?.image = NSImage(named: .colorPanel)
        
        // Setup menu
        let menu = NSMenu()
        menuManager = StatusMenuManager(menu: menu, delegate: self, items: [
            .settingBool(title: "Enable Ambience", key: "enabled", initial: true),
            .separator,
            .settingTimeInterval(title: "Update Interval", key: "updateInterval", initial: 0.25, list: [0.1, 0.25, 0.5, 1, 1.5, 2, 2.5, 3, 5]),
            .separator,
            .text(title: "Quit Ambience", action: { NSApplication.shared.terminate($0) }, keyEquivalent: "q")
        ])
        statusItem.menu = menu
    }
    
    // MARK: - Status Menu Manager Delegate
    
    func menuSettingChanged(with key: String) {
        print("menu setting changed with key: \(key)")
    }
}
