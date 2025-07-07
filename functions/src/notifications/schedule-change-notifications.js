// functions/src/notifications/schedule-change-notifications.js

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

// Trigger when a schedule is created, updated, or deleted
exports.onScheduleChange = onDocumentWritten(
  {
    document: 'classes/{courseId}/schedules/{scheduleId}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const courseId = event.params.courseId;
    const scheduleId = event.params.scheduleId;

    // Get the before and after data
    const beforeData = event.data.before.exists ? event.data.before.data() : null;
    const afterData = event.data.after.exists ? event.data.after.data() : null;

    // Determine the type of change
    let changeType = '';
    let notificationData = {};

    if (!beforeData && afterData) {
      // New schedule created
      changeType = 'created';
      notificationData = afterData;
    } else if (beforeData && !afterData) {
      // Schedule deleted
      changeType = 'deleted';
      notificationData = beforeData;
    } else if (beforeData && afterData) {
      // Schedule updated
      changeType = 'updated';
      notificationData = afterData;
      
      // Check if it's a replacement class
      const isReplacement = notificationData.isReplacement || false;
      if (isReplacement) {
        changeType = 'replacement';
      }
    }

    if (!changeType) return null;

    try {
      // Get course details
      const courseDoc = await admin.firestore()
        .collection('classes')
        .doc(courseId)
        .get();

      if (!courseDoc.exists) {
        console.error('Course not found:', courseId);
        return null;
      }

      const courseData = courseDoc.data();
      const enrolledStudents = courseData.students || [];

      if (enrolledStudents.length === 0) {
        console.log('No students enrolled in course:', courseId);
        return null;
      }

      // Prepare notification content
      let title = '';
      let message = '';
      const courseName = `${courseData.subject} Grade ${courseData.grade}`;
      
      switch (changeType) {
        case 'created':
          title = 'New Class Schedule';
          message = `A new class has been scheduled for ${courseName}`;
          break;
        case 'deleted':
          title = 'Class Cancelled';
          message = `A class has been cancelled for ${courseName}`;
          break;
        case 'updated':
          title = 'Schedule Updated';
          message = `The schedule has been updated for ${courseName}`;
          break;
        case 'replacement':
          title = 'Replacement Class';
          message = `A replacement class has been scheduled for ${courseName}`;
          break;
      }

      // Add schedule details to message
      if (notificationData.day && notificationData.startTime) {
        message += ` on ${notificationData.day} at ${notificationData.startTime}`;
      }

      // Create notifications for each enrolled student
      const batch = admin.firestore().batch();
      const notificationPromises = [];

      for (const studentId of enrolledStudents) {
        // Create in-app notification
        const notificationRef = admin.firestore()
          .collection('notifications')
          .doc();

        batch.set(notificationRef, {
          userId: studentId,
          type: changeType === 'replacement' ? 'schedule_replacement' : 'schedule_change',
          title: title,
          message: message,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            courseId: courseId,
            courseName: courseName,
            scheduleId: scheduleId,
            changeType: changeType,
            day: notificationData.day || null,
            startTime: notificationData.startTime || null,
            endTime: notificationData.endTime || null,
            isReplacement: notificationData.isReplacement || false,
          }
        });

        // Also send push notification
        notificationPromises.push(
          sendPushNotificationToStudent(studentId, title, message, {
            type: changeType === 'replacement' ? 'schedule_replacement' : 'schedule_change',
            courseId: courseId,
            scheduleId: scheduleId,
          })
        );
      }

      // Commit batch write
      await batch.commit();
      
      // Send push notifications
      await Promise.all(notificationPromises);

      console.log(`Sent ${changeType} notifications to ${enrolledStudents.length} students for course ${courseId}`);
      return null;

    } catch (error) {
      console.error('Error sending schedule change notifications:', error);
      return null;
    }
  }
);

// Helper function to send push notification to a student
async function sendPushNotificationToStudent(studentId, title, body, data) {
  try {
    console.log('Attempting to send push notification to student:', studentId);
    
    // First try to find user by studentId field
    const userQuery = await admin.firestore()
      .collection('users')
      .where('studentId', '==', studentId)
      .limit(1)
      .get();

    let userDoc = null;
    let userData = null;

    if (!userQuery.empty) {
      // Found user by studentId field
      userDoc = userQuery.docs[0];
      userData = userDoc.data();
      console.log('Found user by studentId field:', studentId);
    } else {
      // Try to get user directly by document ID (in case studentId is the actual document ID)
      const directUserDoc = await admin.firestore()
        .collection('users')
        .doc(studentId)
        .get();

      if (directUserDoc.exists) {
        userDoc = directUserDoc;
        userData = directUserDoc.data();
        console.log('Found user by document ID:', studentId);
      } else {
        console.log('User not found with studentId:', studentId);
        return;
      }
    }

    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', studentId);
      console.log('User data:', JSON.stringify(userData));
      return;
    }

    // Send push notification
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
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
          },
        },
      },
    };

    await admin.messaging().send(message);
    console.log('Push notification sent successfully to:', studentId);

  } catch (error) {
    console.error('Error sending push notification to', studentId, ':', error);
  }
}

// Trigger when a task is created or updated
exports.onTaskChange = onDocumentWritten(
  {
    document: 'tasks/{taskId}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const taskId = event.params.taskId;

    // Get the before and after data
    const beforeData = event.data.before.exists ? event.data.before.data() : null;
    const afterData = event.data.after.exists ? event.data.after.data() : null;

    // Determine the type of change
    let changeType = '';
    let taskData = {};

    if (!beforeData && afterData) {
      // New task created
      changeType = 'created';
      taskData = afterData;
    } else if (beforeData && afterData) {
      // Task updated - check if remarks were added
      taskData = afterData;

      // Check if remarks were added to a student task
      const beforeRemarks = beforeData.studentTasks || {};
      const afterRemarks = afterData.studentTasks || {};

      for (const studentId in afterRemarks) {
        const beforeRemark = beforeRemarks[studentId]?.remarks || '';
        const afterRemark = afterRemarks[studentId]?.remarks || '';

        if (afterRemark && afterRemark !== beforeRemark) {
          // Send notification for task feedback
          await sendTaskFeedbackNotification(studentId, taskData, taskId);
        }
      }

      return null; // Exit early for updates
    }

    if (changeType !== 'created') return null;

    try {
      // Get course details
      const courseDoc = await admin.firestore()
        .collection('classes')
        .doc(taskData.courseId)
        .get();

      if (!courseDoc.exists) {
        console.error('Course not found:', taskData.courseId);
        return null;
      }

      const courseData = courseDoc.data();
      const enrolledStudents = courseData.students || [];

      if (enrolledStudents.length === 0) {
        console.log('No students enrolled in course:', taskData.courseId);
        return null;
      }

      // Prepare notification content
      const title = 'New Task Assigned';
      const courseName = `${courseData.subject} Grade ${courseData.grade}`;
      const message = `New task "${taskData.title}" has been assigned in ${courseName}`;

      // Create notifications for each enrolled student
      const batch = admin.firestore().batch();
      const notificationPromises = [];

      for (const studentId of enrolledStudents) {
        // Create in-app notification
        const notificationRef = admin.firestore()
          .collection('notifications')
          .doc();

        batch.set(notificationRef, {
          userId: studentId,
          type: 'task_created',
          title: title,
          message: message,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            taskId: taskId,
            courseId: taskData.courseId,
            courseName: courseName,
            taskTitle: taskData.title,
            dueDate: taskData.dueDate || null,
          }
        });

        // Also send push notification
        notificationPromises.push(
          sendPushNotificationToStudent(studentId, title, message, {
            type: 'task_created',
            taskId: taskId,
            courseId: taskData.courseId,
          })
        );
      }

      // Commit batch write
      await batch.commit();
      
      // Send push notifications
      await Promise.all(notificationPromises);

      console.log(`Sent task notifications to ${enrolledStudents.length} students for task ${taskId}`);
      return null;

    } catch (error) {
      console.error('Error sending task notifications:', error);
      return null;
    }
  }
);

// Helper function to send task feedback notification
async function sendTaskFeedbackNotification(studentId, taskData, taskId) {
  try {
    const title = 'Task Feedback Received';
    const message = `Your tutor has provided feedback on "${taskData.title}"`;

    // Create in-app notification
    await admin.firestore()
      .collection('notifications')
      .add({
        userId: studentId,
        type: 'task_feedback',
        title: title,
        message: message,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          taskId: taskId,
          courseId: taskData.courseId,
          taskTitle: taskData.title,
        }
      });

    // Send push notification
    await sendPushNotificationToStudent(studentId, title, message, {
      type: 'task_feedback',
      taskId: taskId,
      courseId: taskData.courseId,
    });

    console.log(`Sent task feedback notification to student ${studentId}`);
  } catch (error) {
    console.error('Error sending task feedback notification:', error);
  }
}

module.exports = {
  onScheduleChange: exports.onScheduleChange,
  onTaskChange: exports.onTaskChange,
};
