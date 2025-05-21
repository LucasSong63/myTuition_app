/**
 * Firebase Functions for MyTuition app
 */

const admin = require("firebase-admin");
admin.initializeApp();

// Import the required modules
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {https} = require("firebase-functions");

// Cloud function for notification cleanup using v2 syntax
exports.cleanupOldNotifications = onSchedule({
  schedule: "0 0 * * *", // Run daily at midnight
  timeZone: "Asia/Kuala_Lumpur",
  retryCount: 3,
  region: "asia-southeast1", // Use region close to Malaysia
}, async (event) => {
  const firestore = admin.firestore();

  try {
    // Get the cleanup config
    const configDoc = await firestore
        .doc("settings/notification_cleanup")
        .get();

    // Split long config line
    const config = configDoc.exists ?
        configDoc.data() :
        {
          retentionPeriodDays: 90,
          archiveInsteadOfDelete: true,
          preservedTypes: ["payment_confirmed", "payment_reminder"],
          preservedTypeRetentionDays: 365,
          cleanupFrequencyDays: 7,
          lastCleanupTime: null,
        };

    console.log("Notification cleanup started");

    // Calculate cutoff dates
    const now = new Date();
    const standardCutoff = new Date(now);
    standardCutoff.setDate(
        standardCutoff.getDate() - config.retentionPeriodDays,
    );

    // Get and process notifications - break long query
    const snapshot = await firestore
        .collection("notifications")
        .where(
            "createdAt",
            "<",
            admin.firestore.Timestamp.fromDate(standardCutoff),
        )
        .get();

    // Fix long console.log line
    const count = snapshot.docs.length;
    console.log(`Found ${count} old notifications`);

    if (snapshot.empty) {
      return null;
    }

    // Process in batches
    const batchSize = 450;
    for (let i = 0; i < snapshot.docs.length; i += batchSize) {
      const batch = firestore.batch();
      const end = Math.min(i + batchSize, snapshot.docs.length);

      for (let j = i; j < end; j++) {
        const doc = snapshot.docs[j];

        if (config.archiveInsteadOfDelete) {
          // Archive first
          const data = doc.data();
          data.archivedAt = admin.firestore.Timestamp.now();
          // Fix long batch.set line
          const archiveRef = firestore
              .collection("archived_notifications")
              .doc(doc.id);
          batch.set(archiveRef, data);
        }

        // Delete from main collection
        batch.delete(doc.ref);
      }

      await batch.commit();
      console.log(`Processed batch: ${i} to ${end-1}`);
    }

    console.log("Notification cleanup completed");
    return null;
  } catch (error) {
    console.error("Error cleaning up notifications:", error);
    return null;
  }
});

/**
 * Scheduled function to check task due dates and send notifications
 * based on configuration stored in Firestore.
 */
exports.checkTaskDueDates = onSchedule({
  schedule: "0 9 * * *", // Default: Run daily at 9:00 AM
  timeZone: "Asia/Kuala_Lumpur",
  retryCount: 3,
  region: "asia-southeast1",
}, async (event) => {
  const firestore = admin.firestore();

  try {
    // Get configuration
    const configDoc = await firestore
        .doc("settings/task_notifications")
        .get();

    // Use default config if not found
    const config = configDoc.exists ? configDoc.data() : {
      enabled: true,
      reminderTimeHour: 9,
      timeZone: "Asia/Kuala_Lumpur",
      reminderDays: [
        {
          daysFromDueDate: 1,
          type: "task_reminder",
          title: "Task Due Tomorrow",
          message: "Your task is due tomorrow",
        },
        {
          daysFromDueDate: -1,
          type: "task_overdue",
          title: "Task Overdue",
          message: "Your task was due yesterday and is now overdue",
        },
        {
          daysFromDueDate: -3,
          type: "task_overdue_final",
          title: "Final Reminder: Task Overdue",
          message: "Your task is 3 days overdue. " +
            "Please remember to complete it",
        },
      ],
      batchSize: 20,
    };

    // Skip processing if disabled
    if (!config.enabled) {
      console.log("Task notifications are disabled in configuration");
      return null;
    }

    console.log("Task notification check started");
    const now = new Date();

    // Process each reminder configuration
    for (const reminder of config.reminderDays) {
      const targetDate = new Date(now);
      // Positive = future, negative = past
      targetDate.setDate(targetDate.getDate() - reminder.daysFromDueDate);
      targetDate.setHours(0, 0, 0, 0);

      const targetDateEnd = new Date(targetDate);
      targetDateEnd.setHours(23, 59, 59, 999);

      // Break long line for better readability
      const reminderType = reminder.daysFromDueDate > 0 ?
        "upcoming" : "overdue";
      console.log(
          `Processing reminders for ${reminderType} tasks (${reminder.type})`,
      );

      await processTasksInDateRange(
          firestore,
          admin.firestore.Timestamp.fromDate(targetDate),
          admin.firestore.Timestamp.fromDate(targetDateEnd),
          reminder.type,
          reminder.title,
          reminder.message,
          config.batchSize || 20,
      );
    }

    console.log("Task due date check completed");
    return null;
  } catch (error) {
    console.error("Error checking task due dates:", error);
    return null;
  }
});

/**
 * Processes tasks in a specific date range and sends notifications to students.
 * @param {object} firestore - The Firestore instance
 * @param {object} startDate - The start date timestamp
 * @param {object} endDate - The end date timestamp
 * @param {string} notificationType - The type of notification to send
 * @param {string} notificationTitle - The title of the notification
 * @param {string} baseMessage - The base message for the notification
 * @param {number} batchSize - Number of tasks to process in each batch
 * @return {Promise<void>} A promise that resolves when processing is complete
 */
async function processTasksInDateRange(
    firestore,
    startDate,
    endDate,
    notificationType,
    notificationTitle,
    baseMessage,
    batchSize = 20,
) {
  // Find tasks in the specified date range that aren't completed
  const tasksSnapshot = await firestore
      .collection("tasks")
      .where("dueDate", ">=", startDate)
      .where("dueDate", "<=", endDate)
      .where("isCompleted", "==", false)
      .get();

  // Log the number of tasks found in this date range
  // Split into multiple lines to avoid max-len
  const startDateStr = startDate.toDate().toLocaleDateString();
  const endDateStr = endDate.toDate().toLocaleDateString();
  console.log(
      `Found ${tasksSnapshot.size} tasks in date range ` +
      `${startDateStr} to ${endDateStr}`,
  );

  // Process tasks in batches
  const tasks = tasksSnapshot.docs;

  for (let i = 0; i < tasks.length; i += batchSize) {
    const batch = tasks.slice(i, i + batchSize);

    // Process this batch of tasks
    await Promise.all(batch.map(async (taskDoc) => {
      const task = taskDoc.data();
      const courseId = task.courseId;

      // Get course to find enrolled students
      const courseDoc = await firestore
          .collection("classes")
          .doc(courseId)
          .get();

      if (!courseDoc.exists) return;

      const course = courseDoc.data();
      const students = course.students || [];

      // Send notification to each student
      for (const studentId of students) {
        // Check if student already completed this task
        const studentTaskRef = firestore
            .collection("student_tasks")
            .doc(`${taskDoc.id}-${studentId}`);

        const studentTask = await studentTaskRef.get();
        if (studentTask.exists && studentTask.data().isCompleted) {
          continue; // Skip if student already completed this task
        }

        // Format due date nicely
        const dueDate = task.dueDate.toDate();
        const formattedDate = dueDate.toLocaleDateString("en-MY", {
          weekday: "long",
          year: "numeric",
          month: "short",
          day: "numeric",
        });

        // Create notification with customized message
        await firestore.collection("notifications").add({
          userId: studentId,
          type: notificationType,
          title: notificationTitle,
          message: `${baseMessage}: "${task.title}" for ${course.subject} ` +
                  `(${formattedDate})`,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            taskId: taskDoc.id,
            courseId: courseId,
            courseName: course.subject,
            dueDate: task.dueDate.toDate().getTime(),
            taskTitle: task.title,
          },
        });

        // Also send push notification
        await sendPushNotification(
            studentId,
            notificationTitle,
            // Break this into multiple lines to avoid max-len
            `${baseMessage}: "${task.title}" for ${course.subject} ` +
            `(${formattedDate})`,
            {
              type: notificationType,
              taskId: taskDoc.id,
              courseId: courseId,
              courseName: course.subject,
              dueDate: task.dueDate.toDate().getTime().toString(),
            },
        );
      }
    }));
  }
}

exports.checkOverduePayments = onSchedule({
  schedule: "0 8 * * *", // Run daily at 8 AM
  timeZone: "Asia/Kuala_Lumpur",
  region: "asia-southeast1",
}, async (event) => {
  const firestore = admin.firestore();

  try {
    // Get current date
    const now = new Date();
    const currentMonth = now.getMonth() + 1; // 1-based month
    const currentYear = now.getFullYear();

    // Get unpaid payments for current or previous months
    const unpaidSnapshot = await firestore
        .collection("payments")
        .where("status", "==", "unpaid")
        .get();

    const overduePayments = unpaidSnapshot.docs.filter((doc) => {
      const data = doc.data();
      const paymentMonth = data.month;
      const paymentYear = data.year;

      // Check if payment is from a previous month/year
      return (paymentYear < currentYear) ||
             (paymentYear === currentYear && paymentMonth < currentMonth);
    });

    // Process each overdue payment
    for (const doc of overduePayments) {
      const payment = doc.data();
      const batch = firestore.batch();

      // Create in-app notification
      const notificationRef = firestore.collection("notifications").doc();
      // Break message into multiple lines to avoid max-len
      const message = `Your payment of RM ${payment.amount} for ` +
                     `${getMonthName(payment.month)} ${payment.year} ` +
                     `is overdue. ` +
                     `Please make payment as soon as possible.`;

      batch.set(notificationRef, {
        studentId: payment.studentId,
        type: "payment_overdue",
        title: "Payment Overdue",
        message: message,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          paymentId: doc.id,
          amount: payment.amount,
          month: payment.month,
          year: payment.year,
        },
      });

      await batch.commit();

      // Also send push notification
      // Break into smaller segments to avoid max-len
      const pushMessage = `Your payment of RM ${payment.amount} for ` +
                         `${getMonthName(payment.month)} ` +
                         `${payment.year} is overdue.`;

      await sendPushNotification(
          payment.studentId,
          "Payment Overdue",
          pushMessage,
          {
            type: "payment_overdue",
            paymentId: doc.id,
            amount: payment.amount.toString(),
            month: payment.month.toString(),
            year: payment.year.toString(),
          },
      );
    }

    if (overduePayments.length > 0) {
      // Split log message to avoid max-len
      const count = overduePayments.length;
      console.log(`Sent overdue payment notifications to ${count} students`);
    }

    return null;
  } catch (error) {
    console.error("Error sending overdue payment notifications:", error);
    return null;
  }
});

/**
 * Returns the name of a month based on its numeric representation.
 * @param {number} month - The month number (1-12) to convert to name.
 * @return {string} The name of the month.
 */
function getMonthName(month) {
  const months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];
  return months[month - 1];
}

// Push Notification Functions
const {getMessaging} = require("firebase-admin/messaging");

/**
 * Sends a push notification to a specific user.
 * @param {string} studentId - The ID of the student to notify
 * @param {string} title - The notification title
 * @param {string} body - The notification message
 * @param {Object} data - Optional data payload for the notification
 * @return {Promise<string>} Messaging response
 */
async function sendPushNotification(studentId, title, body, data = {}) {
  try {
    // Get user document to retrieve FCM tokens
    const userDoc = await admin.firestore()
        .collection("users")
        .where("studentId", "==", studentId)
        .limit(1)
        .get();

    if (userDoc.empty) {
      console.log(`No user found for studentId: ${studentId}`);
      return null;
    }

    const userData = userDoc.docs[0].data();
    const fcmTokens = userData.fcmTokens || [];

    if (fcmTokens.length === 0) {
      console.log(`No FCM tokens found for student: ${studentId}`);
      return null;
    }

    // Prepare notification message
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      tokens: fcmTokens, // Multiple tokens can be targeted
    };

    // Send message
    const response = await getMessaging().sendMulticast(message);
    console.log(
        `Successfully sent message to ${response.successCount} devices ` +
        `for ${studentId}`,
    );

    // Handle failed tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(fcmTokens[idx]);
        }
      });

      // Remove failed tokens
      if (failedTokens.length > 0) {
        await admin.firestore()
            .collection("users")
            .doc(userDoc.docs[0].id)
            .update({
              fcmTokens: admin.firestore.FieldValue
                  .arrayRemove(...failedTokens),
            });
        console.log(`Removed ${failedTokens.length} invalid tokens`);
      }
    }

    return response;
  } catch (error) {
    console.error("Error sending push notification:", error);
    return null;
  }
}

// We'll keep this function even if it's not used currently
/**
 * Sends a push notification to a topic.
 * @param {string} topic - The topic to send to
 * @param {string} title - The notification title
 * @param {string} body - The notification message
 * @param {Object} data - Optional data payload for the notification
 * @return {Promise<string>} Messaging response
 */
// async function sendTopicPushNotification(topic, title, body, data = {}) {
//  try {
//    // Prepare notification message
//    const message = {
//      notification: {
//        title: title,
//        body: body,
//      },
//      data: {
//        ...data,
//        click_action: "FLUTTER_NOTIFICATION_CLICK",
//      },
//      topic: topic,
//    };
//
//    // Send message
//    const response = await getMessaging().send(message);
//    console.log(`Successfully sent message to topic ${topic}: ${response}`);
//    return response;
//  } catch (error) {
//    console.error(`Error sending notification to topic ${topic}:`, error);
//    return null;
//  }
// }

// Cloud Function to test push notifications


// Make sure admin is initialized at the top level of index.js
// If admin is not initialized yet, uncomment the next line:
// admin.initializeApp();

/**
 * Usage: https://asia-southeast1-mytuition-fyp.cloudfunctions.net/testPushNotificationHttp?studentId=MT25-2656
 */
/**
 * General-purpose push notification sender.
 * Parameters:
 * - studentId: the ID of the student to send to
 * - title: notification title
 * - message: notification body
 * - type: notification type (for routing)
 * - data: optional JSON string containing additional data
 */
exports.sendPushNotification = https.onRequest({
  region: "asia-southeast1",
}, async (req, res) => {
  // Set CORS headers
  res.set("Access-Control-Allow-Origin", "*");

  // Handle OPTIONS request for CORS preflight
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "GET");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.status(204).send("");
    return;
  }

  try {
    // Extract parameters from query string
    const studentId = req.query.studentId;
    const title = req.query.title;
    const message = req.query.message;
    const type = req.query.type || "general_notification";
    const createInApp = req.query.createInApp !== "false";
    // Default to true if not specified

    // Parse data if provided
    let data = {};
    try {
      if (req.query.data) {
        data = JSON.parse(req.query.data);
      }
    } catch (parseError) {
      console.warn("Error parsing data payload using empty object:",
          parseError);
    }

    // Add required fields to data
    data.type = type;
    data.click_action = "FLUTTER_NOTIFICATION_CLICK";
    data.timestamp = Date.now().toString();

    console.log(`Sending push notification to ${studentId}`);

    // Only create in-app notification if requested
    if (createInApp) {
      // Create in-app notification
      await admin.firestore().collection("notifications").add({
        userId: studentId,
        type: type,
        title: title,
        message: message,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: data,
      });
      console.log("Created in-app notification successfully");
    } else {
      console.log("Skipping in-app notification creation (createInApp=false)");
    }

    // Get user document to find FCM token
    const userSnapshot = await admin.firestore()
        .collection("users")
        .where("studentId", "==", studentId)
        .limit(1)
        .get();

    if (userSnapshot.empty) {
      const errorMsg = `No user found with studentId: ${studentId}`;
      console.error(errorMsg);
      res.status(404).json({success: false, error: errorMsg});
      return;
    }

    const userData = userSnapshot.docs[0].data();
    const fcmTokens = userData.fcmTokens || [];

    console.log(`Found user: ${userSnapshot.docs[0].id}`);
    console.log(`Found ${fcmTokens.length} FCM tokens`);

    if (fcmTokens.length === 0) {
      const errorMsg = "No FCM tokens found for user";
      console.error(errorMsg);
      res.status(400).json({success: false, error: errorMsg});
      return;
    }

    const mostRecentToken = fcmTokens[fcmTokens.length - 1];

    const singleMessage = {
      notification: {
        title: title,
        body: message,
      },
      android: {
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
          icon: "ic_notification",
          sound: "default",
        },
      },
      data: Object.keys(data).reduce((result, key) => {
        // Convert all values to strings as FCM requires string values in data
        result[key] = data[key] !== null && data[key] !==
        undefined ? data[key].toString() : "";
        return result;
      }, {}),
      token: mostRecentToken,
    };

    console.log(`Sending FCM message to token:
    ${mostRecentToken.substring(0, 15)}...`);

    // Use send instead of sendMulticast for reliability
    const response = await admin.messaging().send(singleMessage);
    console.log(`Successfully sent message: ${response}`);

    // Return success response
    res.status(200).json({
      success: true,
      message: "Push notification sent successfully!",
      messageId: response,
      inAppNotification: createInApp,
    });
  } catch (error) {
    console.error("Error sending notification:", error);
    res.status(500).json({
      success: false,
      error: error.message,
      stack: error.stack,
    });
  }
});
