//
//  AppDelegate.swift
//  Ambience
//
//  Created by Ayden Panhuyzen on 2017-12-30.
//  Copyright © 2017 Ayden Panhuyzen. All rights reserved.
//

import Cocoa

let initialUpdateIntervalValue: TimeInterval = 0.25
class AppDelegate: NSObject, NSApplicationDelegate, StatusMenuManagerDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: -2)
    var menuManager: StatusMenuManager!, timer: Timer?, bridgeSelectionMenuManager: StatusMenuManager!
    var hueSDK: PHHueSDK!, bridgeSearch: PHBridgeSearching?
    @IBOutlet weak var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // Setup Hue SDK
        hueSDK = PHHueSDK()
        hueSDK.startUp()
        hueSDK.enableLogging(true)
        
        // Setup menu bar icon
        // TODO: New icon
        statusItem.button?.image = NSImage(named: .colorPanel)
        
        // Setup bridge selection menu
        let bridgeMenu = NSMenu()
        bridgeSelectionMenuManager = StatusMenuManager(menu: bridgeMenu, delegate: self, items: [
            .text(title: "Searching for Bridges...", action: nil, keyEquivalent: "")
        ])
        
        // Setup menu
        let menu = NSMenu()
        menuManager = StatusMenuManager(menu: menu, delegate: self, items: [
            .settingBool(title: "Enable Ambience", key: "enabled", initial: true),
            .separator,
            .submenu(title: "Select Bridge", submenu: bridgeMenu),
            .settingTimeInterval(title: "Update Interval", key: "updateInterval", initial: initialUpdateIntervalValue, list: [0.1, 0.25, 0.5, 1, 1.5, 2, 2.5, 3, 5]),
            .settingBool(title: "Smooth Transition", key: "smoothTransition", initial: true),
            .separator,
            .text(title: "Quit Ambience", action: { NSApplication.shared.terminate($0) }, keyEquivalent: "q")
        ])
        statusItem.menu = menu
        
        enableLocalHeartbeat()
        setupTimer()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        disableLocalHeartbeat()
    }
    
    // MARK: - Timer Management and Action
    
    func setupTimer() {
        // Destroy previous timer
        timer?.invalidate()
        timer = nil
        // Setup new timer if enabled
        let interval = UserDefaults.standard.object(forKey: "updateInterval") as? TimeInterval ?? initialUpdateIntervalValue
        if UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true, interval > 0 {
            timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        }
    }
    
    @objc func tick() {
        guard let colour = ScreenCapturer.shared.getScreenAverageColour() else { return }
        print(colour)
    }
    
    // MARK: - Hue Bridge Connection Management
    
    func enableLocalHeartbeat() {
        // Search for bridges
        searchForBridges()
        
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
        if cache != nil && cache?.bridgeConfiguration != nil && cache?.bridgeConfiguration.ipaddress != nil {
            // We have a bridge IP
            hueSDK.enableLocalConnection()
        }
    }
    
    func disableLocalHeartbeat() {
        hueSDK.disableLocalConnection()
    }
    
    func searchForBridges() {
        // Start searching for bridges
        bridgeSearch?.cancelSearch()
        bridgeSearch = PHBridgeSearching(upnpSearch: true, andPortalSearch: true, andIpAddressSearch: true)
        bridgeSearch?.startSearch { self.foundBridges = $0 as? [String: String] }
    }
    
    /// Dictionary of found bridges where the key is MAC address and value is IP.
    var foundBridges: [String: String]? {
        didSet { populateBridgesMenu() }
    }
    
    private func populateBridgesMenu() {
        if let foundBridges = foundBridges {
            var items = [StatusMenuManager.StatusMenuItem]()
            if foundBridges.count > 0 {
                foundBridges.forEach { (key, value) in
                    items.append(.text(title: "\(value) (\(key))", action: { _ in self.hueSDK.setBridgeToUseWithId(key, ipAddress: value) }, keyEquivalent: ""))
                }
            } else {
                items.append(.text(title: "No Bridges found", action: nil, keyEquivalent: ""))
            }
            items.append(contentsOf: [.separator, .text(title: "Refresh", action: { _ in self.searchForBridges() }, keyEquivalent: "")])
            bridgeSelectionMenuManager.items = items
        } else {
            bridgeSelectionMenuManager.items = [.text(title: "Searching for Bridges...", action: nil, keyEquivalent: "")]
        }
    }
    
    // MARK: - Status Menu Manager Delegate
    
    func statusMenuManager(_ manager: StatusMenuManager, changedMenuSettingWithKey key: String) {
        setupTimer()
    }
}
