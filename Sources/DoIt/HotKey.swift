import Carbon.HIToolbox
import Foundation

/// Thin wrapper around Carbon's RegisterEventHotKey. Does not require
/// Accessibility permission (unlike NSEvent global monitors).
final class HotKey {
    private var ref: EventHotKeyRef?
    private let id: UInt32

    private static var handlers: [UInt32: () -> Void] = [:]
    private static var nextID: UInt32 = 1
    private static var installed = false

    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        Self.installHandlerIfNeeded()
        self.id = Self.nextID
        Self.nextID += 1
        Self.handlers[self.id] = handler

        let hotKeyID = EventHotKeyID(signature: 0x444F4954 /* 'DOIT' */, id: self.id)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        Self.handlers[id] = nil
    }

    private static func installHandlerIfNeeded() {
        guard !installed else { return }
        installed = true

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                guard let event else { return noErr }
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr,
                      let handler = HotKey.handlers[hotKeyID.id] else { return noErr }
                DispatchQueue.main.async { handler() }
                return noErr
            },
            1,
            &spec,
            nil,
            nil
        )
    }
}
