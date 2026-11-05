import AVFoundation
import PingCore

/// Plays the game's sound event for a ping: every voice (base file plus layers) with the event's volume and pitch.
final class PingAudio {
    struct Voice: Decodable { let event: String; let file: String; let volume: Float; let pitch: Float }
    struct Entry: Decodable { let wheelKey: String; let event: String }
    struct Catalog: Decodable { let pings: [String: Entry]; let events: [String: [Voice]] }
    enum Failure: Error { case missingResource(String), missingPing(String), emptyAudio(String) }

    private struct Channel { let player: AVAudioPlayerNode; let buffer: AVAudioPCMBuffer; let volume: Float }

    let engine = AVAudioEngine()
    let catalog: Catalog
    private var channels: [Ping: [Channel]] = [:]

    init(bundle: Bundle = .module, manualRenderingFormat: AVAudioFormat? = nil) throws {
        guard let url = bundle.url(forResource: "sound_events", withExtension: "json", subdirectory: "Sounds") else { throw Failure.missingResource("sound_events.json") }
        catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
        if let manualRenderingFormat { try engine.enableManualRenderingMode(.offline, format: manualRenderingFormat, maximumFrameCount: 4096) }
        var buffers: [String: AVAudioPCMBuffer] = [:]
        for ping in Ping.allCases {
            let name = String(describing: ping)
            guard let entry = catalog.pings[name], let voices = catalog.events[entry.event], !voices.isEmpty else { throw Failure.missingPing(name) }
            channels[ping] = try voices.map { voice in
                let buffer = try buffers[voice.file] ?? Self.decode(voice.file, bundle: bundle)
                buffers[voice.file] = buffer
                let player = AVAudioPlayerNode(), varispeed = AVAudioUnitVarispeed()
                varispeed.rate = voice.pitch
                engine.attach(player); engine.attach(varispeed)
                engine.connect(player, to: varispeed, format: buffer.format)
                engine.connect(varispeed, to: engine.mainMixerNode, format: buffer.format)
                return Channel(player: player, buffer: buffer, volume: voice.volume)
            }
        }
        engine.prepare()
    }

    private static func decode(_ file: String, bundle: Bundle) throws -> AVAudioPCMBuffer {
        let name = (file as NSString).deletingPathExtension, ext = (file as NSString).pathExtension
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Sounds") else { throw Failure.missingResource(file) }
        let audio = try AVAudioFile(forReading: url)
        guard audio.length > 0, let buffer = AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: AVAudioFrameCount(audio.length)) else { throw Failure.emptyAudio(file) }
        try audio.read(into: buffer)
        guard buffer.frameLength == AVAudioFrameCount(audio.length) else { throw Failure.emptyAudio(file) }
        return buffer
    }

    func event(for ping: Ping) -> String { catalog.pings[String(describing: ping)]!.event }

    func duration(of ping: Ping) -> TimeInterval {
        let voices = catalog.events[event(for: ping)] ?? []
        return zip(channels[ping, default: []], voices).map { Double($0.buffer.frameLength) / $0.buffer.format.sampleRate / Double($1.pitch) }.max() ?? 0
    }

    /// Restarts the ping's voices so a repeated ping retriggers instead of stacking; layers share one start time.
    func play(_ ping: Ping) {
        if !engine.isRunning { do { try engine.start() } catch { NSLog("DotaPing audio unavailable: \(error)"); return } }
        let voices = channels[ping, default: []]
        for channel in voices {
            channel.player.stop()
            channel.player.volume = channel.volume
            channel.player.scheduleBuffer(channel.buffer, at: nil, options: [])
        }
        let start = engine.isInManualRenderingMode ? nil : AVAudioTime(hostTime: mach_absolute_time() + AVAudioTime.hostTime(forSeconds: Self.startLead))
        for channel in voices { channel.player.play(at: start) }
    }

    func stop() {
        for channel in channels.values.joined() { channel.player.stop() }
    }

    private static let startLead: TimeInterval = 0.02

    /// Offline-renders a ping through the same graph; returns the peak sample. Requires manual rendering mode.
    func renderPeak(_ ping: Ping, seconds: Double) throws -> Float {
        play(ping)
        let format = engine.manualRenderingFormat
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: engine.manualRenderingMaximumFrameCount) else { return 0 }
        var remaining = AVAudioFramePosition(seconds * format.sampleRate), peak: Float = 0
        while remaining > 0 {
            let frames = AVAudioFrameCount(min(remaining, AVAudioFramePosition(output.frameCapacity)))
            guard try engine.renderOffline(frames, to: output) == .success else { break }
            for channel in 0..<Int(format.channelCount) {
                let samples = UnsafeBufferPointer(start: output.floatChannelData![channel], count: Int(output.frameLength))
                peak = max(peak, samples.map(abs).max() ?? 0)
            }
            remaining -= AVAudioFramePosition(output.frameLength)
        }
        stop()
        engine.stop()
        return peak
    }
}

extension PingAudio {
    /// Headless check for --self-test: renders every ping offline through the playback graph, without audible output.
    static func runSelfCheck() throws -> String {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        for ping in Ping.allCases {
            let audio = try PingAudio(manualRenderingFormat: format)
            let peak = try audio.renderPeak(ping, seconds: 0.6)
            guard peak > 0.01 else { throw Failure.emptyAudio(audio.event(for: ping)) }
        }
        let catalog = try PingAudio(manualRenderingFormat: format).catalog
        return "Bundled audio checks passed: \(Set(catalog.events.values.flatMap { $0.map(\.file) }).count) original WAVs, \(catalog.pings.count) pings rendered."
    }
}

