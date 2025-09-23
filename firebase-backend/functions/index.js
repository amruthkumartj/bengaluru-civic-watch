const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

exports.createAuthority = onCall(async (request) => {
  if (request.auth.token.role !== "superadmin") {
    throw new HttpsError("permission-denied", "Must be a superadmin.");
  }
  const {email, name, phone, zone} = request.data;
  if (!email || !name || !zone) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }
  try {
    // eslint-disable-next-line max-len
    const userRecord = await admin.auth().createUser({email, displayName: name});
    await admin.auth().setCustomUserClaims(userRecord.uid, {
      role: "authority",
      zone: zone,
    });
    await admin.firestore().collection("authorities").doc(userRecord.uid).set({
      name, email, zone, phone: phone || null,
    });
    return {result: `Successfully created authority ${name}.`};
  } catch (error) {
    throw new HttpsError("internal", "Could not create authority.");
  }
});

exports.sendOtpEmail = onCall(async (request) => {
  const {email} = request.data;
  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required.");
  }
  const mailTransport = nodemailer.createTransport({
    service: "gmail",
    auth: {user: process.env.GMAIL_EMAIL, pass: process.env.GMAIL_PASSWORD},
  });
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  await mailTransport.sendMail({
    from: `Bengaluru Civic Watch <${process.env.GMAIL_EMAIL}>`,
    to: email,
    subject: "Your Verification Code",
    text: `Your OTP is: ${otp}`,
  });
  return {otp};
});

exports.resolveIssue = onCall(async (request) => {
  // eslint-disable-next-line max-len
  if (request.auth.token.role !== "authority" && request.auth.token.role !== "superadmin") {
    throw new HttpsError("permission-denied", "Must be an admin/authority.");
  }
  const {issueId, resolutionDetails} = request.data;
  if (!issueId) {
    throw new HttpsError("invalid-argument", "Issue ID is required.");
  }
  const db = admin.firestore();
  const issueRef = db.collection("issues").doc(issueId);
  const resolvedIssueRef = db.collection("resolved_issues").doc(issueId);

  return db.runTransaction(async (transaction) => {
    const issueDoc = await transaction.get(issueRef);
    if (!issueDoc.exists) {
      throw new HttpsError("not-found", "Issue not found.");
    }
    const issueData = issueDoc.data();
    const resolvedData = {
      ...issueData,
      status: "Resolved",
      resolvedAt: new Date(),
      resolvedBy: request.auth.uid,
      resolutionDetails: resolutionDetails || "Issue marked as resolved.",
    };
    transaction.set(resolvedIssueRef, resolvedData);
    transaction.delete(issueRef);
    return {result: "Issue successfully resolved and archived."};
  });
});

exports.getUserDetails = onCall(async (request) => {
  // eslint-disable-next-line max-len
  if (request.auth.token.role !== "authority" && request.auth.token.role !== "superadmin") {
    throw new HttpsError("permission-denied", "Must be an admin/authority.");
  }
  const {userId} = request.data;
  if (!userId) {
    throw new HttpsError("invalid-argument", "User ID is required.");
  }
  try {
    // eslint-disable-next-line max-len
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found.");
    }
    return userDoc.data();
  } catch (error) {
    throw new HttpsError("internal", "Could not fetch user details.");
  }
});
