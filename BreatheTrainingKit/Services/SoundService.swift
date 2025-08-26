import Foundation
import AVFoundation

class SoundService: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var phasePlayer: AVAudioPlayer?
    
    func playBackgroundSound(_ sound: BreathingSound, volume: Double) {
        guard let url = Bundle.main.url(forResource: sound.filename, withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = Float(volume)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    func playPhaseSound(_ phase: BreathPhase) {
        guard let url = Bundle.main.url(forResource: "phase_\(phase.rawValue.lowercased())", withExtension: "mp3") else { return }
        
        do {
            phasePlayer = try AVAudioPlayer(contentsOf: url)
            phasePlayer?.play()
        } catch {
            print("Failed to play phase sound: \(error)")
        }
    }
    
    func stopBackgroundSound() {
        audioPlayer?.stop()
    }
    
    func stopPhaseSound() {
        phasePlayer?.stop()
    }
} 