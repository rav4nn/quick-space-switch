import ISS
import XCTest

@_silgen_name("iss_shortcut_direction")
private func iss_shortcut_direction(
  _ keycode: UInt16, _ flags: UInt64, _ outDirection: UnsafeMutablePointer<ISSDirection>
) -> Bool

private let leftArrow: UInt16 = 123
private let rightArrow: UInt16 = 124

// Flags captured on macOS 27.0.1 for the two real sources of Control+Arrow
private let logiOptionsFlags: UInt64 = 0x840000
private let physicalKeyboardFlags: UInt64 = 0xa40101

private let control = CGEventFlags.maskControl.rawValue
private let capsLock = CGEventFlags.maskAlphaShift.rawValue
private let numericPad = CGEventFlags.maskNumericPad.rawValue
private let secondaryFn = CGEventFlags.maskSecondaryFn.rawValue

private func direction(_ keycode: UInt16, _ flags: UInt64) -> ISSDirection? {
  var result = ISSDirectionLeft
  return iss_shortcut_direction(keycode, flags, &result) ? result : nil
}

final class ShortcutMatchTests: XCTestCase {
  func testLogiOptionsGestureSwitchesInItsDirection() {
    XCTAssertEqual(direction(leftArrow, logiOptionsFlags), ISSDirectionLeft)
    XCTAssertEqual(direction(rightArrow, logiOptionsFlags), ISSDirectionRight)
  }

  func testPhysicalKeyboardControlArrowSwitches() {
    XCTAssertEqual(direction(leftArrow, physicalKeyboardFlags), ISSDirectionLeft)
    XCTAssertEqual(direction(rightArrow, physicalKeyboardFlags), ISSDirectionRight)
  }

  func testCapsLockFnAndNumericPadBitsDoNotBlockAMatch() {
    let noise = capsLock | numericPad | secondaryFn
    XCTAssertEqual(direction(rightArrow, control | noise), ISSDirectionRight)
  }

  func testExtraCommandModifierIsNotTheShortcut() {
    for extra in [CGEventFlags.maskCommand, .maskAlternate, .maskShift] {
      XCTAssertNil(direction(rightArrow, logiOptionsFlags | extra.rawValue), "\(extra)")
      XCTAssertNil(direction(leftArrow, physicalKeyboardFlags | extra.rawValue), "\(extra)")
    }
  }

  func testArrowWithoutControlIsNotTheShortcut() {
    XCTAssertNil(direction(rightArrow, 0))
    XCTAssertNil(direction(rightArrow, numericPad | secondaryFn))
  }

  func testOtherKeysWithControlAreNotTheShortcut() {
    let upArrow: UInt16 = 126
    let downArrow: UInt16 = 125
    let letterA: UInt16 = 0
    for keycode in [upArrow, downArrow, letterA] {
      XCTAssertNil(direction(keycode, logiOptionsFlags), "keycode \(keycode)")
    }
  }
}
