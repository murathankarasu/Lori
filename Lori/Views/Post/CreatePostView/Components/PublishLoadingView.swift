import SwiftUI

struct PublishLoadingView: View {
    enum PublishStatus {
        case loading
        case success
        case failure
    }
    
    @Binding var status: PublishStatus
    @Binding var isPresented: Bool
    var errorMessage: String
    
    @State private var loadingProgress: Double = 0.0
    @State private var loadingRotation: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showPulse = false
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var resultIconScale: CGFloat = 0.0
    @State private var resultTextOpacity: Double = 0.0
    @State private var loadingOpacity: Double = 1.0
    @State private var resultOpacity: Double = 0.0
    
    // Animasyon zamanlaması için
    @State private var showResult = false
    
    var body: some View {
        ZStack {
            // Arka plan - tamamen opak ve tam ekran
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    if status != .loading {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    // Yükleme animasyonu
                    loadingAnimation
                        .padding(.bottom, 30)
                        .padding(.top, 50)
                        .opacity(loadingOpacity)
                    
                    // Sonuç animasyonu
                    resultAnimation
                        .padding(.bottom, 30)
                        .opacity(resultOpacity)
                }
                
                // Text alanı
                ZStack {
                    if status == .loading {
                        Text("Publishing your post...")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 15)
                            .opacity(textOpacity * loadingOpacity)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
                                    textOpacity = 1
                                }
                            }
                    } else if status == .success {
                        Text("Successfully posted!")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 15)
                            .opacity(resultTextOpacity)
                    } else {
                        VStack(spacing: 10) {
                            Text("Post not published")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(errorMessage)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .opacity(resultTextOpacity)
                    }
                }
                
                // Yükleme çubuğu - sadece loading durumunda
                if status == .loading {
                    loadingProgressView
                        .padding(.top, 20)
                        .padding(.horizontal, 40)
                        .opacity(textOpacity * loadingOpacity)
                }
                
                Spacer()
                
                // Kapatma butonu - sadece success veya failure durumunda
                if status != .loading {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Text(status == .success ? "Continue" : "Try Again")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 50)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.white)
                            )
                    }
                    .opacity(resultTextOpacity)
                    .padding(.bottom, 30)
                }
            }
            .padding()
        }
        .onAppear {
            // Yükleme başladığında ilerleme çubuğunu animeyi başlat
            if status == .loading {
                startLoadingAnimation()
            }
        }
        .onChange(of: status) { newStatus in
            // Durum değiştiğinde gerekli animasyonları göster
            if newStatus != .loading {
                // Önce ilerleme çubuğunun %100'e ulaşmasını sağla
                withAnimation(.easeInOut(duration: 0.5)) {
                    loadingProgress = 1.0
                }
                
                // Yumuşak geçiş için önce yükleme içeriğini kademeli olarak görünmez yap
                withAnimation(.easeInOut(duration: 0.6)) {
                    loadingOpacity = 0
                }
                
                // Sonra sonuç animasyonlarını göster
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showResult = true
                        resultIconScale = 1.0
                        resultOpacity = 1.0
                        resultTextOpacity = 1.0
                    }
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(status == .loading)
    }
    
    // MARK: - Görünümler
    
    // Yükleme animasyonu
    private var loadingAnimation: some View {
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
            
            // İçerik ikonu
            Image(systemName: "doc.text")
                .font(.system(size: 30))
                .foregroundColor(.white)
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
    }
    
    // Sonuç animasyonu
    private var resultAnimation: some View {
        ZStack {
            // Arka plan çember
            Circle()
                .fill(status == .success ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .frame(width: 130, height: 130)
            
            // Ön plan çember
            Circle()
                .fill(status == .success ? Color.green : Color.red)
                .frame(width: 100, height: 100)
                .shadow(color: status == .success ? Color.green.opacity(0.5) : Color.red.opacity(0.5),
                        radius: 10, x: 0, y: 0)
            
            // İkon
            Image(systemName: status == .success ? "checkmark" : "exclamationmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(resultIconScale)
    }
    
    // İlerleme çubuğu
    private var loadingProgressView: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.5), Color.white]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(CGFloat(loadingProgress) * UIScreen.main.bounds.width - 80, 0), height: 8)
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
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    private func startLoadingAnimation() {
        // İlerleme çubuğu animasyonu başlat
        loadingProgress = 0.0
        animateProgressBar()
    }
    
    private func animateProgressBar() {
        guard status == .loading else { return }
        
        // Daha akıcı ve gerçekçi animasyon için
        withAnimation(.easeInOut(duration: 0.4)) {
            if loadingProgress < 0.95 {
                // Yavaşlayan bir ilerleme - başta hızlı, sona doğru yavaş
                let targetProgress = min(loadingProgress + 0.05 + (0.2 * (1.0 - loadingProgress)), 0.95)
                loadingProgress = targetProgress
                
                // Bir sonraki güncellemeyi zamanla
                let nextDelay = 0.3 + (loadingProgress * 0.7) // Daha ilerledikçe daha yavaş güncellenir
                DispatchQueue.main.asyncAfter(deadline: .now() + nextDelay) {
                    animateProgressBar()
                }
            }
        }
    }
}

#Preview {
    PublishLoadingView(
        status: .constant(.loading),
        isPresented: .constant(true),
        errorMessage: "Your message contains inappropriate content that violates our community guidelines."
    )
}

#Preview {
    PublishLoadingView(
        status: .constant(.success),
        isPresented: .constant(true),
        errorMessage: ""
    )
}

#Preview {
    PublishLoadingView(
        status: .constant(.failure),
        isPresented: .constant(true),
        errorMessage: "Your message contains inappropriate content that violates our community guidelines."
    )
} 