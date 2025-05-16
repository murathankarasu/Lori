import SwiftUI

struct PodcastLoadingView: View {
    let userID: String
    let username: String
    var onAudioReady: (String) -> Void
    @State private var currentLang: Int = 0
    @State private var isWaiting: Bool = true
    let waitMessages = [
        "Wait your feed", // English
        "Bekleyin, podcast'iniz hazırlanıyor", // Turkish
        "Espere su podcast", // Spanish
        "请稍候，您的播客正在生成" // Chinese
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                AnimatedText(text: waitMessages[currentLang])
                    .id(currentLang)
                    .foregroundColor(.white)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                Spacer()
            }
        }
        .onAppear {
            print("[PodcastLoadingView] userID: \(userID), username: \(username)")
            animateLanguages()
            generatePodcast()
        }
    }
    
    func animateLanguages() {
        guard isWaiting else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                currentLang = (currentLang + 1) % waitMessages.count
            }
            animateLanguages()
        }
    }
    
    func generatePodcast() {
        PodcastAudioService.shared.generateAudio(userID: userID, username: username) { result in
            DispatchQueue.main.async {
                isWaiting = false
                switch result {
                case .success(let response):
                    print("[PodcastLoadingView] public_url: \(response.public_url)")
                    onAudioReady(response.public_url)
                case .failure(let error):
                    print("[PodcastLoadingView] API Hatası: \(error.localizedDescription)")
                    onAudioReady("")
                }
            }
        }
    }
} 