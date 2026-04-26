import Foundation
import SwiftUI
import UIKit
import Combine
import AVFoundation

/// Zentrale Spiel- und Workflow-Logik.
///
/// Hält den `AppPhase`, alle Spielerstände, Scoring/Bust/Double-Out, Multi-Leg-Tracking
/// sowie Bridges zu CameraService, ServerClient, DartTracker und SpeechService.
@MainActor
final class GameEngine: ObservableObject {

    // MARK: - Phase / Setup
    @Published var phase: AppPhase = .permission
    @Published var setup = GameSetup()
    @Published var players: [Player] = []

    // MARK: - Laufender Zug
    @Published var currentPlayerIndex: Int = 0
    @Published var turnNumber: Int = 1
    @Published var currentTurnDarts: [DartData] = []
    @Published var currentTurnTotal: Int = 0
    /// Wenn != nil → BUST-Toast wird angezeigt.
    @Published var bustFlash: Bool = false
    /// Server-/Netz-Fehler-Banner.
    @Published var errorMessage: String? = nil

    // MARK: - Capture-Status (rein für UI-Anzeige)
    @Published var captureStatus: CaptureStatus = .idle

    // MARK: - Letzte Runde (für Korrektur)
    @Published private(set) var lastTurn: TurnSnapshot?

    // MARK: - Services
    let cameraService = CameraService()
    let speech = SpeechService()
    private let dartTracker = DartTracker()

    // MARK: - Internal
    private var turnStartScore: Int = 0
    private var isThrowBusted: Bool = false
    private var observers: [NSObjectProtocol] = []
    private var cancellables: Set<AnyCancellable> = []
    /// Bei sehr kurzer Stillstand-Phase mehrmals Capture in Folge auslösen ist okay,
    /// das DartTracker-Merge dedupliziert. Wir blockieren nur, während ein Upload läuft.
    private var isUploading: Bool = false

    init() {
        wireServices()
        // Re-publishen, wenn untergeordnete ObservableObjects sich ändern,
        // damit Views, die nur `engine` beobachten, ein Re-Render bekommen.
        cameraService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        speech.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    deinit {
        for o in observers { NotificationCenter.default.removeObserver(o) }
    }

    // MARK: - Service-Bridges

    private func wireServices() {
        cameraService.canCapture = { [weak self] in
            guard let self else { return false }
            return !self.speech.isSpeaking && !self.isUploading && self.phase == .playing
        }
        cameraService.photoHandler = { [weak self] image in
            self?.handleCapturedPhoto(image)
        }

        // Fortlaufender Status aus Motion-Detector → captureStatus
        let still = NotificationCenter.default.addObserver(
            forName: .deviceWasStillFor2Sec, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.phase == .playing, !self.isUploading else { return }
                self.captureStatus = .ready
            }
        }
        observers.append(still)
    }

    // MARK: - Setup-Phase

    func addPlayer(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              players.count < 4,
              !players.contains(where: { $0.name.lowercased() == trimmed.lowercased() })
        else { return }
        players.append(Player(name: trimmed))
    }

    func removePlayer(at index: Int) {
        guard players.indices.contains(index) else { return }
        players.remove(at: index)
    }

    func setMode(_ mode: GameMode)   { setup.mode = mode }
    func setLegs(_ n: Int)           { setup.legsToPlay = n }

    func goToMode()                  { phase = .mode }
    func goToCalibration()           { phase = .calibration }

    // MARK: - Calibration

    /// Wird von der CalibrationView aufgerufen. Macht ein einzelnes Bild und probiert
    /// es beim Server (ohne Keypoints), bis valide Keypoints zurückkommen.
    /// `completion(true)` wenn Kalibrierung erfolgreich, `completion(false)` bei Fehler.
    func runServerCalibration(_ completion: @escaping (Bool) -> Void) {
        cameraService.captureOnce { [weak self] image in
            guard let self, let image else {
                completion(false); return
            }
            Task { @MainActor in
                do {
                    let resp = try await ServerClient.shared.upload(image: image, keypoints: nil)
                    if let kp = Keypoints(server: resp.keypoints) {
                        self.setup.keypoints = kp
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    self.errorMessage = (error as? ServerError)?.errorDescription ?? "Kalibrierung fehlgeschlagen."
                    completion(false)
                }
            }
        }
    }

    // MARK: - Spiel starten

    func startGame() {
        let base = setup.mode.startScore
        for i in players.indices {
            players[i].rest = base
            players[i].legWins = 0
            players[i].turnTotals = []
        }
        currentPlayerIndex = 0
        turnNumber = 1
        currentTurnDarts = []
        currentTurnTotal = 0
        turnStartScore = base
        isThrowBusted = false
        lastTurn = nil
        dartTracker.reset()
        dartTracker.clearIgnored()
        phase = .playing
        cameraService.start()
        captureStatus = .stilling
    }

    func forfeit() {
        cameraService.stop()
        speech.stop()
        captureStatus = .idle
        phase = .players
        players = []
        setup = GameSetup()
    }

    func togglePause() {
        if cameraService.isRunning {
            cameraService.stop()
            captureStatus = .idle
        } else {
            cameraService.start()
            captureStatus = .stilling
        }
    }

    func recalibrate() {
        cameraService.stop()
        captureStatus = .idle
        setup.keypoints = nil
        dartTracker.reset()
        currentTurnDarts = []
        currentTurnTotal = 0
        phase = .calibration
    }

    /// Manueller Scan-Override (Mockup-Button "Foto analysieren").
    func triggerManualScan() {
        guard phase == .playing, !isUploading else { return }
        cameraService.captureNow()
    }

    // MARK: - Capture → Upload → Merge

    private func handleCapturedPhoto(_ image: UIImage) {
        isUploading = true
        captureStatus = .uploading
        errorMessage = nil

        Task { @MainActor in
            do {
                let resp = try await ServerClient.shared.upload(image: image, keypoints: setup.keypoints)
                handleServerResponse(resp)
            } catch {
                let msg = (error as? ServerError)?.errorDescription ?? error.localizedDescription
                errorMessage = msg
            }
            isUploading = false
            if phase == .playing {
                captureStatus = cameraService.motionDetector.hasBeenStillFor2Sec ? .ready : .stilling
            }
        }
    }

    private func handleServerResponse(_ response: ServerResponse) {
        // Keypoints sichern, falls Calibration sie nicht schon gesetzt hat.
        if setup.keypoints == nil, let kp = Keypoints(server: response.keypoints) {
            setup.keypoints = kp
        }

        let countBefore = dartTracker.getHistoryCount()
        let result = dartTracker.merge(with: response.darts, isBusted: isThrowBusted)

        switch result {
        case .sameRound:
            // Kein neuer Dart erkannt — entweder noch dieselbe Runde oder Server hat Pfeile alt erkannt.
            return
        case .update(let currentDarts):
            guard currentDarts.count > countBefore else { return }
            for i in countBefore..<currentDarts.count {
                let newDart = currentDarts[i]
                let dartIndex = i // 0,1,2
                if dartIndex < 2 {
                    applyDart(newDart, isFinal: false)
                } else {
                    applyDart(newDart, isFinal: true)
                }
            }
        }
    }

    // MARK: - Scoring (entspricht ContentView.thrown / handleTurnFinished)

    private func applyDart(_ dart: DartData, isFinal: Bool) {
        guard players.indices.contains(currentPlayerIndex) else { return }
        currentTurnDarts.append(dart)
        currentTurnTotal += dart.score

        let player = players[currentPlayerIndex]
        let currentRest = player.rest
        let newRest = currentRest - currentTurnTotal

        if isFinal {
            speech.stop()
        }

        // Fall 1: Bust (überworfen)
        if newRest < 0 {
            registerBust()
            return
        }
        // Fall 2: Win mit Double-Out-Check
        if newRest == 0 && setup.doubleOut {
            if dart.multiplier == .double || dart.multiplier == .bull {
                registerLegWin()
            } else {
                registerBust(reason: "Single — Double-Out!")
            }
            return
        }
        // Fall 3: Win ohne Double-Out
        if newRest == 0 && !setup.doubleOut {
            registerLegWin()
            return
        }
        // Fall 4: weiterspielen
        if isFinal {
            // Runde regulär abschließen
            players[currentPlayerIndex].rest = newRest
            players[currentPlayerIndex].turnTotals.append(currentTurnTotal)
            lastTurn = TurnSnapshot(
                playerIndex: currentPlayerIndex,
                scoreThrown: currentTurnTotal,
                previousRest: currentRest,
                isWin: false,
                isBust: false,
                previousLegWins: players[currentPlayerIndex].legWins
            )
            speech.speak("Rest \(newRest)")
            advanceToNextPlayer()
        }
    }

    private func registerBust(reason: String = "Überworfen") {
        let idx = currentPlayerIndex
        let prevRest = players[idx].rest
        // Score zurücksetzen — Rest bleibt wie vor der Runde
        isThrowBusted = true
        bustFlash = true
        speech.stop()
        speech.speak(reason)

        lastTurn = TurnSnapshot(
            playerIndex: idx,
            scoreThrown: currentTurnTotal,
            previousRest: prevRest,
            isWin: false,
            isBust: true,
            previousLegWins: players[idx].legWins
        )

        // Bust-Toast 1.2s anzeigen, dann nächster Spieler
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            self.bustFlash = false
            self.advanceToNextPlayer()
            self.isThrowBusted = false
        }
    }

    private func registerLegWin() {
        let idx = currentPlayerIndex
        let prevRest = players[idx].rest
        let prevLegs = players[idx].legWins
        players[idx].rest = 0
        players[idx].legWins += 1
        players[idx].turnTotals.append(currentTurnTotal)

        lastTurn = TurnSnapshot(
            playerIndex: idx,
            scoreThrown: currentTurnTotal,
            previousRest: prevRest,
            isWin: true,
            isBust: false,
            previousLegWins: prevLegs
        )
        speech.speak("Sieg \(players[idx].name)")

        let winnerName = players[idx].name
        if players[idx].legWins >= setup.legsToWin {
            cameraService.stop()
            captureStatus = .idle
            phase = .won(winner: winnerName)
        } else {
            phase = .legTransition(winner: winnerName, leg: players[idx].legWins)
            // Auto-dismiss nach 2.4s
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                if case .legTransition = self.phase {
                    self.startNextLeg()
                }
            }
        }
    }

    /// Wird vom LegTransition-Tap oder Auto-Timer gerufen.
    func startNextLeg() {
        let base = setup.mode.startScore
        for i in players.indices {
            players[i].rest = base
        }
        currentPlayerIndex = 0
        turnNumber = 1
        currentTurnDarts = []
        currentTurnTotal = 0
        turnStartScore = base
        isThrowBusted = false
        dartTracker.reset()
        dartTracker.clearIgnored()
        phase = .playing
    }

    private func advanceToNextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % max(players.count, 1)
        if currentPlayerIndex == 0 { turnNumber += 1 }
        currentTurnDarts = []
        currentTurnTotal = 0
        turnStartScore = players[currentPlayerIndex].rest
    }

    // MARK: - Score-Korrektur (3 Darts × Multiplier)

    /// Übernimmt eine 3-Dart-Korrektur für die *letzte* abgeschlossene Runde.
    /// Validiert Bust / Double-Out anhand des letzten Darts.
    func correctLastTurn(darts corrections: [(value: Int, multiplier: DartData.Multiplier)]) {
        guard let last = lastTurn else { return }
        let idx = last.playerIndex
        guard players.indices.contains(idx) else { return }

        let total = corrections.reduce(0) { $0 + $1.value }
        let oldRest = last.previousRest
        let newRest = oldRest - total

        // Vorigen Effekt rückgängig machen
        players[idx].rest = oldRest
        if last.isWin {
            players[idx].legWins = last.previousLegWins
        }
        if !last.turnTotalsHadFlush {
            // turnTotals war ggf. ergänzt → letzten Eintrag zurücknehmen
            if !last.isBust, let lastIndex = players[idx].turnTotals.indices.last {
                _ = players[idx].turnTotals.remove(at: lastIndex)
            }
        }

        // Neue Regeln anwenden
        let lastMul = corrections.last?.multiplier ?? .single
        if newRest < 0 {
            // Bust durch Korrektur
            // Rest bleibt = oldRest (wie vor der Runde)
            lastTurn = TurnSnapshot(
                playerIndex: idx,
                scoreThrown: total,
                previousRest: oldRest,
                isWin: false,
                isBust: true,
                previousLegWins: players[idx].legWins
            )
            speech.speak("Korrigiert: Überworfen")
        } else if newRest == 0 {
            let validDouble = !setup.doubleOut || lastMul == .double || lastMul == .bull
            if validDouble {
                players[idx].rest = 0
                players[idx].legWins += 1
                players[idx].turnTotals.append(total)
                lastTurn = TurnSnapshot(
                    playerIndex: idx,
                    scoreThrown: total,
                    previousRest: oldRest,
                    isWin: true,
                    isBust: false,
                    previousLegWins: players[idx].legWins - 1
                )
                let winnerName = players[idx].name
                if players[idx].legWins >= setup.legsToWin {
                    cameraService.stop()
                    captureStatus = .idle
                    phase = .won(winner: winnerName)
                } else {
                    phase = .legTransition(winner: winnerName, leg: players[idx].legWins)
                }
                speech.speak("Korrigiert: Sieg")
            } else {
                // Single auf Checkout → Bust
                lastTurn = TurnSnapshot(
                    playerIndex: idx,
                    scoreThrown: total,
                    previousRest: oldRest,
                    isWin: false,
                    isBust: true,
                    previousLegWins: players[idx].legWins
                )
                speech.speak("Korrigiert: Single — Überworfen")
            }
        } else {
            players[idx].rest = newRest
            players[idx].turnTotals.append(total)
            lastTurn = TurnSnapshot(
                playerIndex: idx,
                scoreThrown: total,
                previousRest: oldRest,
                isWin: false,
                isBust: false,
                previousLegWins: players[idx].legWins
            )
            speech.speak("Korrigiert: Rest \(newRest)")
        }
    }

    // MARK: - Helpers für Views

    var checkoutForCurrentPlayer: String? {
        guard players.indices.contains(currentPlayerIndex) else { return nil }
        return Checkout.suggestion(for: players[currentPlayerIndex].rest)
    }

    /// Setzt `phase` auf `.players`, wenn Kamera-Permission bereits erteilt ist.
    func bootstrapAfterPermissionCheck() {
        let status = CameraService.cameraAuthorizationStatus()
        if status == .authorized {
            phase = .players
        } else {
            phase = .permission
        }
    }

    func backToSetup() {
        cameraService.stop()
        speech.stop()
        captureStatus = .idle
        players = []
        setup = GameSetup()
        currentPlayerIndex = 0
        turnNumber = 1
        currentTurnDarts = []
        currentTurnTotal = 0
        lastTurn = nil
        dartTracker.reset()
        dartTracker.clearIgnored()
        phase = .players
    }
}

private extension TurnSnapshot {
    /// Marker, ob `turnTotals` schon befüllt wurde (Wins + reguläre Runden ja, Busts nein).
    /// Aktuell rein heuristisch: bei Bust nicht angefügt, sonst doch.
    var turnTotalsHadFlush: Bool { isBust }
}
