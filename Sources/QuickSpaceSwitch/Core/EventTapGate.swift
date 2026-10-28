import AppKit
import ApplicationServices
import ISS

/// Keeps every event tap installed exactly while the app holds Accessibility trust.
///
/// An active keyboard tap that outlives its trust (the user unticks the app in
/// System Settings) stalls key delivery for the whole login session until the
/// process dies. Each reconcile reads the live trust value and converges the taps
/// to it, so a missed notification or a failed tap creation heals on the next tick.
final class EventTapGate {
  private static let trustChanged = Notification.Name("com.apple.accessibility.api")
  private static let pollInterval: TimeInterval = 1.0
  // TCC commits the new value shortly after it posts the notification
  private static let settleDelay: TimeInterval = 0.3

  private var timer: Timer?
  private var observer: NSObjectProtocol?

  func start() {
    guard timer == nil else { return }

    observer = DistributedNotificationCenter.default().addObserver(
      forName: Self.trustChanged, object: nil, queue: .main
    ) { [weak self] _ in
      self?.reconcile()
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.settleDelay) {
        self?.reconcile()
      }
    }

    let timer = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
      self?.reconcile()
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer

    reconcile()
  }

  func stop() {
    timer?.invalidate()
    timer = nil
    if let observer {
      DistributedNotificationCenter.default().removeObserver(observer)
      self.observer = nil
    }
    removeTaps()
  }

  private func reconcile() {
    if AXIsProcessTrusted() {
      _ = iss_init()
      HotKeyManager.shared.installEventTap()
    } else {
      removeTaps()
    }
  }

  private func removeTaps() {
    iss_destroy()
    HotKeyManager.shared.removeEventTap()
    GlobalEventTapRecorder.shared.stopRecording()
  }
}
