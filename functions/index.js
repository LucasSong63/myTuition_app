const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Set up email transporter (you'd use actual credentials in production)
const mailTransport = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.password,
  }
});

// Send email when a document is created in the mail collection
exports.sendEmail = functions.firestore
  .document('mail/{mailId}')
  .onCreate(async (snapshot, context) => {
    const mailData = snapshot.data();

    if (!mailData) {
      console.error('No mail data found');
      return null;
    }

    const { to, template, data } = mailData;

    // Different email templates
    let subject, html;

    if (template === 'registration_approved') {
      subject = 'Welcome to myTuition - Registration Approved';
      html = `
        <h2>Welcome to myTuition, ${data.name}!</h2>
        <p>Your registration has been approved. You can now log in to the app using your email and password.</p>
        <p>Please verify your email by clicking on the verification link sent to your email.</p>
        <p><a href="${data.loginUrl}">Click here to log in</a></p>
      `;
    } else if (template === 'registration_rejected') {
      subject = 'myTuition Registration Status';
      html = `
        <h2>Hello ${data.name},</h2>
        <p>We've reviewed your registration request for myTuition and unfortunately, we are unable to approve it at this time.</p>
        <p>Reason: ${data.reason}</p>
        <p>If you have any questions, please contact our support team at ${data.supportEmail}.</p>
      `;
    } else {
      console.error('Unknown email template:', template);
      return null;
    }

    const mailOptions = {
      from: '"myTuition App" <noreply@mytuition.app>',
      to: to,
      subject: subject,
      html: html
    };

    try {
      await mailTransport.sendMail(mailOptions);

      // Update the email log
      await admin.firestore().collection('email_logs')
        .where('email', '==', to)
        .where('type', '==', template)
        .where('status', '==', 'queued')
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get()
        .then(querySnapshot => {
          if (!querySnapshot.empty) {
            querySnapshot.docs[0].ref.update({
              'status': 'sent',
              'sentAt': admin.firestore.FieldValue.serverTimestamp()
            });
          }
        });

      return null;
    } catch (error) {
      console.error('Error sending email:', error);

      // Update the email log with error
      await admin.firestore().collection('email_logs')
        .where('email', '==', to)
        .where('type', '==', template)
        .where('status', '==', 'queued')
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get()
        .then(querySnapshot => {
          if (!querySnapshot.empty) {
            querySnapshot.docs[0].ref.update({
              'status': 'error',
              'errorMessage': error.toString(),
              'updatedAt': admin.firestore.FieldValue.serverTimestamp()
            });
          }
        });

      return null;
    }
  });