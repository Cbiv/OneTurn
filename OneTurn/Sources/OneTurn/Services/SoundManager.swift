import AVFoundation

@MainActor
final class SoundManager {
    enum Effect {
        case commit
        case placement
        case objective
        case mirror
        case success
        case failure
        case milestone
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var started = false

    init() {
        engine.attach(player)
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play(_ effect: Effect, enabled: Bool) {
        guard enabled else { return }
        startIfNeeded()

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44_100
        guard let buffer = makeBuffer(for: effect, sampleRate: sampleRate) else { return }

        if !player.isPlaying {
            player.play()
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    private func startIfNeeded() {
        guard !started else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            started = true
        } catch {
            started = false
        }
    }

    private func makeBuffer(for effect: Effect, sampleRate: Double) -> AVAudioPCMBuffer? {
        let tone = toneProfile(for: effect)
        let frameCount = AVAudioFrameCount((tone.duration * sampleRate).rounded(.up))
        guard frameCount > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount
        let attackFrames = max(Int(sampleRate * 0.01), 1)
        let releaseFrames = max(Int(sampleRate * tone.duration * 0.75), 1)

        guard let channel = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / sampleRate
            let envelope: Double
            if frame < attackFrames {
                envelope = Double(frame) / Double(attackFrames)
            } else {
                let releaseProgress = Double(max(frame - attackFrames, 0)) / Double(releaseFrames)
                envelope = max(0, 1 - releaseProgress)
            }

            let wobble = sin(2 * .pi * tone.modulation * progress) * tone.detune
            let sample = sin(2 * .pi * (tone.frequency + wobble) * progress)
            channel[frame] = Float(sample * envelope * tone.volume)
        }

        return buffer
    }

    private func toneProfile(for effect: Effect) -> (frequency: Double, duration: Double, volume: Double, modulation: Double, detune: Double) {
        switch effect {
        case .commit:
            (320, 0.07, 0.08, 2, 1.5)
        case .placement:
            (460, 0.05, 0.06, 1.5, 1.2)
        case .objective:
            (620, 0.06, 0.05, 4, 2)
        case .mirror:
            (760, 0.07, 0.05, 6, 3.5)
        case .success:
            (560, 0.16, 0.08, 3, 2.5)
        case .failure:
            (210, 0.12, 0.07, 2, 1.5)
        case .milestone:
            (690, 0.18, 0.08, 5, 4)
        }
    }
}
