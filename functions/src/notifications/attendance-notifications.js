// functions/src/notifications/attendance-notifications.js

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

// Trigger when attendance is recorded
exports.onAttendanceRecorded = onDocumentWritten(
  {
    document: 'attendance/{attendanceId}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const attendanceId = event.params.attendanceId;

    // Get the before and after data
    const beforeData = event.data.before.exists ? event.data.before.data() : null;
    const afterData = event.data.after.exists ? event.data.after.data() : null;

    // Only process new attendance records or status changes
    if (!afterData || (beforeData && beforeData.status === afterData.status)) {
      return null;
    }

    const isNewRecord = !beforeData;
    const attendanceData = afterData;

    try {
      // Skip if not absent or excused
      if (attendanceData.status !== 'absent' && attendanceData.status !== 'excused') {
        console.log(`Attendance status is ${attendanceData.status}, skipping notification`);
        return null;
      }

      // Get course details
      const courseDoc = await admin.firestore()
        .collection('classes')
        .doc(attendanceData.courseId)
        .get();

      if (!courseDoc.exists) {
        console.error('Course not found:', attendanceData.courseId);
        return null;
      }

      const courseData = courseDoc.data();
      const courseName = `${courseData.subject} Grade ${courseData.grade}`;

      // Format date
      const attendanceDate = attendanceData.date.toDate();
      const dateOptions = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
      const formattedDate = attendanceDate.toLocaleDateString('en-US', dateOptions);

      // Prepare notification based on status
      let title = '';
      let message = '';
      let notificationType = '';

      if (attendanceData.status === 'absent') {
        title = 'Marked Absent';
        message = `You were marked absent from ${courseName} on ${formattedDate}.`;
        notificationType = 'attendance_absent';
      } else if (attendanceData.status === 'excused') {
        title = 'Excused Absence Recorded';
        message = `Your absence from ${courseName} on ${formattedDate} has been excused.`;
        notificationType = 'attendance_excused';
      }

      // Add remarks if available
      if (attendanceData.remarks) {
        message += ` Remarks: ${attendanceData.remarks}`;
      }

      // Create in-app notification
      await admin.firestore()
        .collection('notifications')
        .add({
          userId: attendanceData.studentId,
          type: 'attendance_recorded',
          title: title,
          message: message,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            attendanceId: attendanceId,
            courseId: attendanceData.courseId,
            courseName: courseName,
            date: attendanceData.date,
            status: attendanceData.status,
            remarks: attendanceData.remarks || '',
          }
        });

      // Send push notification
      await sendPushNotificationToStudent(
        attendanceData.studentId,
        title,
        message,
        {
          type: 'attendance_recorded',
          courseId: attendanceData.courseId,
          status: attendanceData.status,
        }
      );

      console.log(`Sent attendance notification to student ${attendanceData.studentId}`);
      return null;

    } catch (error) {
      console.error('Error sending attendance notification:', error);
      return null;
    }
  }
);

// Send weekly attendance summary every Sunday at 7 PM
exports.weeklyAttendanceSummary = onSchedule(
  {
    schedule: 'every sunday 19:00', // 7 PM every Sunday
    timeZone: 'Asia/Kuala_Lumpur',
    region: 'asia-southeast1',
  },
  async (event) => {
    try {
      // Get all active students
      const studentsSnapshot = await admin.firestore()
        .collection('users')
        .where('role', '==', 'student')
        .where('isActive', '==', true)
        .get();

      if (studentsSnapshot.empty) {
        console.log('No active students found');
        return null;
      }

      // Calculate date range for past week
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 7);

      const batch = admin.firestore().batch();
      const notificationPromises = [];

      for (const studentDoc of studentsSnapshot.docs) {
        const studentData = studentDoc.data();
        const studentId = studentData.studentId;

        // Get student's attendance for the past week
        const attendanceSnapshot = await admin.firestore()
          .collection('attendance')
          .where('studentId', '==', studentId)
          .where('date', '>=', admin.firestore.Timestamp.fromDate(startDate))
          .where('date', '<=', admin.firestore.Timestamp.fromDate(endDate))
          .get();

        if (attendanceSnapshot.empty) continue;

        // Count attendance by status
        const stats = {
          present: 0,
          absent: 0,
          late: 0,
          excused: 0,
          total: attendanceSnapshot.size
        };

        attendanceSnapshot.forEach(doc => {
          const status = doc.data().status;
          if (stats[status] !== undefined) {
            stats[status]++;
          }
        });

        // Only send if there were absences
        if (stats.absent > 0 || stats.late > 0) {
          const title = 'Weekly Attendance Summary';
          let message = `This week: ${stats.present} present`;
          
          if (stats.absent > 0) message += `, ${stats.absent} absent`;
          if (stats.late > 0) message += `, ${stats.late} late`;
          if (stats.excused > 0) message += ` (${stats.excused} excused)`;
          
          message += ` out of ${stats.total} classes.`;

          // Create notification
          const notificationRef = admin.firestore()
            .collection('notifications')
            .doc();

          batch.set(notificationRef, {
            userId: studentId,
            type: 'attendance_summary',
            title: title,
            message: message,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            data: {
              weekStart: startDate.toISOString(),
              weekEnd: endDate.toISOString(),
              stats: stats,
            }
          });

          // Send push notification
          notificationPromises.push(
            sendPushNotificationToStudent(studentId, title, message, {
              type: 'attendance_summary',
            })
          );
        }
      }

      // Commit batch write
      await batch.commit();
      
      // Send push notifications
      await Promise.all(notificationPromises);

      console.log('Sent weekly attendance summaries');
      return null;

    } catch (error) {
      console.error('Error sending weekly attendance summaries:', error);
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
  onAttendanceRecorded: exports.onAttendanceRecorded,
  weeklyAttendanceSummary: exports.weeklyAttendanceSummary,
};
