# Lori

<div style="display: flex; flex-wrap: wrap; gap: 10px; justify-content: center;">
  <img src="https://github.com/user-attachments/assets/d283ea1d-e1cb-453c-a945-f73dfa3efc08" width="200"/>
  <img src="https://github.com/user-attachments/assets/64470d5e-a287-4ff1-a88e-bcced1aaea69" width="200"/>
  <img src="https://github.com/user-attachments/assets/67f6ed14-9272-4540-83d1-902f9da6ad8b" width="200"/>
  <img src="https://github.com/user-attachments/assets/70817d00-edf7-475c-9c62-7429c527191d" width="200"/>
  <img src="https://github.com/user-attachments/assets/321d7855-b2e8-4c9d-84d6-96b751453c94" width="200"/>
  <img src="https://github.com/user-attachments/assets/e0e60e67-687f-4e86-923a-3f240c2483c8" width="200"/>
  <img src="https://github.com/user-attachments/assets/689f3628-4ce9-4254-85cd-69d2f2a11df5" width="200"/>
  <img src="https://github.com/user-attachments/assets/ccbbd9f2-313e-4ae3-826a-935d1482e251" width="200"/>
  <img src="https://github.com/user-attachments/assets/477a678d-eceb-42e8-bbde-c625f214264e" width="200"/>
</div>

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
