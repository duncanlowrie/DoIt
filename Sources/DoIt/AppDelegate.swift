import Cocoa
import SwiftUI
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let store = TodoStore()
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "DoIt")
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Popover hosting the SwiftUI view
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 448)
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(
            rootView: TodoListView().environmentObject(store)
        )

        // Global hotkey: ⌃⌥⌘T
        hotKey = HotKey(
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(controlKey | optionKey | cmdKey)
        ) { [weak self] in
            self?.togglePopover(nil)
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        // Right-click → show quit menu; left-click → toggle popover.
        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu()
        } else {
            togglePopover(sender)
        }
    }

    func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Ensure text field receives keystrokes immediately.
        popover.contentViewController?.view.window?.makeKey()
    }

    private func showStatusMenu() {
        guard let button = statusItem.button else { return }
        let menu = NSMenu()
        let quitItem = NSMenuItem(
            title: "Quit DoIt",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 4),
            in: button
        )
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
