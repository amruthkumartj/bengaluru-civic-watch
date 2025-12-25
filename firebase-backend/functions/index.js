const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const {onSchedule} = require("firebase-functions/v2/scheduler");
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

exports.sendOtpEmail = onCall({allowUnauthenticated: true}, async (request) => {
  // eslint-disable-next-line max-len
  // This function can be called by unauthenticated users (for login/register OTP)
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
exports.updateIssueSeverity = onSchedule("every 12 hours", async (event) => {
  const db = admin.firestore();
  const issuesRef = db.collection("issues");
  const snapshot = await issuesRef.get();

  if (snapshot.empty) {
    console.log("No active issues to process.");
    return null;
  }

  const issues = [];
  let maxVotes = 0;
  snapshot.forEach((doc) => {
    const data = doc.data();
    issues.push({id: doc.id, ...data});
    if (data.upvotes > maxVotes) {
      maxVotes = data.upvotes;
    }
  });

  // Don't run if there's no significant voting activity to avoid minor changes
  if (maxVotes < 3) {
    // eslint-disable-next-line max-len
    console.log("Not enough voting activity to update severity. Max votes:", maxVotes);
    return null;
  }

  const batch = db.batch();
  // Define thresholds: e.g., top 30% are High, next 40% are Medium
  const highThreshold = maxVotes * 0.7;
  const mediumThreshold = maxVotes * 0.3;

  issues.forEach((issue) => {
    let newSeverity;
    if (issue.upvotes >= highThreshold && highThreshold > 0) {
      newSeverity = "High";
    } else if (issue.upvotes >= mediumThreshold) {
      newSeverity = "Medium";
    } else {
      newSeverity = "Low";
    }

    // Only update the document if the severity has actually changed
    if (issue.severity !== newSeverity) {
      const docRef = issuesRef.doc(issue.id);
      batch.update(docRef, {severity: newSeverity});
      // eslint-disable-next-line max-len
      console.log(`Updating issue ${issue.id} from ${issue.severity} to ${newSeverity}.`);
    }
  });

  await batch.commit();
  console.log("Completed issue severity update process.");
  return null;
});
