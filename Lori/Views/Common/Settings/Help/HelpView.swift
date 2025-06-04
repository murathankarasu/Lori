import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    // Sample data
    private let quickHelpItems = [
        QuickHelpItem(title: "Getting Started", icon: "star.fill", color: .yellow),
        QuickHelpItem(title: "Account Settings", icon: "person.fill", color: .blue),
        QuickHelpItem(title: "Privacy", icon: "lock.fill", color: .green),
        QuickHelpItem(title: "Support", icon: "questionmark.circle.fill", color: .purple)
    ]
    
    private let categories = [
        HelpCategory(title: "Getting Started", icon: "star.fill", color: .yellow),
        HelpCategory(title: "Account & Profile", icon: "person.fill", color: .blue),
        HelpCategory(title: "Privacy & Security", icon: "lock.fill", color: .green),
        HelpCategory(title: "Notifications", icon: "bell.fill", color: .orange),
        HelpCategory(title: "Billing & Subscription", icon: "creditcard.fill", color: .purple),
        HelpCategory(title: "Troubleshooting", icon: "wrench.fill", color: .red)
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.15, blue: 0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    Text("Help & Support")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible placeholder for balance
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 80, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search help topics", text: $searchText)
                                .foregroundColor(.white)
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Quick help section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Help")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(quickHelpItems) { item in
                                        QuickHelpCard(title: item.title, icon: item.icon, color: item.color)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Categories section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Help Categories")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                ForEach(categories) { category in
                                    Button(action: {
                                        // Handle category selection
                                    }) {
                                        HelpCategoryRow(title: category.title, icon: category.icon, color: category.color)
                                            .padding()
                                            .background(Color.white.opacity(0.05))
                                    }
                                    
                                    if category.id != categories.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        // FAQ section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Frequently Asked Questions")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                ForEach(faqItems) { item in
                                    FAQItemRow(item: item)
                                        .padding(.horizontal, 20)
                                    
                                    if item.id != faqItems.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        // Guides section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Helpful Guides")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(guideItems) { item in
                                    GuideItemCard(item: item)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// Subviews
struct FAQView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            List {
                ForEach(faqItems) { item in
                    FAQItemRow(item: item)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

struct UserGuideView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(guideItems) { item in
                        GuideItemCard(item: item)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("User Guide")
    }
} 