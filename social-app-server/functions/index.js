const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Use service account for development
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://baalish-blog.firebaseio.com",
});
// admin.initializeApp(); // Use normal function for production

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
exports.onUserCreated = functions.firestore
  .document("users/{userID}")
  .onCreate((snap, context) => {
    const newValue = snap.data();
    admin.auth().setCustomUserClaims(context.params.userID, {
      userName: newValue.userName,
    });
    return true;
  });

/* -------------- WARNING!!!! ---- THESE ARE NOT SAFE METHODS -------------- */
/* -------------- WARNING!!!! ---- THESE ARE NOT SAFE METHODS -------------- */
/* -------------- WARNING!!!! ---- THESE ARE NOT SAFE METHODS -------------- */
/* -------------- WARNING!!!! ---- THESE ARE NOT SAFE METHODS -------------- */
/* -------------- WARNING!!!! ---- THESE ARE NOT SAFE METHODS -------------- */
exports.onUserUpdated = functions.firestore
  .document("users/{userID}")
  .onUpdate(async (change, context) => {
    // Get the old, new documents
    const oldDocument = change.before.data();
    const newDocument = change.after.data();

    // Update the userName records
    // Delete the previous userName document in the /takenUserNames/ collection
    if (
      oldDocument.userName &&
      newDocument.userName &&
      newDocument.userName !== oldDocument.userName
    ) {
      // Update the customClaims userName in FirebaseAuth
      admin.auth().setCustomUserClaims(context.params.userID, {
        userName: newDocument.userName,
      });
      // This is an update and the userName has been changed. So delele the previous one
      const response = await admin
        .firestore()
        .collection("takenUserNames")
        .doc(oldDocument.userName)
        .get();
      // Check if the old username reference has this users userUid, if so delete it
      if (
        response.exists &&
        response.data().userUid === context.params.userID
      ) {
        admin
          .firestore()
          .collection("takenUserNames")
          .doc(oldDocument.userName)
          .delete();
      }
    }

    return true;
  });

exports.test = functions.https.onRequest(async (req, res) => {
  const reposnse = await admin
    .firestore()
    .collection("takenUserNames")
    .doc("aneekbro")
    .get();
  res.json({ result: JSON.stringify(reposnse.data()) });
});

console.log("Updated!");
