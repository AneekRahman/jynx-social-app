const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Use service account for development
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://baalish-blog.firebaseio.com",
});

//  PREVIOUS USER UPDATES TRIGGER FUNCTIONS (START) ---------------

// exports.onUserCreated = functions.firestore
//   .document("users/{userID}")
//   .onCreate((snap, context) => {
//     const newValue = snap.data();
//     admin.auth().setCustomUserClaims(context.params.userID, {
//       userName: newValue.userName,
//     });
//     return true;
//   });

// exports.onUserUpdated = functions.firestore
//   .document("users/{userID}")
//   .onUpdate(async (change, context) => {
//     // Get the old, new documents
//     const oldDocument = change.before.data();
//     const newDocument = change.after.data();

//     // Update the userName records
//     // Delete the previous userName document in the /takenUserNames/ collection
//     if (
//       oldDocument.userName &&
//       newDocument.userName &&
//       newDocument.userName !== oldDocument.userName
//     ) {
//       // Update the customClaims userName in FirebaseAuth
//       admin.auth().setCustomUserClaims(context.params.userID, {
//         userName: newDocument.userName,
//       });
//       // This is an update and the userName has been changed. So delele the previous one
//       const response = await admin
//         .firestore()
//         .collection("takenUserNames")
//         .doc(oldDocument.userName)
//         .get();
//       // Check if the old username reference has this users userUid, if so delete it
//       if (
//         response.exists &&
//         response.data().userUid === context.params.userID
//       ) {
//         admin
//           .firestore()
//           .collection("takenUserNames")
//           .doc(oldDocument.userName)
//           .delete();
//       }
//     }

//     return true;
//   });

//  PREVIOUS USER UPDATES TRIGGER FUNCTIONS (END) ---------------

// Exporting ---------------

exports.api = require("./modules/api").api;

console.log("Updated!");
