//
//  Symbol_SelectorApp.swift
//  Symbol Selector
//
//  Created by Joseph Cestone on 4/3/22.
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    /// After Launch, customize the window to be transparent (ultrathin configured in Symbol\_SelectorApp)
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.toolbarStyle = .expanded
            window.isOpaque = false
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor.clear
            window.delegate = self
        }
    }
}

/// The Main of the App, adds App Delegate and ultrathin background
@main
struct Symbol_SelectorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            SymbolPickerView()
                .background(.ultraThinMaterial)
                .toolbar {
                    EmptyView()
                }
        }
    }
}

// MARK: Unneeded - Wrong Method for Blur

//struct VisualEffectView: NSViewRepresentable
//{
//    let material: NSVisualEffectView.Material
//    let blendingMode: NSVisualEffectView.BlendingMode
//
//    func makeNSView(context: Context) -> NSVisualEffectView
//    {
//        let visualEffectView = NSVisualEffectView()
//        visualEffectView.material = material
//        visualEffectView.blendingMode = blendingMode
//        visualEffectView.state = NSVisualEffectView.State.active
//        return visualEffectView
//    }
//
//    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context)
//    {
//        visualEffectView.material = material
//        visualEffectView.blendingMode = blendingMode
//    }
//}
