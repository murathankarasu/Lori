import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct GuideItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct HelpCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

struct QuickHelpItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

// Sample Data
let faqItems = [
    FAQItem(
        question: "How can I create an account?",
        answer: "You can create a new account by clicking the 'Sign Up' button on the app's welcome screen."
    ),
    FAQItem(
        question: "How can I reset my password?",
        answer: "You can start the password reset process by clicking the 'Forgot Password' option on the login screen."
    ),
    FAQItem(
        question: "How can I edit my profile?",
        answer: "You can update your profile information by going to 'Edit Profile' in the settings menu."
    )
]

let guideItems = [
    GuideItem(
        title: "Getting Started",
        description: "If you're using the app for the first time, this guide will help you.",
        icon: "star.fill",
        color: .yellow
    ),
    GuideItem(
        title: "Profile Management",
        description: "Learn how to edit and customize your profile.",
        icon: "person.fill",
        color: .blue
    ),
    GuideItem(
        title: "Content Sharing",
        description: "Everything you need to know about sharing photos and videos.",
        icon: "photo.fill",
        color: .green
    )
] 