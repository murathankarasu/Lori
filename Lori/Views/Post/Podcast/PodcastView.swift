import SwiftUI
import FirebaseFirestore

struct PodcastView: View {
    let userID: String
    let username: String // Bu sadece fallback için, Firestore'dan çekilecek
    @Environment(\.presentationMode) var presentationMode
    @State private var step: Int = 0
    @State private var showButton: Bool = false
    @State private var isActive: Bool = true
    @State private var showLoading: Bool = false
    @State private var audioURL: String? = nil
    @State private var fetchedUsername: String? = nil
    @State private var isLoadingUsername: Bool = true
    
    let messages = [
        "Turn your thoughts into sound",
        "Lori Postcast — where imagination speaks."
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if showLoading {
                if let audioURL = audioURL {
                    PodcastPlayerView(audioURL: audioURL)
                } else {
                    PodcastLoadingView(userID: userID, username: fetchedUsername ?? username) { url in
                        self.audioURL = url
                    }
                    .id(UUID())
                }
            } else {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                        .padding(.top, 28)
                }
                .zIndex(2)
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        ForEach(0..<step, id: \.self) { i in
                            AnimatedText(text: messages[i], animate: false)
                                .foregroundColor(.white)
                                .font(.title)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        if step < messages.count {
                            AnimatedText(text: messages[step], animate: true)
                                .foregroundColor(.white)
                                .font(.title)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .id(step)
                        }
                    }
                    if showButton {
                        Button(action: {
                            withAnimation {
                                showLoading = true
                            }
                        }) {
                            if isLoadingUsername {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 40)
                            } else {
                                Text("Start")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .disabled(isLoadingUsername)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            isActive = true
            step = 0
            showButton = false
            showLoading = false
            audioURL = nil
            fetchUsernameFromFirestore()
            animateSteps()
        }
        .onDisappear {
            isActive = false
        }
    }
    
    func animateSteps() {
        guard isActive else { return }
        if step < messages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    step += 1
                }
                animateSteps()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation {
                    showButton = true
                }
            }
        }
    }
    
    func fetchUsernameFromFirestore() {
        isLoadingUsername = true
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let data = snapshot?.data(), let uname = data["username"] as? String {
                self.fetchedUsername = uname
            }
            self.isLoadingUsername = false
        }
    }
}

struct AnimatedText: View {
    let text: String
    var animate: Bool = true
    @State private var displayed: String = ""
    
    var body: some View {
        Text(displayed)
            .onAppear {
                displayed = ""
                if animate {
                    animateText()
                } else {
                    displayed = text
                }
            }
    }
    
    func animateText() {
        for (i, char) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                displayed.append(char)
            }
        }
    }
}

#Preview {
    PodcastView(userID: "demo", username: "demo")
} 