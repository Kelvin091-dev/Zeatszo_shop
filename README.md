# Zeatszo Shopkeeper Dashboard

A production-ready Flutter application for managing chicken orders in real-time, integrated with Firebase for authentication, database, storage, and push notifications.

## 🚀 Features

- **Real-Time Order Management**: View and update orders instantly with Firebase Firestore
- **Order Status Tracking**: Track orders from pending to completion
- **Product/Pricing Management**: Add, edit, and manage chicken products with pricing
- **Revenue Analytics**: View daily, weekly, and monthly revenue with interactive charts
- **Push Notifications**: Real-time order notifications using Firebase Cloud Messaging
- **User Authentication**: Secure Firebase Authentication
- **Profile Management**: View and manage shop information
- **Material Design UI**: Modern, responsive UI with light/dark theme support

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- Flutter SDK (>=3.5.0 <4.0.0)
- Dart SDK
- Firebase CLI (`npm install -g firebase-tools`)
- Node.js 20+ (for Cloud Functions)
- Android Studio / Xcode (for mobile development)
- A Firebase project

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Kelvin091-dev/Zeatszo_shop.git
cd Zeatszo_shop
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

#### Option A: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will:
- Connect your Flutter app to your Firebase project
- Generate `lib/firebase_options.dart` with your configuration
- Set up Firebase for Android, iOS, and Web platforms

#### Option B: Manual Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android/iOS/Web apps to your Firebase project
3. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Web: Update `web/firebase-messaging-sw.js` with your config
4. Manually create `lib/firebase_options.dart` with your Firebase configuration

### 4. Enable Firebase Services

In the Firebase Console, enable the following services:

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable Email/Password authentication

2. **Firestore Database**
   - Go to Firestore Database → Create database
   - Start in production mode
   - Deploy the security rules from `firestore.rules`:
     ```bash
     firebase deploy --only firestore:rules
     ```

3. **Cloud Messaging**
   - Go to Cloud Messaging
   - No additional setup required; it's enabled by default

4. **Cloud Storage** (Optional, for product images)
   - Go to Storage → Get Started

### 5. Deploy Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
cd ..
```

### 6. Create Assets Directory

```bash
mkdir -p assets/icons
```

Add icon files to `assets/icons/` if you have custom icons.

### 7. Run the Application

```bash
# Run on connected device or emulator
flutter run

# Run in debug mode
flutter run --debug

# Run in release mode
flutter run --release

# Run on specific platform
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS
```

## 🗂️ Project Structure

```
lib/
├── firebase_options.dart       # Firebase configuration
├── main.dart                   # App entry point
├── models/                     # Data models
│   ├── order.dart
│   ├── product.dart
│   ├── shop.dart
│   └── revenue_stats.dart
├── router/                     # Navigation
│   └── app_router.dart
├── screens/                    # UI screens
│   ├── auth/
│   │   └── login_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── pricing/
│   │   └── pricing_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── revenue/
│       └── revenue_screen.dart
├── services/                   # Business logic
│   ├── auth_service.dart
│   ├── notification_service.dart
│   ├── order_service.dart
│   ├── product_service.dart
│   ├── revenue_service.dart
│   └── shop_service.dart
├── theme/                      # App theme
│   └── app_theme.dart
└── widgets/                    # Reusable widgets
    └── order_card.dart

functions/                      # Firebase Cloud Functions
├── src/
│   └── index.ts
├── package.json
└── tsconfig.json

firestore.rules                 # Firestore security rules
```

## 📱 Usage

### For Shopkeepers

1. **Login**: Sign in with your email and password
2. **View Orders**: See all orders in real-time on the Dashboard
3. **Update Order Status**: Tap on an order to change its status (Pending → Confirmed → Preparing → Ready → Completed)
4. **Manage Products**: Go to Products tab to add/edit/delete products and update pricing
5. **View Revenue**: Check revenue analytics with charts in the Revenue tab
6. **Profile**: View shop information and logout

### Initial Setup for New Shops

After setting up the app, you'll need to create shop data in Firestore:

1. Go to Firebase Console → Firestore Database
2. Create a collection named `shops`
3. Add a document with the following fields:
   ```
   {
     "ownerId": "<your-firebase-auth-uid>",
     "name": "Your Shop Name",
     "address": "Shop Address",
     "phone": "+1234567890",
     "email": "shop@example.com",
     "isActive": true,
     "createdAt": <current timestamp>
   }
   ```

## 🧪 Testing

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## 🔐 Security

- Firestore security rules are defined in `firestore.rules`
- Only authenticated users can access data
- Shop owners can only modify their own shop data
- Order access is restricted to the shop owner or customer

## 🚀 Building for Production

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 📦 Dependencies

- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **cloud_firestore**: Database
- **firebase_messaging**: Push notifications
- **firebase_storage**: File storage
- **flutter_local_notifications**: Local notifications
- **provider**: State management
- **fl_chart**: Charts and analytics
- **google_fonts**: Typography
- **intl**: Internationalization
- **cached_network_image**: Image caching
- **file_picker**: File selection
- **image_picker**: Image selection

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Support

For support, email support@zeatszo.com or create an issue in the repository.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for backend services
- Community contributors

---

**Note**: Make sure to run `flutterfire configure` to generate the `firebase_options.dart` file before running the app. This file is required for Firebase initialization and is not included in the repository for security reasons.
