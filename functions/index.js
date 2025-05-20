/**
 * Firebase Functions for MyTuition app
 */

const admin = require("firebase-admin");
admin.initializeApp();

// Import the scheduler from v2
const {onSchedule} = require("firebase-functions/v2/scheduler");

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
          message: "Your task is 3days overdue. Please remember to complete it",
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

      console.log(
          `Processing reminders for ${reminder.daysFromDueDate > 0 ?
              "upcoming" : "overdue"} tasks (${reminder.type})`,
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
  console.log(
      `Found ${tasksSnapshot.size} tasks in date range ` +
      `${startDate.toDate().toLocaleDateString()} to ` +
      `${endDate.toDate().toLocaleDateString()}`,
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
      }
    }));
  }
}
