const admin = require("firebase-admin");

// This tells the script where to find your private key.
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// PASTE THE UID YOU COPIED FROM THE FIREBASE CONSOLE HERE
const uid = "GF9O3NVRvSbxcJvZkeE8Heq0ox92";

admin.auth().setCustomUserClaims(uid, { role: "superadmin" })
  .then(() => {
    console.log(`✅ Success! The user with UID: ${uid} is now a superadmin.`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Error setting custom claim:", error);
    process.exit(1);
  });

