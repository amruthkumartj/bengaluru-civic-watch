const admin = require("firebase-admin");
const { geohashForLocation } = require("geofire-common");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function updateIssueLocations() {
  const issuesCollection = db.collection("issues");
  const snapshot = await issuesCollection.get();

  if (snapshot.empty) {
    console.log("No issues found to update.");
    return;
  }

  const batch = db.batch();
  snapshot.forEach(doc => {
    const issueData = doc.data();
    const issueLocation = issueData.location; // Your original GeoPoint field

    if (issueLocation && issueLocation.latitude && issueLocation.longitude) {
      const lat = issueLocation.latitude;
      const lng = issueLocation.longitude;
      const hash = geohashForLocation([lat, lng]);

      const positionField = {
        geohash: hash,
        geopoint: issueLocation,
      };

      const docRef = issuesCollection.doc(doc.id);
      batch.set(docRef, { position: positionField }, { merge: true });
    }
  });

  await batch.commit();
  console.log(`✅ Success! Updated ${snapshot.size} documents with the new 'position' field.`);
}

updateIssueLocations().catch(error => {
  console.error("❌ Error updating documents:", error);
});