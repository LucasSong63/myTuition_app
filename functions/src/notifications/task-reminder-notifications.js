// functions/src/notifications/task-reminder-notifications.js

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

// Check for tasks due tomorrow and send reminders at 8 PM daily
exports.dailyTaskReminder = onSchedule(
  {
    schedule: 'every day 20:00', // 8 PM daily
    timeZone: 'Asia/Kuala_Lumpur',
    region: 'asia-southeast1',
  },
  async (event) => {
    try {
      // Get tomorrow's date
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);

      const dayAfterTomorrow = new Date(tomorrow);
      dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 1);

      // Find all tasks due tomorrow
      const tasksSnapshot = await admin.firestore()
        .collection('tasks')
        .where('dueDate', '>=', admin.firestore.Timestamp.fromDate(tomorrow))
        .where('dueDate', '<', admin.firestore.Timestamp.fromDate(dayAfterTomorrow))
        .get();

      if (tasksSnapshot.empty) {
        console.log('No tasks due tomorrow');
        return null;
      }

      const batch = admin.firestore().batch();
      const notificationPromises = [];

      for (const taskDoc of tasksSnapshot.docs) {
        const taskData = taskDoc.data();
        const taskId = taskDoc.id;

        // Get course info
        const courseDoc = await admin.firestore()
          .collection('classes')
          .doc(taskData.courseId)
          .get();

        if (!courseDoc.exists) continue;

        const courseData = courseDoc.data();
        const enrolledStudents = courseData.students || [];
        const courseName = `${courseData.subject} Grade ${courseData.grade}`;

        // Check each student's completion status
        for (const studentId of enrolledStudents) {
          // Check if student has already completed the task
          const studentTaskDoc = await admin.firestore()
            .collection('student_tasks')
            .doc(`${taskId}_${studentId}`)
            .get();

          if (studentTaskDoc.exists && studentTaskDoc.data().isCompleted) {
            continue; // Skip if already completed
          }

          // Create reminder notification
          const title = 'Task Due Tomorrow!';
          const message = `Don't forget! "${taskData.title}" for ${courseName} is due tomorrow.`;

          // Create in-app notification
          const notificationRef = admin.firestore()
            .collection('notifications')
            .doc();

          batch.set(notificationRef, {
            userId: studentId,
            type: 'task_reminder',
            title: title,
            message: message,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            data: {
              taskId: taskId,
              courseId: taskData.courseId,
              courseName: courseName,
              taskTitle: taskData.title,
              dueDate: taskData.dueDate,
            }
          });

          // Send push notification
          notificationPromises.push(
            sendPushNotificationToStudent(studentId, title, message, {
              type: 'task_reminder',
              taskId: taskId,
              courseId: taskData.courseId,
            })
          );
        }
      }

      // Commit batch write
      await batch.commit();
      
      // Send push notifications
      await Promise.all(notificationPromises);

      console.log(`Sent task reminders for tasks due tomorrow`);
      return null;

    } catch (error) {
      console.error('Error sending task reminders:', error);
      return null;
    }
  }
);

// Check for overdue tasks and send final reminders at 9 AM daily
exports.overdueTaskReminder = onSchedule(
  {
    schedule: 'every day 09:00', // 9 AM daily
    timeZone: 'Asia/Kuala_Lumpur',
    region: 'asia-southeast1',
  },
  async (event) => {
    try {
      const now = new Date();
      now.setHours(0, 0, 0, 0);

      // Find all overdue tasks
      const tasksSnapshot = await admin.firestore()
        .collection('tasks')
        .where('dueDate', '<', admin.firestore.Timestamp.fromDate(now))
        .get();

      if (tasksSnapshot.empty) {
        console.log('No overdue tasks');
        return null;
      }

      const batch = admin.firestore().batch();
      const notificationPromises = [];

      for (const taskDoc of tasksSnapshot.docs) {
        const taskData = taskDoc.data();
        const taskId = taskDoc.id;

        // Skip if we already sent overdue notification in last 7 days
        const recentNotifications = await admin.firestore()
          .collection('notifications')
          .where('type', '==', 'task_overdue')
          .where('data.taskId', '==', taskId)
          .where('createdAt', '>', admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) // 7 days ago
          ))
          .limit(1)
          .get();

        if (!recentNotifications.empty) continue;

        // Get course info
        const courseDoc = await admin.firestore()
          .collection('classes')
          .doc(taskData.courseId)
          .get();

        if (!courseDoc.exists) continue;

        const courseData = courseDoc.data();
        const enrolledStudents = courseData.students || [];
        const courseName = `${courseData.subject} Grade ${courseData.grade}`;

        // Check each student's completion status
        for (const studentId of enrolledStudents) {
          // Check if student has already completed the task
          const studentTaskDoc = await admin.firestore()
            .collection('student_tasks')
            .doc(`${taskId}_${studentId}`)
            .get();

          if (studentTaskDoc.exists && studentTaskDoc.data().isCompleted) {
            continue; // Skip if already completed
          }

          // Create overdue notification
          const daysOverdue = Math.floor((now - taskData.dueDate.toDate()) / (1000 * 60 * 60 * 24));
          const title = 'Task Overdue!';
          const message = `"${taskData.title}" for ${courseName} is ${daysOverdue} days overdue. Please complete it as soon as possible.`;

          // Create in-app notification
          const notificationRef = admin.firestore()
            .collection('notifications')
            .doc();

          batch.set(notificationRef, {
            userId: studentId,
            type: 'task_overdue',
            title: title,
            message: message,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            data: {
              taskId: taskId,
              courseId: taskData.courseId,
              courseName: courseName,
              taskTitle: taskData.title,
              dueDate: taskData.dueDate,
              daysOverdue: daysOverdue,
            }
          });

          // Send push notification
          notificationPromises.push(
            sendPushNotificationToStudent(studentId, title, message, {
              type: 'task_overdue',
              taskId: taskId,
              courseId: taskData.courseId,
            })
          );
        }
      }

      // Commit batch write
      await batch.commit();
      
      // Send push notifications
      await Promise.all(notificationPromises);

      console.log(`Sent overdue task reminders`);
      return null;

    } catch (error) {
      console.error('Error sending overdue task reminders:', error);
      return null;
    }
  }
);

// Helper function to send push notification
async function sendPushNotificationToStudent(studentId, title, body, data) {
  try {
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
  dailyTaskReminder: exports.dailyTaskReminder,
  overdueTaskReminder: exports.overdueTaskReminder,
};
