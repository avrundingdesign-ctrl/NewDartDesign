import Foundation
import AVFoundation
import UIKit
import Combine

/// AVCaptureSession-Wrapper. Steuert nur Kamera-Hardware + Capture-Trigger.
/// Game-Logik / Server-Upload sind woanders (GameEngine / ServerClient).
@MainActor
final class CameraService: NSObject, ObservableObject {

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var captureTimer: Timer?
    private var isCapturingNow = false

    let motionDetector = MotionDetector()

    /// Wird aufgerufen, wenn ein neues Foto da ist.
    var photoHandler: ((UIImage) -> Void)?

    /// Externes Gating (z.B. "TTS läuft gerade" oder "Spiel pausiert").
    var canCapture: () -> Bool = { true }

    @Published private(set) var isRunning = false

    // MARK: - Permission

    static func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestCameraAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    // MARK: - Konfiguration

    func configure() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("❌ Kamera konnte nicht initialisiert werden.")
            return
        }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
    }

    // MARK: - Start / Stop

    func start() {
        configure()
        if !session.isRunning {
            // startRunning ist ein blockierender Call → in den Hintergrund
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                Task { @MainActor [weak self] in
                    self?.isRunning = true
                }
            }
        } else {
            isRunning = true
        }
        motionDetector.startMonitoring()
        startCaptureTimer()
    }

    func stop() {
        captureTimer?.invalidate()
        captureTimer = nil
        isCapturingNow = false
        motionDetector.stopMonitoring()
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
                Task { @MainActor [weak self] in
                    self?.isRunning = false
                }
            }
        } else {
            isRunning = false
        }
    }

    /// Erzwingt sofort einen Capture (manueller Override-Button).
    func captureNow() {
        guard !isCapturingNow else { return }
        isCapturingNow = true
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    /// Schießt ein einzelnes Bild ohne Auto-Loop (für Calibration-Probe).
    func captureOnce(_ completion: @escaping (UIImage?) -> Void) {
        configure()
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                Task { @MainActor [weak self] in
                    self?.isRunning = true
                    self?.singleCapture(completion)
                }
            }
        } else {
            singleCapture(completion)
        }
    }

    private func singleCapture(_ completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        let delegate = SingleShotDelegate(completion: completion)
        // Delegate retainen, sonst wird er vor dem Callback freigegeben
        self.singleShotDelegate = delegate
        output.capturePhoto(with: settings, delegate: delegate)
    }

    private var singleShotDelegate: SingleShotDelegate?

    // MARK: - Capture-Loop

    private func startCaptureTimer() {
        captureTimer?.invalidate()
        captureTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.canCapture() else { return }
                guard self.motionDetector.hasBeenStillFor2Sec else { return }
                guard !self.isCapturingNow else { return }
                self.captureNow()
            }
        }
    }
}

// MARK: - Photo-Delegate (Auto-Loop)
extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        Task { @MainActor in
            defer { self.isCapturingNow = false }
            if let error {
                print("❌ Fotoverarbeitung fehlgeschlagen:", error.localizedDescription)
                return
            }
            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                return
            }
            self.photoHandler?(image)
        }
    }
}

// MARK: - Single-Shot-Delegate (Calibration)
private final class SingleShotDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void
    init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let _ = error {
            DispatchQueue.main.async { self.completion(nil) }
            return
        }
        let img = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        DispatchQueue.main.async { self.completion(img) }
    }
}
