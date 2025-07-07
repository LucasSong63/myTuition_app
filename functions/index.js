// functions/index.js

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

// Import notification functions
const { onScheduleChange, onTaskChange } = require('./src/notifications/schedule-change-notifications');
const { outstandingPaymentReminder, paymentDueSoonReminder } = require('./src/notifications/payment-reminder-notifications');
const { dailyTaskReminder, overdueTaskReminder } = require('./src/notifications/task-reminder-notifications');
const { onAttendanceRecorded, weeklyAttendanceSummary } = require('./src/notifications/attendance-notifications');

// Export the functions
exports.onScheduleChange = onScheduleChange;
exports.onTaskChange = onTaskChange;
exports.outstandingPaymentReminder = outstandingPaymentReminder;
exports.paymentDueSoonReminder = paymentDueSoonReminder;
exports.dailyTaskReminder = dailyTaskReminder;
exports.overdueTaskReminder = overdueTaskReminder;
exports.onAttendanceRecorded = onAttendanceRecorded;
exports.weeklyAttendanceSummary = weeklyAttendanceSummary;

// Existing sendPushNotification function (HTTP callable) - Updated to v2
exports.sendPushNotification = onRequest(
  {
    region: 'asia-southeast1',
    // Gen 2 settings - using minimal resources
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (req, res) => {
    try {
      const { studentId, title, message, type, createInApp = true, data = {} } = req.query;

      if (!studentId || !title || !message) {
        res.status(400).send('Missing required parameters: studentId, title, and message');
        return;
      }

      // Get student document to find FCM token - query by studentId field
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('studentId', '==', studentId)
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        res.status(404).send('User not found');
        return;
      }

      const userDoc = usersSnapshot.docs[0];
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      // Create in-app notification if requested
      if (createInApp === 'true' || createInApp === true) {
        await admin.firestore().collection('notifications').add({
          userId: studentId,
          type: type || 'general',
          title: title,
          message: message,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: data,
        });
      }

      // Send push notification if FCM token exists
      if (fcmToken) {
        const pushMessage = {
          token: fcmToken,
          notification: {
            title: title,
            body: message,
          },
          data: {
            type: type || 'general',
            ...data,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: title,
                  body: message,
                },
                sound: 'default',
              },
            },
          },
        };

        await admin.messaging().send(pushMessage);
        res.status(200).send('Notification sent successfully');
      } else {
        res.status(200).send('In-app notification created (no FCM token available)');
      }

    } catch (error) {
      console.error('Error sending notification:', error);
      res.status(500).send('Error sending notification: ' + error.message);
    }
  }
);
