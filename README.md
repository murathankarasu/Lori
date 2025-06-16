# Lori

Lori is a sophisticated social media platform built with Swift, focusing on user interaction, content moderation, and emotional intelligence. The platform combines modern social networking features with advanced AI-powered content analysis and user experience optimization.

## 🌟 Features

### Core Functionality
- **Post Management**: Create, share, and interact with posts
- **Direct Messaging**: Real-time private messaging between users
- **User Profiles**: Customizable user profiles with interest tracking
- **Notifications**: Comprehensive notification system with in-app and push notifications
- **Search**: Advanced search capabilities for posts and users

### Advanced Features
- **Content Moderation**
  - Hate speech detection
  - Disinformation analysis
  - Media content analysis
  - Keyword analysis

### Emotional Intelligence
- **Emotion Analysis**: AI-powered emotion detection in user interactions
- **User Emotion Tracking**: Monitor and analyze user emotional patterns
- **Recommendation Engine**: Personalized content recommendations based on user behavior

### Media Handling
- **Media Analysis**: Advanced processing of images and videos
- **Podcast Support**: Audio content management and processing
- **Direct Message Media**: Secure media sharing in private conversations

## 🏗 Architecture

The project follows a clean architecture pattern with clear separation of concerns:

### Services Layer
- **Core Services**
  - `DirectMessageService`: Manages private messaging
  - `InteractionService`: Handles user interactions
  - `CacheManager`: Optimizes data caching
  - `NotificationCoreService`: Core notification functionality

- **Analysis Services**
  - `DisinformationService`: Content verification
  - `HateSpeechService`: Content moderation
  - `EmotionService`: Emotional analysis
  - `MediaAnalysisService`: Media content processing

- **User Experience Services**
  - `RecommendationService`: Content recommendations
  - `UserEmotionService`: User emotion tracking
  - `InAppNotificationService`: In-app notification management

### Views Layer
Organized into feature-specific directories:
- `Post/`: Post-related views
- `Message/`: Messaging interface
- `Profile/`: User profile views
- `Search/`: Search functionality
- `Auth/`: Authentication views
- `Common/`: Shared UI components

### Models Layer
Core data models including:
- `User`: User profile and preferences
- `Post`: Content structure
- `DirectMessage`: Private messaging
- `Notification`: Notification system
- `EmotionAnalysis`: Emotional data
- `SupportTicket`: User support system

## 🛠 Technical Stack

- **Language**: Swift
- **Architecture**: MVVM (Model-View-ViewModel)
- **Database**: Firestore (based on FirestoreIndexes.swift)
- **Media Processing**: Custom media analysis services
- **AI Integration**: Multiple AI services for content analysis

## 🔒 Security Features

- Content moderation
- Hate speech detection
- Disinformation prevention
- Secure media handling
- User privacy protection

## 📱 User Experience

- Real-time notifications
- In-app messaging
- Emotional intelligence features
- Personalized recommendations
- Media-rich content support

## 🚀 Getting Started

1. Clone the repository
2. Install required dependencies
3. Set up Firebase configuration
4. Configure necessary API keys
5. Build and run the project

## 📝 Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.0+
- Firebase account
- Required API keys for various services

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is proprietary software. All rights reserved.

## 👥 Team

Lori is developed and maintained by me and cursor.

## 📞 Support

For support, please use the in-app support ticket system or contact the development team directly. 
