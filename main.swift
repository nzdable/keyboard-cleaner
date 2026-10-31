import Cocoa

var tap: CFMachPort?

// Swallow every event the tap sees. Re-enable the tap if macOS turns it off.
func callback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    return nil
}

// keyDown, keyUp, modifier keys, media/brightness keys
let keyboardMask: CGEventMask = (1 << 10) | (1 << 11) | (1 << 12) | (1 << 14)
// clicks, moves, drags, scroll, and trackpad gestures (pinch, swipe, rotate, force click)
let trackpadMask: CGEventMask = [1, 2, 3, 4, 5, 6, 7, 18, 19, 20, 22, 25, 26, 27, 29, 30, 31, 32, 34]
    .reduce(0) { $0 | (1 << $1) }
let trackpadSeconds = 30

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let label = NSTextField(labelWithString: "")
    let button = NSButton(title: "", target: nil, action: nil)
    let allButton = NSButton(title: "Lock Keyboard + Trackpad (\(trackpadSeconds)s)", target: nil, action: nil)
    var timer: Timer?
    var secondsLeft = 0
    let cat = NSImageView()
    let idleImage = Bundle.main.image(forResource: "cat") ?? NSImage()
    // NSImageView plays animated GIFs natively; shown only while locked.
    let lockedImage = Bundle.main.image(forResource: "lock") ?? NSImage()

    func applicationDidFinishLaunching(_ n: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 180),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Keyboard Cleaner"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.alignment = .center
        for (b, action) in [(button, #selector(toggle)), (allButton, #selector(lockAll))] {
            b.target = self
            b.action = action
            b.bezelStyle = .rounded
            b.controlSize = .large
        }
        cat.animates = true
        cat.imageScaling = .scaleProportionallyUpOrDown
        cat.widthAnchor.constraint(equalToConstant: 280).isActive = true
        cat.heightAnchor.constraint(equalToConstant: 280).isActive = true
        let stack = NSStackView(views: [cat, label, button, allButton])
        stack.orientation = .vertical
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 32, bottom: 28, right: 32)
        window.contentView = stack
        update()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func update() {
        if timer != nil {
            label.stringValue = "🐾 All LOCKED, unlocks in \(secondsLeft)s"
        } else {
            label.stringValue = tap == nil ? "🐱 Paws on the keys" : "🐾 Keyboard LOCKED, clean away"
        }
        button.title = tap == nil ? "Lock Keyboard" : "Unlock (click with mouse)"
        cat.image = tap == nil ? idleImage : lockedImage
        button.isHidden = timer != nil
        allButton.isHidden = tap != nil
    }

    func startTap(_ mask: CGEventMask) -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(opts) else {
            label.stringValue = "Allow Accessibility, then retry"
            return false
        }
        guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                        options: .defaultTap, eventsOfInterest: mask,
                                        callback: callback, userInfo: nil) else {
            label.stringValue = "Could not lock keyboard"
            return false
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, t, 0), .commonModes)
        tap = t
        return true
    }

    func stopTap() {
        guard let t = tap else { return }
        CGEvent.tapEnable(tap: t, enable: false)
        CFMachPortInvalidate(t)
        tap = nil
    }

    @objc func toggle() {
        if tap != nil { stopTap() } else if !startTap(keyboardMask) { return }
        update()
    }

    // The trackpad is locked too, so nothing can click Unlock: always unlock on a timer.
    @objc func lockAll() {
        guard startTap(keyboardMask | trackpadMask) else { return }
        CGAssociateMouseAndMouseCursorPosition(0)  // freeze the pointer
        secondsLeft = trackpadSeconds
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            self.secondsLeft -= 1
            if self.secondsLeft <= 0 {
                t.invalidate()
                self.timer = nil
                self.stopTap()
                CGAssociateMouseAndMouseCursorPosition(1)
            }
            self.update()
        }
        update()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
