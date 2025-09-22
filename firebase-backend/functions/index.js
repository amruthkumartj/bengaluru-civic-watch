const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

exports.createAuthority = onCall(async (request) => {
  if (request.auth.token.role !== "superadmin") {
    throw new HttpsError(
        "permission-denied",
        "You must be a superadmin to perform this action.",
    );
  }

  const {email, name, phone, zone} = request.data;
  if (!email || !name || !zone) {
    throw new HttpsError(
        "invalid-argument",
        "Missing required fields: email, name, zone.",
    );
  }

  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      displayName: name,
    });

    await admin.auth().setCustomUserClaims(userRecord.uid, {
      role: "authority",
      zone: zone,
      passwordSet: false,
    });

    await admin.firestore().collection("authorities").doc(userRecord.uid).set({
      name: name,
      email: email,
      phone: phone || null,
      zone: zone,
    });

    return {result: `Successfully created authority ${name} (${email}).`};
  } catch (error) {
    console.error("Error creating new authority:", error);
    throw new HttpsError("internal", "Could not create authority.");
  }
});

exports.sendOtpEmail = onCall(async (request) => {
  const recipientEmail = request.data.email;

  if (!recipientEmail) {
    throw new HttpsError(
        "invalid-argument",
        "The function requires an 'email' argument.",
    );
  }

  const gmailEmail = process.env.GMAIL_EMAIL;
  const gmailPassword = process.env.GMAIL_PASSWORD;

  const mailTransport = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailEmail,
      pass: gmailPassword,
    },
  });

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const mailOptions = {
    from: `Bengaluru Civic Watch <${gmailEmail}>`,
    to: recipientEmail,
    subject: "Your Verification Code",
    text: `Your OTP is: ${otp}`,
  };

  try {
    await mailTransport.sendMail(mailOptions);
    console.log(`OTP email sent to ${recipientEmail}`);
    return {otp: otp};
  } catch (error) {
    console.error("Error sending email:", error);
    throw new HttpsError("internal", "Could not send email.");
  }
});

