//
//  AppDelegate.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/30/21.
//

import Foundation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    func applicationWillFinishLaunching(_ notification: Notification) {
            NSWindow.allowsAutomaticWindowTabbing = false
    }
}
