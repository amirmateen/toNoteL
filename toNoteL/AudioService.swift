import SwiftUI
import AVFoundation

// MARK: - AudioService

class AudioService: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession
    private var recordingTimer: Timer?
    private var currentRecordingURL: URL?

    @Published var recordingTime: TimeInterval = 0.0
    @Published var isRecording = false
    @Published var currentlyPlayingData: Data? = nil
    
    var onPlaybackFinished: (() -> Void)?

    init() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { _ in }
        } catch { print("Failed to set up recording session: \(error)") }
    }

    func startRecording() {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        currentRecordingURL = audioFilename
        let settings = [ AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            withAnimation { isRecording = true }
            recordingTime = 0.0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.recordingTime += 0.1 }
        } catch { print("Could not start recording: \(error)") }
    }

    func stopRecording(completion: @escaping (Data?, TimeInterval?) -> Void) {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        let duration = recordingTime
        guard let url = currentRecordingURL, let data = try? Data(contentsOf: url) else {
            completion(nil, nil)
            return
        }
        withAnimation { isRecording = false }
        completion(data, duration)
    }
    
    func forceStopRecording() {
        if isRecording {
            audioRecorder?.stop()
            recordingTimer?.invalidate()
            withAnimation { isRecording = false }
        }
    }

    func togglePlayback(for data: Data) {
        if isPlaying(data: data) { stopPlayback() } else { playRecording(data: data) }
    }
    
    func isPlaying(data: Data) -> Bool {
        return currentlyPlayingData == data
    }

    private func playRecording(data: Data) {
        stopPlayback()
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = RecordingDelegate.shared
            RecordingDelegate.shared.onPlaybackFinished = { [weak self] in self?.stopPlayback() }
            audioPlayer?.play()
            currentlyPlayingData = data
        } catch { print("Could not play recording: \(error)") }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentlyPlayingData = nil
    }
}

class RecordingDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = RecordingDelegate()
    var onPlaybackFinished: (() -> Void)?
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onPlaybackFinished?() }
}

