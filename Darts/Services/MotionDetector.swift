import Foundation
import CoreMotion
import Combine

final class MotionDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private var stillnessStart: Date?

    @Published var isStill: Bool = false
    @Published var hasBeenStillFor2Sec: Bool = false
    @Published var isMoving: Bool = false

    // Parameter — ggf. feinjustieren
    private let motionThreshold: Double = 0.08
    private let requiredStillnessTime: TimeInterval = 1.0

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.15

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let rotation = motion.rotationRate
            let accel = motion.userAcceleration

            let totalMotion = abs(rotation.x) + abs(rotation.y) + abs(rotation.z)
                            + abs(accel.x)    + abs(accel.y)    + abs(accel.z)

            if totalMotion < self.motionThreshold {
                if self.stillnessStart == nil {
                    self.stillnessStart = Date()
                } else if Date().timeIntervalSince(self.stillnessStart!) > self.requiredStillnessTime {
                    if !self.hasBeenStillFor2Sec {
                        self.hasBeenStillFor2Sec = true
                        NotificationCenter.default.post(name: .deviceWasStillFor2Sec, object: nil)
                    }
                }
                self.isStill = true
            } else {
                self.isStill = false
                self.hasBeenStillFor2Sec = false
                self.stillnessStart = nil
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        stillnessStart = nil
        hasBeenStillFor2Sec = false
        isStill = false
    }
}
