# Notification System Implementation

This document explains the notification system implementation for the myTuition app, including fixes for FCM token initialization issues.

## Overview

The notification system has been updated to ensure FCM tokens are properly initialized for all authenticated users, including those who were already logged in before the update.

## Key Changes

### 1. **FCM Service (Updated)**
- **File**: `lib/core/services/fcm_service.dart`
- **Changes**:
  - Added `ensureTokenForAuthenticatedUser()` method to handle token initialization for already logged-in users
  - Improved error handling and logging
  - Added token removal on logout
  - Handles token refresh automatically

### 2. **Auth State Observer (Updated)**
- **File**: `lib/core/services/auth_state_observer.dart`
- **Changes**:
  - Now calls `ensureTokenForAuthenticatedUser()` when auth state changes
  - Ensures FCM token is saved for users who skip login due to persistent sessions

### 3. **Auth Repository (Updated)**
- **File**: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- **Changes**:
  - Ensures FCM token is saved during login
  - Removes FCM token during logout
  - Updates user online status

### 4. **Student Dashboard (Updated)**
- **File**: `lib/features/student_dashboard/presentation/pages/student_dashboard_page.dart`
- **Changes**:
  - Added notification badge in app bar
  - Added quick action card for notifications
  - Integrated with notification navigation

### 5. **Cloud Functions (New)**
- **Files**: 
  - `functions/index.js`
  - `functions/src/notifications/schedule-change-notifications.js`
- **Features**:
  - Automatic notifications for schedule changes
  - Task creation and feedback notifications
  - Daily task reminders
  - Old notification cleanup

## How It Works

### FCM Token Initialization Flow

1. **On App Start**:
   - `main.dart` initializes FCM service
   - `AuthStateObserver` checks for authenticated user
   - If user is authenticated, `ensureTokenForAuthenticatedUser()` is called

2. **On Login**:
   - User logs in successfully
   - FCM token is saved to Firestore
   - User document is updated with token

3. **On Token Refresh**:
   - FCM service listens for token refresh events
   - New token is automatically saved to Firestore

4. **On Logout**:
   - FCM token is removed from Firestore
   - User status is updated to offline

### Notification Types

1. **Schedule Changes** (`schedule_change`, `schedule_replacement`)
   - Triggered when schedules are created, updated, or deleted
   - Sent to all enrolled students

2. **Task Notifications** (`task_created`, `task_feedback`, `task_reminder`)
   - New tasks notify enrolled students
   - Feedback notifications when tutor adds remarks
   - Daily reminders for tasks due tomorrow

3. **Manual Notifications** (`tutor_notification`)
   - Sent by tutors to specific students
   - Can include custom messages

## Setup Instructions

### 1. Deploy Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. Update Firebase Security Rules

Add the following to your Firestore security rules:

```javascript
// Allow users to read/write their own FCM token
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Allow users to read their notifications
match /notifications/{notificationId} {
  allow read: if request.auth != null && 
    resource.data.userId == request.auth.uid;
  allow write: if false; // Only cloud functions can write
}
```

### 3. Configure Firebase Cloud Messaging

1. Go to Firebase Console > Project Settings > Cloud Messaging
2. Add your Android/iOS app configurations
3. Download and add the configuration files to your app

### 4. Android Setup

Ensure your `android/app/src/main/AndroidManifest.xml` includes:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
```

### 5. iOS Setup

1. Enable Push Notifications capability in Xcode
2. Add required permissions to `Info.plist`
3. Upload APNs certificates to Firebase Console

## Testing

### Test FCM Token Initialization

1. **For New Users**:
   - Register/login normally
   - Check Firestore to verify FCM token is saved

2. **For Existing Users**:
   - Clear app data/reinstall app
   - Open app (should auto-login if session exists)
   - Check Firestore to verify FCM token is saved

3. **Test Notifications**:
   - Create/update a schedule
   - Create a new task
   - Check if notifications are received

### Troubleshooting

1. **No FCM Token Saved**:
   - Check if notification permissions are granted
   - Verify Firebase configuration files are correct
   - Check console logs for errors

2. **Notifications Not Received**:
   - Verify FCM token exists in Firestore
   - Check if cloud functions are deployed
   - Verify notification permissions are granted

3. **Token Not Updated for Existing Users**:
   - Force refresh by calling `FCMService().ensureTokenForAuthenticatedUser()`
   - Check AuthStateObserver is initialized in main.dart

## Security Considerations

1. **Token Management**:
   - FCM tokens are removed on logout
   - Tokens are user-specific and stored securely
   - Token refresh is handled automatically

2. **Notification Access**:
   - Users can only read their own notifications
   - Only cloud functions can create notifications
   - Notification data is encrypted in transit

## Future Enhancements

1. **Notification Categories**:
   - Add filtering by notification type
   - Priority levels for notifications

2. **Rich Notifications**:
   - Add images and action buttons
   - Interactive notifications

3. **Analytics**:
   - Track notification delivery rates
   - Monitor user engagement

4. **Customization**:
   - User notification preferences
   - Quiet hours settings
