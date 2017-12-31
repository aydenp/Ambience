//
//  StatusMenuManager.swift
//  Ambience
//
//  Created by Ayden Panhuyzen on 2017-12-30.
//  Copyright © 2017 Ayden Panhuyzen. All rights reserved.
//

import Cocoa

/// Dynamically manage status item NSMenu's with settings.
class StatusMenuManager {
    enum StatusMenuItem {
        case settingBool(title: String, key: String, initial: Bool)
        case settingTimeInterval(title: String, key: String, initial: TimeInterval, list: [TimeInterval])
        case text(title: String, action: ((NSMenuItem) -> ())?, keyEquivalent: String)
        case submenu(title: String, submenu: NSMenu)
        case separator
        
        func menuItem(for manager: StatusMenuManager) -> NSMenuItem {
            switch self {
            case .text(let title, let action, let keyEquivalent):
                let item = NSMenuItem(title: title, action: action != nil ? #selector(manager.handleItemClick(item:)) : nil, keyEquivalent: keyEquivalent)
                item.target = manager
                return item
            case .settingBool(let title, let key, let initial):
                let item = NSMenuItem(title: title, action: #selector(manager.handleItemClick(item:)), keyEquivalent: "")
                item.state = UserDefaults.standard.object(forKey: key) as? Bool ?? initial ? .on : .off
                item.target = manager
                return item
            case .settingTimeInterval(let title, let key, let initial, let list):
                let selectedValue = UserDefaults.standard.object(forKey: key) as? TimeInterval ?? initial
                let submenu = NSMenu()
                list.enumerated().map { (index, element) -> NSMenuItem in
                    let item = NSMenuItem(title: element >= 1 ? "\(element)s" : "\(Int(element * 1000))ms", action: #selector(manager.handleItemClick(item:)), keyEquivalent: "")
                    item.tag = index
                    item.state = element == selectedValue ? .on : .off
                    item.target = manager
                    return item
                }.forEach { submenu.addItem($0) }
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.submenu = submenu
                return item
            case .submenu(let title, let submenu):
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.submenu = submenu
                return item
            case .separator: return .separator()
            }
        }
    }
    
    /// The menu managed by this object.
    var menu: NSMenu
    
    /// The manager's delegate.
    weak var delegate: StatusMenuManagerDelegate?
    
    init(menu: NSMenu, delegate: StatusMenuManagerDelegate? = nil, items: [StatusMenuItem] = []) {
        self.menu = menu
        self.delegate = delegate
        self.items = items
        defer { self.reloadMenuItems() }
    }
    
    // MARK: - Item Storage and Loading
    
    /// The items to display in the menu.
    var items = [StatusMenuItem]() {
        didSet { reloadMenuItems() }
    }
    
    /// Reload the items displayed in the menu.
    private func reloadMenuItems() {
        menu.removeAllItems()
        items.enumerated().map { (index, element) -> NSMenuItem in
            let item = element.menuItem(for: self)
            item.tag = index
            return item
        }.forEach { menu.addItem($0) }
    }
    
    // MARK: - Item Actions
    
    @objc func handleItemClick(item: NSMenuItem) {
        switch items[item.parent?.tag ?? item.tag] {
        case .text(_, let action, _):
            action?(item)
        case .settingBool(_, let key, let initial):
            UserDefaults.standard.set(!(UserDefaults.standard.object(forKey: key) as? Bool ?? initial), forKey: key)
            handleSettingChange(with: key)
        case .settingTimeInterval(_, let key, _, let list):
            UserDefaults.standard.set(list[item.tag], forKey: key)
            handleSettingChange(with: key)
        default: break
        }
    }
    
    private func handleSettingChange(with key: String) {
        delegate?.statusMenuManager(self, changedMenuSettingWithKey: key)
        reloadMenuItems()
    }
}

protocol StatusMenuManagerDelegate: class {
    /// Called when a setting represented in the menu changes is changed.
    func statusMenuManager(_ manager: StatusMenuManager, changedMenuSettingWithKey key: String)
}
