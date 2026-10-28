import AppKit
import ApplicationServices
import Carbon

class HotKeyManager {
  static let shared = HotKeyManager()

  private struct Entry {
    let identifier: HotkeyIdentifier
    let combination: HotkeyCombination
    let handler: () -> Void
  }

  private var entries: [HotkeyIdentifier: Entry] = [:]
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?

  private init() {}

  func register(
    identifier: HotkeyIdentifier, combination: HotkeyCombination, handler: @escaping () -> Void
  ) {
    unregister(identifier: identifier)

    entries[identifier] = Entry(identifier: identifier, combination: combination, handler: handler)
  }

  func unregister(identifier: HotkeyIdentifier) {
    entries.removeValue(forKey: identifier)
  }

  func unregisterAll() {
    entries.removeAll()
  }

  /// Idempotent. EventTapGate calls this only while the app is trusted.
  func installEventTap() {
    if let eventTap {
      if CFMachPortIsValid(eventTap) {
        return
      }
      removeEventTap()
    }

    let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: { _, type, event, userInfo in
          guard let userInfo else { return Unmanaged.passUnretained(event) }
          let manager = Unmanaged<HotKeyManager>.fromOpaque(userInfo).takeUnretainedValue()

          if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = manager.eventTap, AXIsProcessTrusted() {
              CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
          }

          guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
          }

          if manager.dispatch(event: event) {
            return nil
          }
          return Unmanaged.passUnretained(event)
        },
        userInfo: Unmanaged.passUnretained(self).toOpaque()
      )
    else {
      return
    }

    self.eventTap = eventTap
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    if let runLoopSource {
      CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }
    CGEvent.tapEnable(tap: eventTap, enable: true)
  }

  /// Idempotent.
  func removeEventTap() {
    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      CFMachPortInvalidate(eventTap)
      self.eventTap = nil
    }
    if let runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
      self.runLoopSource = nil
    }
  }

  private func dispatch(event: CGEvent) -> Bool {
    let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))
    let rawFlags = event.flags.rawValue
    let selectedEntry = Self.preferredEntry(from: Array(entries.values), keyCode: keyCode, flags: rawFlags)

    if let selectedEntry {
      DispatchQueue.main.async {
        selectedEntry.handler()
      }
      return true
    }

    return false
  }

  static func preferredCombination(
    from combinations: [HotkeyCombination], keyCode: UInt32, eventModifierFlags flags: UInt64
  ) -> HotkeyCombination? {
    combinations.filter {
      $0.keyCode == keyCode && $0.matches(eventModifierFlags: flags)
    }.max {
      priority(for: $0) < priority(for: $1)
    }
  }

  private static func preferredEntry(
    from entries: [Entry], keyCode: UInt32, flags: UInt64
  ) -> Entry? {
    entries.filter {
      $0.combination.keyCode == keyCode && $0.combination.matches(eventModifierFlags: flags)
    }.max {
      priority(for: $0.combination) < priority(for: $1.combination)
    }
  }

  private static func priority(for combination: HotkeyCombination) -> Int {
    combination.optionKeyKind == .right ? 1 : 0
  }
}
