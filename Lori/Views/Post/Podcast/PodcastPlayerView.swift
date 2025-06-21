import SwiftUI
import AVKit

struct PodcastPlayerView: View {
    let audioURL: String
    @State private var player: AVPlayer? = nil
    @State private var isPlaying: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showReadyText: Bool = false
    @State private var readyText: String = ""
    @State private var isDismissed: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()
                VStack {
                    Spacer()
                    if showReadyText {
                        AnimatedText(text: "Your podcast is ready", animate: true)
                            .foregroundColor(.white)
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    if let player = player {
                        PlayerControlBar(player: player, isPlaying: $isPlaying)
                            .padding(.top, 40)
                            .padding(.horizontal, 32)
                    } else {
                        Text("Audio file could not be loaded.")
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear {
            if let url = URL(string: audioURL) {
                let newPlayer = AVPlayer(url: url)
                player = newPlayer
                isPlaying = true
                newPlayer.play()
            }
            showReadyText = true
        }
        .onDisappear {
            player?.pause()
            player = nil
            showReadyText = false
        }
    }
}

struct PlayerControlBar: View {
    let player: AVPlayer
    @Binding var isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 40) {
            Button(action: {
                seek(by: -10)
            }) {
                Image(systemName: "gobackward.10")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
            }
            Button(action: {
                if isPlaying {
                    player.pause()
                } else {
                    player.play()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.white)
            }
            Button(action: {
                seek(by: 10)
            }) {
                Image(systemName: "goforward.10")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func seek(by seconds: Double) {
        guard let currentItem = player.currentItem else { return }
        let currentTime = player.currentTime().seconds
        let newTime = max(currentTime + seconds, 0)
        let time = CMTime(seconds: newTime, preferredTimescale: currentItem.currentTime().timescale)
        player.seek(to: time)
    }
}

struct AudioPlayerView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.showsPlaybackControls = true
        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
} 