// functions/src/notifications/payment-reminder-notifications.js

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

// Check for outstanding payments and send reminders every 3 days at 10 AM
exports.outstandingPaymentReminder = onSchedule(
  {
    schedule: 'every 72 hours', // Every 3 days
    timeZone: 'Asia/Kuala_Lumpur',
    region: 'asia-southeast1',
  },
  async (event) => {
    try {
      // Get all outstanding payments
      const paymentsSnapshot = await admin.firestore()
        .collection('payments')
        .where('status', '==', 'outstanding')
        .get();

      if (paymentsSnapshot.empty) {
        console.log('No outstanding payments found');
        return null;
      }

      const batch = admin.firestore().batch();
      const notificationPromises = [];
      const now = new Date();

      for (const paymentDoc of paymentsSnapshot.docs) {
        const paymentData = paymentDoc.data();
        const paymentId = paymentDoc.id;
        const studentId = paymentData.studentId;

        // Check if we already sent a reminder in the last 3 days
        const recentReminders = await admin.firestore()
          .collection('notifications')
          .where('userId', '==', studentId)
          .where('type', '==', 'payment_reminder')
          .where('data.paymentId', '==', paymentId)
          .where('createdAt', '>', admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 3 * 24 * 60 * 60 * 1000) // 3 days ago
          ))
          .limit(1)
          .get();

        if (!recentReminders.empty) {
          console.log(`Already sent reminder for payment ${paymentId} to student ${studentId}`);
          continue;
        }

        // Calculate days overdue if dueDate exists
        let daysOverdue = 0;
        let overdueText = '';
        if (paymentData.dueDate) {
          const dueDate = paymentData.dueDate.toDate();
          daysOverdue = Math.floor((now - dueDate) / (1000 * 60 * 60 * 24));
          if (daysOverdue > 0) {
            overdueText = ` (${daysOverdue} days overdue)`;
          }
        }

        // Format amount
        const amount = paymentData.amount ? `RM${paymentData.amount.toFixed(2)}` : 'Amount pending';

        // Create notification
        const title = daysOverdue > 7 ? 'Urgent: Payment Overdue' : 'Payment Reminder';
        const message = `You have an outstanding payment of ${amount} for ${paymentData.description || 'tuition fees'}${overdueText}. Please make your payment as soon as possible.`;

        // Create in-app notification
        const notificationRef = admin.firestore()
          .collection('notifications')
          .doc();

        batch.set(notificationRef, {
          userId: studentId,
          type: daysOverdue > 7 ? 'payment_overdue' : 'payment_reminder',
          title: title,
          message: message,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            paymentId: paymentId,
            amount: paymentData.amount || 0,
            description: paymentData.description || 'tuition fees',
            daysOverdue: daysOverdue,
            dueDate: paymentData.dueDate || null,
          }
        });

        // Send push notification
        notificationPromises.push(
          sendPushNotificationToStudent(studentId, title, message, {
            type: daysOverdue > 7 ? 'payment_overdue' : 'payment_reminder',
            paymentId: paymentId,
          })
        );
      }

      // Commit batch write
      await batch.commit();
      
      // Send push notifications
      await Promise.all(notificationPromises);

      console.log(`Sent payment reminders for ${notificationPromises.length} outstanding payments`);
      return null;

    } catch (error) {
      console.error('Error sending payment reminders:', error);
      return null;
    }
  }
);

// Send payment due soon reminders (3 days before due date) daily at 10 AM
exports.paymentDueSoonReminder = onSchedule(
  {
    schedule: 'every day 10:00', // Daily at 10 AM
    timeZone: 'Asia/Kuala_Lumpur',
    region: 'asia-southeast1',
  },
  async (event) => {
    try {
      // Calculate date range (payments due in next 3 days)
      const now = new Date();
      const threeDaysFromNow = new Date();
      threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

      // Get payments due soon
      const paymentsSnapshot = await admin.firestore()
        .collection('payments')
        .where('status', '==', 'pending')
        .where('dueDate', '>=', admin.firestore.Timestamp.fromDate(now))
        .where('dueDate', '<=', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
        .get();

      if (paymentsSnapshot.empty) {
        console.log('No payments due soon');
        return null;
      }

      const batch = admin.firestore().batch();
      const notificationPromises = [];

      for (const paymentDoc of paymentsSnapshot.docs) {
        const paymentData = paymentDoc.data();
        const paymentId = paymentDoc.id;
        const studentId = paymentData.studentId;

        // Check if we already sent a due soon reminder for this payment
        const existingReminders = await admin.firestore()
          .collection('notifications')
          .where('userId', '==', studentId)
          .where('type', '==', 'payment_due_soon')
          .where('data.paymentId', '==', paymentId)
          .limit(1)
          .get();

        if (!existingReminders.empty) {
          console.log(`Already sent due soon reminder for payment ${paymentId}`);
          continue;
        }

        // Calculate days until due
        const dueDate = paymentData.dueDate.toDate();
        const daysUntilDue = Math.ceil((dueDate - now) / (1000 * 60 * 60 * 24));

        // Format amount
        const amount = paymentData.amount ? `RM${paymentData.amount.toFixed(2)}` : 'Amount pending';

        // Create notification
        const title = 'Payment Due Soon';
        const message = `Your payment of ${amount} for ${paymentData.description || 'tuition fees'} is due in ${daysUntilDue} days. Please prepare your payment.`;

        // Create in-app notification
        const notificationRef = admin.firestore()
          .collection('notifications')
          .doc();

        batch.set(notificationRef, {
          userId: studentId,
          type: 'payment_due_soon',
          title: title,
          message: message,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            paymentId: paymentId,
            amount: paymentData.amount || 0,
            description: paymentData.description || 'tuition fees',
            daysUntilDue: daysUntilDue,
            dueDate: paymentData.dueDate,
          }
        });

        // Send push notification
        notificationPromises.push(
          sendPushNotificationToStudent(studentId, title, message, {
            type: 'payment_due_soon',
            paymentId: paymentId,
          })
        );
      }

      // Commit batch write
      await batch.commit();
      
      // Send push notifications
      await Promise.all(notificationPromises);

      console.log(`Sent ${notificationPromises.length} payment due soon reminders`);
      return null;

    } catch (error) {
      console.error('Error sending payment due soon reminders:', error);
      return null;
    }
  }
);

// Helper function to send push notification (reuse from other files)
async function sendPushNotificationToStudent(studentId, title, body, data) {
  try {
    // Query user by studentId field
    const userQuery = await admin.firestore()
      .collection('users')
      .where('studentId', '==', studentId)
      .limit(1)
      .get();

    if (userQuery.empty) {
      console.log('User not found with studentId:', studentId);
      return;
    }

    const userData = userQuery.docs[0].data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', studentId);
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
          priority: 'high',
          defaultSound: true,
        },
      },
    };

    await admin.messaging().send(message);
    console.log('Push notification sent to:', studentId);

  } catch (error) {
    console.error('Error sending push notification:', error);
  }
}

module.exports = {
  outstandingPaymentReminder: exports.outstandingPaymentReminder,
  paymentDueSoonReminder: exports.paymentDueSoonReminder,
};
