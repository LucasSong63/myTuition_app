# Notification System Implementation Guide

## Summary of Changes

This implementation addresses the FCM token initialization issue where users who were already logged in before the app update would not have their FCM tokens initialized properly.

### Files Modified/Created:

1. **Core Services**:
   - `lib/core/services/fcm_service.dart` - Enhanced FCM token management
   - `lib/core/services/auth_state_observer.dart` - Ensures token initialization for authenticated users
   - `lib/core/services/notification_navigation_service.dart` - Handles navigation when notifications are tapped

2. **Authentication**:
   - `lib/features/auth/data/repositories/auth_repository_impl.dart` - Added FCM token handling during login/logout

3. **UI Updates**:
   - `lib/features/student_dashboard/presentation/pages/student_dashboard_page.dart` - Added notification badge and quick actions

4. **Cloud Functions** (New):
   - `functions/index.js` - Main cloud functions file
   - `functions/src/notifications/schedule-change-notifications.js` - Automatic notification triggers
   - `functions/package.json` - Dependencies
   - `functions/.gitignore` - Git ignore file

5. **Configuration**:
   - `firebase.json` - Firebase project configuration
   - `lib/config/router/route_config.dart` - Added global navigator key

6. **Documentation**:
   - `NOTIFICATION_SYSTEM_README.md` - Detailed documentation
   - This implementation guide

## Key Features Implemented

### 1. **Automatic FCM Token Initialization**
- Tokens are now initialized when:
  - User logs in
  - App starts with an authenticated session
  - Auth state changes
  - Token refreshes

### 2. **Notification Types**
- Schedule changes (create/update/delete/replacement)
- Task notifications (created/feedback/reminders)
- Manual notifications from tutors
- Payment reminders

### 3. **UI Integration**
- Notification badge with unread count in app bar
- Quick action card for easy access
- Navigation to relevant screens when notifications are tapped

### 4. **Cloud Functions**
- Automatic notifications for schedule and task changes
- Daily task reminders
- Old notification cleanup (90 days)

## Deployment Steps

### 1. Update Flutter App

```bash
# Get dependencies
flutter pub get

# Build the app
flutter build apk --release
```

### 2. Deploy Cloud Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy to Firebase
firebase deploy --only functions
```

### 3. Update Firestore Security Rules

Add these rules to your `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own FCM token
    match /users/{userId} {
      allow read: if request.auth != null && 
        (request.auth.uid == userId || request.auth.token.role == 'tutor');
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow users to read their notifications
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow write: if false; // Only cloud functions can write
    }
  }
}
```

Deploy the rules:
```bash
firebase deploy --only firestore:rules
```

## Testing the Implementation

### 1. **Test FCM Token Initialization for Existing Users**

1. Clear app data or reinstall the app
2. Log in as an existing user
3. Check Firestore console:
   - Navigate to `users` collection
   - Find the user document
   - Verify `fcmToken` field exists and has a value

### 2. **Test Notification Delivery**

1. **Schedule Change Notification**:
   - As tutor, create or update a schedule
   - Students should receive notification immediately

2. **Task Notification**:
   - As tutor, create a new task
   - Students should receive notification

3. **Manual Notification**:
   - Use the notification bottom sheet to send custom notifications
   - Verify delivery

### 3. **Test Notification Badge**

1. Send a notification to a student
2. Open the student app
3. Verify the red badge appears with count
4. Tap the notification icon
5. Verify navigation to notifications list
6. Mark as read and verify badge updates

### 4. **Test Background Notifications**

1. Close the app (background)
2. Send a notification
3. Verify notification appears in system tray
4. Tap notification
5. Verify app opens to correct screen

## Troubleshooting

### Issue: FCM Token Not Saved

**Check**:
1. Notification permissions are granted
2. Google Play Services is updated
3. Internet connection is available

**Solution**:
```dart
// Force token refresh
final fcmService = GetIt.instance<FCMService>();
await fcmService.ensureTokenForAuthenticatedUser();
```

### Issue: Notifications Not Received

**Check**:
1. FCM token exists in Firestore
2. Cloud functions are deployed
3. User is enrolled in the course
4. Notification permissions are enabled

**Debug**:
- Check Cloud Functions logs:
  ```bash
  firebase functions:log
  ```
- Check FCM token in Firestore
- Test with Firebase Console

### Issue: Badge Count Not Updating

**Check**:
1. NotificationManager is registered in GetIt
2. Stream is properly connected
3. Firestore query permissions

## Maintenance

### Daily Tasks
- Old notifications are automatically cleaned up after 90 days
- Task reminders are sent daily at 8:00 AM (Malaysia time)

### Monitoring
- Monitor Cloud Functions logs for errors
- Check notification delivery rates
- Monitor Firestore usage

### Updates
- Keep Firebase SDKs updated
- Update cloud functions dependencies regularly
- Test after major updates

## Security Notes

1. **Token Security**:
   - FCM tokens are user-specific
   - Removed on logout
   - Only accessible by token owner

2. **Notification Access**:
   - Users can only read their own notifications
   - Only cloud functions can create notifications
   - Tutor notifications require authentication

3. **Data Privacy**:
   - Notification data is minimal
   - No sensitive information in push notifications
   - All data encrypted in transit

## Next Steps

1. **Analytics Integration**:
   - Track notification open rates
   - Monitor engagement metrics

2. **User Preferences**:
   - Allow notification type preferences
   - Quiet hours settings
   - Language preferences

3. **Rich Notifications**:
   - Add images to notifications
   - Action buttons for quick responses
   - Expandable notifications

4. **Performance Optimization**:
   - Batch notification sending
   - Rate limiting for manual notifications
   - Caching for better performance
