import SwiftUI

struct PodcastLoadingView: View {
    let userID: String
    let username: String
    var onAudioReady: (String) -> Void
    @State private var currentLang: Int = 0
    @State private var isWaiting: Bool = true
    @State private var loadingProgress: Double = 0.0
    @State private var loadingRotation: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showPulse = false
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var progressScale: CGFloat = 0.9
    
    let waitMessages = [
        "No one knows where Lori's first post went. It simply vanished.",
        "There's a hidden post that only appears when no one is watching.",
        "Lori's feed has a pulse. Some say it syncs with your mood.",
        "Every 1000th post is written in a language no one claims to know.",
        "Some users swear they've seen replies from people who don't exist.",
        "At 3:33 AM, Lori's interface shifts—just slightly.",
        "There's a room called 'The Archive'. Only Galadriel has the key.",
        "Once, a post predicted an event… three days before it happened.",
        "If you scroll backwards long enough, you might find yesterday's tomorrow.",
        "Lori doesn't store memories—she replays echoes."
    ]
    
    var body: some View {
        ZStack {
            // Siyah arka plan
            Color.black.ignoresSafeArea()
            
            // Gradient arka plan
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Spacer()
                
                // Modern yükleme animasyonu
                ZStack {
                    // Dış pulse efekti
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                            .scaleEffect(showPulse ? 1.1 : 0.9)
                            .opacity(showPulse ? 0.3 : 0.7)
                            .animation(
                                Animation.easeInOut(duration: 1.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.4),
                                value: showPulse
                            )
                    }
                    
                    // Orta halka - dönüş animasyonu
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.white.opacity(0.3)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(Angle(degrees: loadingRotation))
                        .onAppear {
                            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                                loadingRotation = 360
                            }
                        }
                    
                    // İç çember
                    Circle()
                        .fill(Color.black)
                        .frame(width: 75, height: 75)
                        .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 0)
                    
                    // Ses dalgası animasyonu
                    HStack(spacing: 4) {
                        ForEach(0..<5) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: 4, height: isWaiting ? CGFloat.random(in: 20...40) : 20)
                                .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isWaiting)
                        }
                    }
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulseScale = 1.1
                        }
                    }
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                        iconScale = 1.0
                        iconOpacity = 1
                        showPulse = true
                    }
                }
                
                // Yükleme mesajı
                Text(waitMessages[currentLang])
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 30)
                    .opacity(textOpacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
                            textOpacity = 1
                        }
                    }
                
                // İlerleme çubuğu
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.5), Color.white]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(CGFloat(loadingProgress) * UIScreen.main.bounds.width - 80, 0), height: 12)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: loadingProgress)
                    }
                    
                    HStack {
                        Text("Processing...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(Int(loadingProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .scaleEffect(progressScale)
                .opacity(textOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7)) {
                        progressScale = 1.0
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            print("[PodcastLoadingView] userID: \(userID), username: \(username)")
            animateLanguages()
            animateProgressBar()
            generatePodcast()
        }
    }
    
    func animateLanguages() {
        guard isWaiting else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                currentLang = (currentLang + 1) % waitMessages.count
            }
            animateLanguages()
        }
    }
    
    func animateProgressBar() {
        guard isWaiting else { return }
        
        // İlerleme çubuğunu daha yavaş arttır
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation {
                if loadingProgress < 0.95 {
                    // Daha yavaş bir hızda ilerleme
                    let increment = (1.0 - loadingProgress) * 0.04
                    loadingProgress += min(increment, 0.02)
                    animateProgressBar()
                }
            }
        }
    }
    
    func generatePodcast() {
        // İlk olarak ilerlemeyi başlat
        animateProgressBar()
        
        PodcastAudioService.shared.generateAudio(userID: userID, username: username) { result in
            DispatchQueue.main.async {
                // API yanıtı gelince ilerlemeyi %100 yap
                withAnimation(.easeInOut(duration: 1.5)) {
                    loadingProgress = 1.0
                }
                
                // Daha uzun bir gecikmeyle isWaiting'i false yap
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
} 